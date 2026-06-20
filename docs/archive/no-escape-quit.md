## No-Escape-Quit Checklist

- [x] Task A — `main.lua` — Remove `love.event.quit()` from the `love.keypressed` Escape fallback branch (the `elseif not (settings_menu and settings_menu.is_open) then love.event.quit()` block, ~line 215)
- [x] Task B — `main.lua` — Remove `love.event.quit()` from the `love.gamepadpressed` Start button fallback branch (the `else love.event.quit()` inside the `if button == "start"` block, ~line 235)
