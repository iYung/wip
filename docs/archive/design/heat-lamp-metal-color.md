# Heat Lamp Metal Color

## Goal
Replace the grey metal tones in all heat lamp images with the blue palette used in the garbage bin, so the two objects share the same metal color language.

## Affected files
- `assets/images/heat_lamp_1.png`
- `assets/images/heat_lamp_2.png`
- `assets/images/heat_lamp_3.png`
- `assets/images/heat_lamp_4.png`
- `assets/images/heat_lamp_5.png`
- `assets/images/heat_lamp_6.png`
- `assets/images/heat_lamp_icon.png`

## What changes
Two pixel-exact color substitutions applied to all 7 PNGs:

| From | To | Role |
|---|---|---|
| `#919191` | `#7ba3e9` | Light grey → light blue (main shade body) |
| `#595959` | `#243f70` | Dark grey → dark blue (shadow / depth) |

## What stays the same
- `#000000` — wire and cord — unchanged
- `#ffffff` — highlight glints — unchanged
- All bulb colors (`#f4be59`, `#f4ee59`, red tones) — unchanged
- PSDs — not touched (user manages source files separately)
- No Lua code changes; these are asset-only edits

## Open questions
None — user confirmed mapping: dark grey → dark blue, light grey → light blue, sourced from `garbage_bin.png`.
