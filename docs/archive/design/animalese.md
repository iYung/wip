# Animalese Character Sounds

## Goal

Play a pitched, per-character voice sound as the typewriter reveals each character of scripted dialogue. No sound plays when the player skips (which jumps `reveal_index` instantly to the end of the text). Each character script can optionally define a voice pitch; characters without one share a neutral default.

## Affected files

- `lua/game/customer.lua` — typewriter update loop, skip logic, character config
- `lua/game/data/customer_scripts.lua` — voice pitch field per script
- `lua/game/sound.lua` — animalese sound loading and playback helper
- `assets/sounds/` — one short voice sample (animalese.wav) to be added

## What changes

### 1. Voice asset (`assets/sounds/animalese.wav`)

A short (~50–80ms), neutral voiced syllable (e.g. a soft "ah" or "mm"). This single sample is reused for every character, pitched up/down per character.

### 2. Sound module (`lua/game/sound.lua`)

Add `Sound.play_animalese(pitch)`:
- Loads `animalese.wav` once at startup (alongside other SFX).
- On call: clone the source, set pitch, play. Same polyphony pattern already used for other SFX.
- Pitch is a multiplier (1.0 = neutral, e.g. 0.8–1.4 range for character variety).

### 3. Customer script data (`lua/game/data/customer_scripts.lua`)

Add an optional `voice_pitch` field to each script entry (float, default `1.0`). Example:

```lua
{ id = "dottie", chapter = 1, voice_pitch = 1.3, ... }
```

Characters without `voice_pitch` get the neutral default.

### 4. Customer class (`lua/game/customer.lua`)

**On `show(cfg)`:** Store `cfg.voice_pitch` (or `1.0`) as `self._voice_pitch`.

**In the typewriter update loop** (currently lines 234–240):

Track the previous `reveal_index`. When `reveal_index` advances (i.e. new bytes were revealed this frame), play `Sound.play_animalese(self._voice_pitch)` once per frame the index moves. Do NOT play one sound per byte — one trigger per frame the index advances is sufficient and avoids sound spam at high speeds.

**Skip path (`skip_reveal()`):** Sets `reveal_index` to `#self._full_text` and resets `reveal_t`. No sound call is made here — correct by omission (sounds only fire from the typewriter update path).

## What stays the same

- The typewriter advance/skip logic and UTF-8 boundary clamping are unchanged.
- `skip_reveal()` behavior (instant jump, no animation) is unchanged.
- All other SFX events (`sell_plant`, `shop_navigate`, etc.) are unchanged.
- The dialogue state machine (messages → done_talking → after_messages) is unchanged.
- No sound plays for `after_messages` differently than `messages` — both are driven by the same typewriter loop, so both get animalese automatically.

## Open questions

None.
