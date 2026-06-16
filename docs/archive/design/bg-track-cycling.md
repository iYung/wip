## Goal

Instead of picking one random background track when entering the store scene and looping it forever, cycle sequentially through all four bg tracks (bg1→bg2→bg3→bg4→bg1→…). Each track plays once to its natural end, then the next fades in.

## Affected files

- `lua/core/sound.lua` — no changes needed; existing `fade_music` / `stop_music` / `is_music_playing` cover everything
- `lua/game/scenes/store_scene.lua` — owns the cycling logic

## What changes

**`StoreScene.new()`**
- Add `self._bg_list = {"bg1", "bg2", "bg3", "bg4"}`
- Add `self._bg_index = math.random(4)` — random starting point so it doesn't always open on bg1

**`StoreScene:on_enter()`**
- Replace `Sound.play_random_music(_bg, 2)` guard block with: if no bg track is currently playing, fade in `_bg_list[_bg_index]` with a 2-second duration (same feel as the existing scene-entry fade)
- If a bg track is already playing (returning from BuyScene), do nothing — the cycling logic in `update` keeps running

**`StoreScene:update(dt)`**
- After existing update logic, check whether `_bg_list[_bg_index]` is no longer playing
- If it stopped, advance `_bg_index` (mod 4, 1-based wrapping), then fade in the new current track with a 2-second duration

**`main.lua` Sound.load manifest**
- bg1–bg4 currently have no `autoplay` and are loaded with `setLooping(true)`. Remove the looping so tracks play once and stop naturally. This requires adding a `looping` field to the manifest, or toggling it after load.
- Simplest: add `looping = false` to each bg track entry; `Sound.load` already sets `setLooping(autoplay)` implicitly — we just need to pass through a `looping` flag.

Actually: `Sound.load` always calls `src:setLooping(true)` for all tracks. We need to either:
- (a) Pass a `looping = false` flag per track and honour it in `Sound.load`, or
- (b) Expose `Sound.set_looping(name, bool)` and call it after load

Option (a) is cleaner — one-line addition to the load loop.

## What stays the same

- The 2-second fade from menu → first bg track (same `fade_music` call, same duration)
- All bg tracks are faded out when leaving to the main menu (existing `main.lua` logic unchanged)
- `Sound.play_random_music` remains in the codebase (used nowhere else after this change, can be left for now)
- BuyScene audio behaviour unchanged — bg keeps playing through BuyScene visits

## Open questions

None — all design decisions confirmed by user:
- Sequential order (1→2→3→4→1)
- Random starting track
- Natural track end triggers the transition (no artificial fade-out)
- Next track fades in over 2 seconds
