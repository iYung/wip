# Fix: Customer One-Frame Flash on Spawn Checklist

- [x] Task A — `lua/game/customer.lua` — At the end of `Customer:show()`, sync `sprite.x` and `sprite.y` to the correct off-screen entry position (`self.x - CW / 2` and `self.y - CH / 2 - 20`) so the sprite is positioned correctly before the first draw, preventing the one-frame flash at the previous customer's stale position.
- [x] Task B — `tests/test_customer_spawn_flash.lua` — Added regression test that verifies `sprite.x`/`sprite.y` snap to exit_x immediately after `show()` with no intervening `update()` call.
