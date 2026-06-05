# Animalese Sound Trim

## Goal

Trim the animalese note from 60ms to 50ms and prevent notes from stacking more than
one-deep by adding a minimum inter-note cooldown equal to the trimmed note length.

Current state: `REVEAL_SPEED = 40` chars/sec fires a note every 25ms; the 60ms sound
means up to three notes play simultaneously. The desired state is at most two, with clean
note separation.

---

## Affected files

- `assets/sounds/animalese.wav` — trim from 60ms (2646 frames) to 50ms (2205 frames)
- `lua/game/sound.lua` — add a per-source cooldown so `play_animalese` skips a trigger
  if fewer than 50ms have elapsed since the last play

---

## What changes

### `assets/sounds/animalese.wav`

Trim the file to exactly 50ms (2205 frames at 44100 Hz) by writing only the first 2205
PCM frames. No pitch or amplitude change.

### `lua/game/sound.lua`

Add a module-level `_animalese_last_t = 0` timestamp (seconds, updated via
`Sound.update`). In `play_animalese`, skip playback if
`love.timer.getTime() - _animalese_last_t < 0.05`; update `_animalese_last_t` on play.

This keeps at most two notes alive at once — the current note and one that starts when
the first has 25ms left — which is the minimum overlap achievable without slowing down
the typewriter.

---

## What stays the same

- `REVEAL_SPEED` is unchanged; typewriter speed is not affected.
- All other sounds, volume, music, and SFX logic are untouched.
- `play_animalese` API is unchanged; callers need no updates.
- Headless no-ops remain: `love.audio` guard in `play_animalese` still exits early.

---

## Open questions

None.
