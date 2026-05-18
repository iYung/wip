# Start Screen

Replace the code-drawn start screen with PNG assets, one at a time.
Each PNG has a fallback so the screen works before art is created.

## Current State

`start_scene.lua` draws everything in code — no assets:
- "PLANT STORE" title text (size-64 font) at y=140
- 3 buttons (New Game / Continue / Exit) as colored rectangles
  - Size: 300×54px, centered on 1280px screen, starting y=290, gap 74px
  - Selected: green `(0.35, 0.75, 0.45)` / Unselected: dark `(0.18, 0.18, 0.24)`

## PNGs to Create

| File | Size | Description |
|------|------|-------------|
| `assets/start_bg.png` | 1280×720 | Full background (shop exterior, sky, etc.) |
| `assets/start_logo.png` | ~500×120 | "PLANT STORE" title as art |
| `assets/start_btn.png` | 300×54 | Normal button state |
| `assets/start_btn_selected.png` | 300×54 | Highlighted button state |

## Steps

- [ ] Update `start_scene.lua` to load each PNG via `try_img`, fall back to current code-drawn style if missing
- [ ] Create `start_bg.png` — wire up in scene
- [ ] Create `start_logo.png` — wire up in scene
- [ ] Create `start_btn.png` and `start_btn_selected.png` — wire up in scene
- [ ] Clean up fallback code once all PNGs are in place
