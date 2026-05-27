# Replace Placeholder Sounds

## Goal

Swap every placeholder `.wav` file in `assets/sounds/` with a real sound effect
sourced from craigsmith's public-domain library on freesound.org
(username: **craigsmith**, category: Sound effects).
No code changes are required — only the asset files change.

---

## Affected files

- `assets/sounds/*.wav` — all 17 files replaced in-place

---

## What changes

### Sound mapping

Each game event is matched to the closest available craigsmith sound.
Where no perfect semantic match exists the most evocative available clip is used.

| Game event | Freesound ID | Sound name | Rationale |
|---|---|---|---|
| `pick_up` | 483212 | R09-36-Rustle and Click | Gentle rustle + click conveys lifting something |
| `put_down` | 481855 | R17-55-Small Object Falling | Small thud on wood — item placed down |
| `water_plant` | 480840 | R23-38-Oar Splash | Only water sound in library; short splash |
| `plant_ready` | 675866 | S16-10-Door chime (Columbia Pictures) | Pleasant bell chime for a notification |
| `clone_success` | 480686 | R02-13-Group Applause | Crowd reaction = success/reward |
| `clone_fail` | 675921 | S40-08-Two-tone 8-bit electronic buzz | Electronic buzz = error / denial |
| `sell_plant` | 481835 | R15-81-Metal Clanking Coins | Coins = money changing hands |
| `dismiss_customer` | 675869 | S04-23-Short door latch | Door latch = customer shown out |
| `dialogue_skip` | 675772 | S31-09-Flare whoosh | Fast whoosh = skipping forward quickly |
| `dialogue_advance` | 481825 | R09-64-Pen or Tape Scratches | Marker-on-paper click = text advancing |
| `discard_plant` | 483238 | R09-82-Falling on Muffled Wood | Muffled thud = item thrown away |
| `open_shop` | 675881 | S06-08-Wooden door opens and closes | Door opening = entering the shop |
| `shop_navigate` | 480663 | R17-23-Clicks Clanks | Quick clicks = cursor moving through items |
| `shop_buy` | 676000 | S24-24-Comedy cartoon cork pop | Satisfying pop = successful purchase |
| `shop_close` | 483202 | R09-20-Light Door Shut | Quiet door close = leaving shop |
| `menu_navigate` | 480663 | R17-23-Clicks Clanks | Same clip as shop_navigate; consistent UI feel |
| `menu_confirm` | 675695 | S29-01-Submarine signal bell | Short bell chime = confirming a selection |

> **Note:** `shop_navigate` and `menu_navigate` intentionally share the same source
> sound (480663). They will be stored as two separate `.wav` files so either can be
> swapped independently later.

### Download script

A shell script `scripts/download_sounds.sh` is added that fetches each sound
via the freesound API and converts/renames it to the correct `.wav` filename.

Requirements:
- `curl`
- `ffmpeg` (for any format conversion if a clip isn't already `.wav`)
- A freesound **personal API token** (set via env var `FREESOUND_TOKEN`)

The script writes directly into `assets/sounds/`, overwriting placeholders.

---

## What stays the same

- `lua/game/sound.lua` — no changes; filenames are identical to the placeholders
- All other Lua source files — untouched
- File names — identical to the existing placeholders; no renames
- Tests — pass through unchanged (headless stubs silence audio)

---

## Open questions

None — all answered before writing this doc.
- Creative stretches are acceptable; use best available match.
- Delivery via shell script (user runs it with their own API token).
