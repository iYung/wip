# Checklist: Remove Arrow Keys / WASD-Only Controls

- [x] `lua/game/input.lua` — remove `"up"`, `"down"`, `"left"`, `"right"` from the four movement action lists, leaving only the WASD keys
- [x] `web-template/controls.js` — update `KEY_CODES` map: remove Arrow entries, add `w:87, a:65, s:83, d:68`
- [x] `web-template/controls.js` — change `attachButton` calls for the four d-pad buttons to fire `w/a/s/d` with codes `KeyW/KeyA/KeyS/KeyD`
- [x] `web-template/controls.js` — update d-pad button labels from arrow symbols to `W`, `A`, `S`, `D`
