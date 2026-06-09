# Design: Music Focus Resume

## Goal

When the player alt-tabs away from the game window and then returns, background music
should continue playing seamlessly. Currently, music stops when focus is lost and does
not resume when focus returns.

---

## Root Cause

Love2D's default behavior is to pause all audio sources when the game window loses
focus and resume them when focus returns. However, this behavior only works for sources
that are in the **paused** state — it calls `source:pause()` on focus-out and
`source:resume()` on focus-in.

The bug is triggered because the music tracks in this game are never *paused* — they
are either *playing* or *stopped*. When `Sound.fade_music` fades a track to zero
volume, it calls `entry.src:stop()` at the end of the fade (`stop_on_done = true`,
line 151 in `sound.lua`). A stopped source has no resume point; `love.audio`'s
built-in focus handler cannot resume a stopped source, so it silently does nothing.

More precisely, Love2D 11.x **does not** automatically call pause/resume at all for
stream sources unless `love.audio.setMixWithSystem(false)` has been set (the default
on desktop is `true`, meaning audio continues even when the window is not focused and
no automatic pause occurs). The behavior is platform-specific:

- **macOS / iOS**: Love2D registers an application-level audio session interrupt
  handler. When the OS suspends the audio session (focus loss, phone call, etc.)
  the Love2D internals call `love.audio.pause()` on all playing sources. When the
  session resumes, it calls `love.audio.resume()`. This only works for sources that
  are in the playing state at the moment of suspension — it records a snapshot of
  which sources were playing, pauses them, then replays only those same sources on
  resume.
- **Windows / Linux**: No automatic pause/resume. Music simply keeps playing unless
  the OS or audio driver interrupts the stream, which can abruptly stop a streaming
  source without setting it back to "playing".

In both cases the result is the same for this game: after the track is stopped (either
via the explicit `stop()` calls in `Sound.stop_music` / `Sound.play_random_music`, or
by the OS/driver interrupting a stream source), calling `entry.src:isPlaying()` returns
`false`. When the game is refocused there is no code path that checks for this
condition and calls `entry.src:play()` again.

There is also no `love.focus` callback defined anywhere in `main.lua` or any scene,
so the game has no opportunity to react to focus changes at all.

### Concrete sequence (macOS focus-loss path)

1. User alt-tabs away. macOS suspends the audio session.
2. Love2D's internal interrupt handler calls `love.audio.pause()` on all *currently
   playing* sources and records them.
3. User alt-tabs back. Love2D's internal handler calls `love.audio.resume()` on the
   recorded sources.
4. **Problem**: Step 2 only captures sources that were in a `playing` state when the
   OS interrupted. If the track was in the middle of a volume fade and the fade
   completed with `stop_on_done = true` *before* or *during* the interruption, the
   source is already stopped and is not in the snapshot. It will not be resumed.
5. Additionally, on some platforms the stream source simply stops due to the audio
   session being torn down, leaving `isPlaying() == false` without any resume handle.

### Concrete sequence (Windows / Linux path)

1. User alt-tabs away. The audio device may stutter or the stream may be interrupted.
2. On some drivers, `stream` sources stop silently when the audio device is
   suspended.
3. User alt-tabs back. No Love2D code attempts to restart stopped sources.
4. `entry.src:isPlaying()` is now `false`; `Sound.update(dt)` only adjusts volume on
   entries where `fade_rate ~= 0`, so the silence persists indefinitely.

---

## Affected Files

| File | Why affected |
|------|-------------|
| `main.lua` | Missing `love.focus` callback; the only place to hook OS-level focus events |
| `lua/game/sound.lua` | `Sound.update`, `Sound.is_music_playing`, `Sound.fade_music`, and the track entry structure all need awareness of the focus-paused state vs. the intentionally-stopped state |

No other files need changes. The scenes (`start_scene.lua`, `store_scene.lua`) already
call the correct `Sound` API; they just need `Sound` to recover transparently.

---

## What Changes

### 1. `main.lua` — add `love.focus` callback

Add a new top-level callback after `love.quit`:

```lua
function love.focus(focused)
    Sound.on_focus(focused)
end
```

This feeds focus events into `Sound` so it can decide what to do without any
scene-level knowledge.

### 2. `lua/game/sound.lua` — track "should be playing" intent separately from source state

#### 2a. Add `playing_intent` flag to each music track entry

In `Sound.load()`, add `playing_intent = false` to every track entry table.
`playing_intent` records whether the game *wants* the track playing, independent of
whether the OS currently has the source in a playing state.

Set `playing_intent = true` whenever `entry.src:play()` is called (inside
`Sound.play_music`, `Sound.fade_music`).
Set `playing_intent = false` whenever `entry.src:stop()` is called (inside
`Sound.stop_music`, `Sound.play_random_music`, and the `stop_on_done` branch of
`Sound.update`).

#### 2b. Add `Sound.on_focus(focused)` function

```lua
function Sound.on_focus(focused)
    if focused then
        -- Resume any track the game intended to be playing but that the OS stopped
        for _, entry in pairs(_music_tracks) do
            if entry.playing_intent and not entry.src:isPlaying() then
                entry.src:setVolume(entry.fade_vol * _music_volume)
                entry.src:play()
            end
        end
    end
    -- No action needed on focus-out: Love2D's built-in handler (where present)
    -- already pauses playing sources.  We intentionally do not stop tracks on
    -- focus-out because that would lose the resume point.
end
```

#### 2c. Keep `stop_on_done` but set `playing_intent = false` in that branch

In `Sound.update`, the existing block that calls `entry.src:stop()` when `stop_on_done`
is true must also set `entry.playing_intent = false` so `on_focus` does not
accidentally restart a track that was intentionally faded out.

---

## What Stays the Same

- All existing `Sound` API surface (`Sound.play`, `Sound.fade_music`, `Sound.stop_music`,
  `Sound.play_music`, `Sound.play_random_music`, `Sound.is_music_playing`,
  `Sound.set_music_volume`, `Sound.set_sfx_volume`, `Sound.update`) — signatures
  and external behavior are unchanged.
- Scene music management logic in `store_scene.lua` (the `_bg_playing` guard on
  `on_enter`) and `start_scene.lua` — these continue to work as-is.
- SFX sources (static clones played via `Sound.play`) — these are fire-and-forget
  clones and do not need intent tracking.
- The `animalese` source — same reasoning as SFX.
- All tests — `lua/headless/stubs.lua` stubs `love.audio` so `on_focus` will be a
  no-op in headless (the `if not love.audio then return end` guard already at the top
  of Sound functions covers this; `on_focus` should add the same guard).
- `love.quit` auto-save logic in `main.lua` — untouched.

---

## Open Questions

1. **`love.focus` on web (love.js)**: Does love.js fire `love.focus` on browser
   tab visibility changes? If not, a separate `love.visible` handler (or a
   `document.visibilitychange` event bridge) may be needed for web builds. Low
   priority until web is a shipping target.

2. **Volume on resume**: When `on_focus` restarts a stopped stream source it sets
   the volume to `entry.fade_vol * _music_volume`. If the track was mid-fade when
   focus was lost this is correct. Confirm there is no audible volume jump before
   committing.

3. **`isPlaying()` after OS-level interrupt**: On macOS, if Love2D's internal handler
   already resumed the source, `isPlaying()` will return `true` by the time
   `love.focus(true)` fires, and the `on_focus` guard (`not entry.src:isPlaying()`)
   will skip it — correct. But this should be verified on a real device to make sure
   the Love2D callback fires *after* the internal resume, not before.

4. **`menu` track on focus resume**: The menu track is started in `Sound.load()` with
   `playing_intent` effectively `true` from the start. `StoreScene:on_enter()` calls
   `Sound.stop_music("menu")`. Ensure that `stop_music` sets `playing_intent = false`
   so the menu track does not restart mid-game.
