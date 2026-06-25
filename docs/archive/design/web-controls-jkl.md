## Goal

Update the web PR preview UI's on-screen buttons to match the current default keyboard controls. The right cluster still fires `Space` and `Escape`, but the game's default action keys changed to `interact=j`, `pick_up_down=k`, `cancel=l`.

## Affected files

- `web-template/controls.js` — defines and wires all on-screen buttons

## What changes

- **`KEY_CODES` map**: add `j` (74), `k` (75), `l` (76); remove `' '` (Space, 32) and `'Escape'` (Escape, 27)
- **Right cluster buttons**: replace `Space` and `Esc` buttons with three buttons: `J` (fires `j`/`KeyJ`), `K` (fires `k`/`KeyK`), `L` (fires `l`/`KeyL`)
- **Right cluster CSS grid**: change from `2-column × 2-row` (with Space/Esc each spanning 2 cols) to `3-column × 1-row` to fit three equal-width buttons
- **CSS classes**: rename `.btn-space` → `.btn-j`, `.btn-esc` → `.btn-k`, add `.btn-l`; remove `grid-column: 1 / span 2` span rules; add simple `grid-column: 1/2/3` positioning for J/K/L

## What stays the same

- Left cluster (W A S D movement) — unchanged
- Gamepad clusters and fake gamepad logic — unchanged
- Canvas scaling, save controls bar, mode toggle — unchanged

## Open questions

None.
