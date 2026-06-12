## Settings Exit Ghost Interact Checklist

- [x] Fix ghost interact — `main.lua` — after `settings_menu:update(dt)`, check if settings just closed and call `input:update()` to prime `_down` so the confirm key doesn't register as a fresh press in the scene next frame
</thinking>
