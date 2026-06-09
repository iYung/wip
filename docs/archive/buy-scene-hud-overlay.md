## Buy Scene HUD Overlay Checklist

- [x] Task A — `lua/game/scenes/buy_scene.lua` — require `lua/game/ui`, remove the hardcoded hints block from inside the canvas render, and after `CRT.clear()` build key-aware hint strings via `self.input:key_for(...)`, then call `UI.draw_hud_box(hints, font_ui)` and print the labels inside the box using the same coordinate logic StoreScene uses
