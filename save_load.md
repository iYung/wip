# Save / Load System

Persist game progress across sessions using LÖVE's `love.filesystem` API, which writes to a platform-safe user data directory automatically.

---

## What to save

### Flat values (GameState)
| Field | Type | Notes |
|-------|------|-------|
| `currency` | number | current gold |
| `speed_level` | number | 0–3 |
| `growth_level` | number | |
| `growth_mult` | number | derived from growth_level, but simpler to store directly |
| `unlocked_plants` | table (int→bool) | sparse, key = plant_type |
| `stage3_counts` | table (int→int) | harvest counts per plant type |
| `seen_scripts` | table (string→bool) | which dialogue lines have fired |

### Store / slots
For each slot, save:
- `slot_count` — total number of slots (determines store width)
- Per slot: `slot_index`, `item_type` (`"plant"` or `nil`), and if a plant:
  - `plant_type`
  - `stage`
  - `ready` (bool)
  - `cooldown_remaining` (seconds left on the timer)

### Player
- `speed_level` already covers the player's speed; no extra player fields needed.

---

## What NOT to save
- Sprite/visual state — reconstructed from data on load
- `slot_width`, `slot_x/y` — derived from config constants
- Held item — drop it before saving, or save its slot index

---

## Format

Use a plain Lua table serialized to a string with `love.filesystem.write`. LÖVE has no built-in serializer, so either:

- **Option A — hand-roll a simple serializer** for the flat structure above (no nested metatables, so straightforward)
- **Option B — bundle a tiny library** like `bitser` or `ser` (single-file, MIT licensed)

Option A is simplest given how flat the data is.

---

## File location

```
love.filesystem.write("save.dat", serialized_string)
love.filesystem.read("save.dat")
```

LÖVE writes to `%APPDATA%\LÖVE\<identity>\` on Windows and `~/Library/Application Support/LÖVE/<identity>/` on Mac. The `identity` is set in `conf.lua`.

Because the save directory is outside the project folder, **save files never appear in the repo and no `.gitignore` is needed.**

`conf.lua` currently has no `t.identity` set, so LÖVE defaults to the folder name `"love"` — shared with every other LÖVE game on the machine. Set a unique identity to avoid collisions:

```lua
t.identity = "plantgame"
```

---

## Steps

### 1. Add `save()` and `load()` to `GameState`

`GameState:save()` — flatten all saveable fields into a plain table, serialize to string, write to `save.dat`.

`GameState.load()` — read `save.dat`, deserialize, construct a `GameState`, rebuild the `Store` and its `Slot`/`Plant` objects from the saved data, return the populated state.

### 2. Write a minimal serializer

A small module `lua/util/serialize.lua` that turns a plain table into a valid Lua literal string and reads it back with `load()`. Only needs to handle: numbers, booleans, strings, and flat/nested tables with string or integer keys.

### 3. Trigger save

**Save exclusively in `BuyScene:on_exit()`.**

All three exit paths in `buy_scene.lua` (lines 99, 135, 138, 141) go through `switch(self.store_scene)`, which triggers `on_exit()`. This is the only moment where purchases are committed and the player is guaranteed to have no held item — state is always clean here.

> **This must be clearly documented in `buy_scene.lua` with a comment on `on_exit()`.** Any future developer adding a new exit path (a new button, an escape shortcut, etc.) needs to know that skipping `on_exit()` will silently drop a save. The comment should explain both *that* saving happens here and *why* this is the chosen save point.

### 4. Wire up the start screen

`start_scene.lua` has New Game, Continue, Settings, and Exit buttons. `_confirm()` currently treats both New Game and Continue identically. Change it to:

- **New Game (1)** — call `GameState.new()`, delete any existing `save.dat`, then switch to `StoreScene`
- **Continue (2)** — call `GameState.load()` and switch to `StoreScene`; if no save file exists this button should appear dimmed and do nothing
- **Settings (3)** — already wired; calls `self.open_settings()`, no change needed
- **Exit (4)** — unchanged

To dim Continue when there's no save, check `love.filesystem.getInfo("save.dat")` in `StartScene:on_enter()` and store the result as `self._has_save`. Use it in `draw()` to set a muted color for that button, and in `_confirm()` to guard the Continue branch.

### 5. Handle version mismatches

Add a `save_version` integer to the save file. If the loaded version doesn't match the current version, fall back to `GameState.new()` and delete the stale file rather than crashing.
