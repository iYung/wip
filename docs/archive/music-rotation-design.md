# Design: Music Rotation (no repeat, no looping)

## Goal

Replace the current looping behaviour on the four store background tracks (bg1–bg4) with a
playlist-style rotation: each track plays once to completion, then a new track is picked at
random — excluding the track that just finished — and fades in. The net effect is an infinite,
varied soundtrack with no immediate repeats and no audible loop points.

---

## Affected Files

### `lua/game/sound.lua`

1. **Remove `setLooping(true)` from bg1–bg4** during `Sound.load()`.  
   `menu` keeps its looping flag; only the four background tracks change.

2. **Add `play_random_music_except(names, exclude, fade_duration)`** — a new public function
   (or extend `play_random_music` with an optional `exclude` parameter) that filters out one
   name before picking randomly.  Design decision: add an optional fourth parameter
   `exclude_name` to `play_random_music`; when provided, it is removed from the candidate list
   before `math.random` is called.  If the candidate list would be empty after exclusion (i.e.
   only one track exists), the exclusion is ignored so music always plays.

3. **Expose `Sound.get_playing_bg()` (or equivalent)** — a small helper that returns the name
   of whichever bg track currently has `playing_intent = true`, or `nil` if none. Used by
   `StoreScene` to pass the correct `exclude_name` when auto-advancing.

4. **`Sound.update(dt)`** — add end-of-track detection for bg tracks.  
   After each fade entry is processed, check whether any bg track has `playing_intent = true`
   but `entry.src:isPlaying() == false` and `entry.fade_rate == 0` (not mid-fade, not
   intentionally stopped by `stop_on_done`).  When that condition is true the track finished
   naturally; fire a callback or set a flag so the caller can react.  
   Design decision: `Sound.update` accepts an optional second argument `on_bg_ended(name)` — a
   callback function supplied by `StoreScene`.  When a bg track ends naturally, `Sound.update`
   calls `on_bg_ended(name)` once and clears the flag to prevent re-triggering.  A small
   `_bg_ended_fired` boolean per track entry guards against calling the callback on every frame
   while the source stays stopped.

### `lua/game/scenes/store_scene.lua`

1. **`StoreScene:on_enter()`** — no structural change.  The existing guard
   (`_bg_playing` check → `play_random_music`) is kept as-is; it correctly avoids
   restarting music when the player returns from `BuyScene`.

2. **`StoreScene:update(dt)`** — pass an `on_bg_ended` callback into `Sound.update`.  
   The callback calls `Sound.play_random_music({"bg1","bg2","bg3","bg4"}, 2, last_track)` where
   `last_track` is the name received in the callback.  This enforces the no-same-track rule.

   Implementation sketch:
   ```
   Sound.update(dt, function(ended_name)
       Sound.play_random_music({"bg1","bg2","bg3","bg4"}, 2, ended_name)
   end)
   ```

---

## What Stays the Same

- `menu` track — looping, unaffected.
- `Sound.play_music`, `Sound.fade_music`, `Sound.stop_music`, `Sound.on_focus` — unchanged.
- `StoreScene:on_enter()` — the existing `_bg_playing` guard and initial `play_random_music`
  call remain untouched.
- `BuyScene` music handling — unchanged.
- All SFX paths — unchanged.
- The `playing_intent` contract — still the single source of truth for whether a track should
  be playing.  `on_focus` still restores any track with `playing_intent = true`.

---

## Mechanism: Detecting Track End

**Where the check lives:** `Sound.update(dt, on_bg_ended)` in `lua/game/sound.lua`.

**Per-track state needed:**
- `entry.playing_intent` (already exists) — `true` means the track was started intentionally.
- `entry.stop_on_done` (already exists) — `true` means a fade-to-zero is in progress; do *not*
  fire "ended naturally" while this is set.
- New: `entry.is_bg` — boolean set to `true` for bg1–bg4 during `Sound.load()`, `false` (or
  nil) for all other tracks.  Used to limit end-of-track polling to bg tracks only, keeping the
  check cheap.

**Each frame in `Sound.update`:**
```
for name, entry in pairs(_music_tracks) do
    -- existing fade logic ...
    if entry.is_bg
       and entry.playing_intent
       and not entry.stop_on_done
       and not entry.src:isPlaying() then
        -- track ended naturally
        entry.playing_intent = false
        if on_bg_ended then
            on_bg_ended(name)
        end
    end
end
```

The `entry.playing_intent = false` line prevents the callback from firing again next frame
(replaces the need for a separate `_bg_ended_fired` guard).

---

## "No Same Track Twice in a Row" Enforcement

`Sound.play_random_music` gains a third optional parameter `exclude_name`:

```lua
function Sound.play_random_music(names, fade_duration, exclude_name)
    local valid = {}
    for _, name in ipairs(names) do
        if _music_tracks[name] and name ~= exclude_name then
            valid[#valid + 1] = name
        end
    end
    -- fallback: if exclusion leaves nothing, use all valid tracks
    if #valid == 0 then
        for _, name in ipairs(names) do
            if _music_tracks[name] then valid[#valid + 1] = name end
        end
    end
    if #valid == 0 then return end
    -- stop any currently playing bg tracks, pick one, fade in
    ...
    local picked = valid[math.random(#valid)]
    Sound.fade_music(picked, 1, fade_duration)
end
```

The exclusion is a best-effort filter: if only one track is installed (e.g. only `bg1` exists)
the fallback ensures music always continues.

---

## Open Questions / Edge Cases

1. **`on_focus` restart after window re-focus mid-track** — when the OS silences a bg track
   and `on_focus` restarts it, the track resumes from the beginning (Love2D stream sources do
   not preserve playback position after a stop).  This is unchanged behaviour and is acceptable;
   no fix needed.

2. **BuyScene transition** — entering `BuyScene` does not stop bg music; the existing code
   leaves it running.  The rotation check in `Sound.update` continues to run while the player
   is in `BuyScene` because `Sound.update` is called from `main.lua`, not `StoreScene`.
   The `on_bg_ended` callback is only wired by `StoreScene:update`, so if a track ends while
   the player is in `BuyScene` no callback fires.  On return to `StoreScene`, `on_enter` checks
   `_bg_playing` — if nothing is playing at that point it starts a fresh random track.  This is
   the same fallback that exists today; no gap in coverage.

3. **Track durations and fade overlap** — `fade_music` starts the next track with a 2-second
   fade-in.  The outgoing track has already stopped (ended naturally), so there is no overlap
   or audible crossfade; the gap is at most one frame.  If a seamless crossfade is later
   desired, the ending track would need to be detected slightly before its true end (e.g.
   `getDuration() - src:tell()` polling), which is out of scope for this change.

4. **Headless / test environment** — `love.audio` is nil in headless mode; all Sound functions
   already guard with `if not love.audio then return end`.  No additional test stubs needed.

5. **Only one bg track installed** — handled by the exclusion fallback described above; the
   single track plays repeatedly without error.
