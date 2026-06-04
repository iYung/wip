# Animalese Checklist

- [x] Task A — `assets/sounds/animalese.wav` — add a short (~60ms) neutral voiced syllable sample; can be a sine-wave "ah" or similar soft voice sound at a neutral pitch

- [x] Task B — `lua/game/sound.lua` — add `animalese.wav` to `_EVENT_NAMES` (or load it separately if pitch-per-play requires a dedicated source); add `Sound.play_animalese(pitch)` that clones the source, sets pitch, and plays it (same pattern as existing `Sound.play`)

- [x] Task C — `lua/game/customer.lua` — in `show(cfg)` store `self._voice_pitch = cfg.voice_pitch or 1.0`; in the typewriter update loop (lines 234–240) track `prev_index` before updating `reveal_index`, and call `Sound.play_animalese(self._voice_pitch)` once per frame when `reveal_index > prev_index`; no change to `skip_reveal()`
