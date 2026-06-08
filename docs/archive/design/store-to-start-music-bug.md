## Goal

Fix the bug where store background music continues playing after returning to the start menu via Settings → Leave Game.

## Affected files

- `main.lua` — contains the `_on_leave` callback with the wrong track name

## What changes

In `main.lua`, the `_on_leave` function (line 95–103) is called when the player selects "Leave Game" from the in-game settings menu. It currently calls:

```lua
Sound.fade_music("bg", 0, 1)
```

There is no track named `"bg"`. The bg tracks are registered in `sound.lua` as `"bg1"`, `"bg2"`, `"bg3"`, and `"bg4"`. Because the name doesn't match any entry in `_music_tracks`, `Sound.fade_music` silently does nothing, and whichever bg track is playing continues at full volume.

The fix mirrors the start → store transition: just before switching scenes, fade out all four bg tracks to 0 over 1 second. `StartScene:on_enter` already handles playing the menu music once the scene loads (checking `Sound.is_music_playing("menu")` before calling `Sound.play_music("menu")`), so no changes are needed there.

```lua
-- before
Sound.fade_music("bg", 0, 1)

-- after
for _, name in ipairs({"bg1", "bg2", "bg3", "bg4"}) do
    Sound.fade_music(name, 0, 1)
end
```

## What stays the same

- `Sound` module API — no new functions needed
- `StartScene:on_enter` music logic — already correct
- `StoreScene:on_enter` music logic — already correct
- All other settings menu behavior

## Open questions

None — the bug cause and fix are unambiguous.
