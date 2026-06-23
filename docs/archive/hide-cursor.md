## Hide Cursor Checklist

- [x] Task A — `main.lua` — add `love.mouse.setVisible(false)` in `love.load()`, immediately after the `love.graphics.setDefaultFilter("nearest", "nearest")` line, to hide the OS cursor unconditionally at startup across all scenes
- [x] Task B — `lua/headless/stubs.lua` — add a `love.mouse` stub (`love.mouse = love.mouse or {}` / `love.mouse.setVisible = function() end`) alongside the existing `love.window` and `love.keyboard` stubs, so headless tests don't error if `love.mouse` is absent
