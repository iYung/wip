## Animalese Sound Trim Checklist

- [x] Task A — `assets/sounds/animalese.wav` — trim from 60ms (2646 frames) to 50ms (2205 frames at 44100 Hz) by writing only the first 2205 PCM frames; use Python's `wave` module
- [x] Task B — `lua/game/sound.lua` — add `_animalese_last_t = 0` module-level variable; in `play_animalese`, skip playback if `love.timer.getTime() - _animalese_last_t < 0.05` and update `_animalese_last_t` on each play
