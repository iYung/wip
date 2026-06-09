# Progress

## What's Built

All MVP steps are implemented and running. Expand Store, Shop UI, Plant Types, Context HUD, Cashier Zone, Speed Upgrade, Player Walk, Customer System, Sprite Images, Facing Direction, and Customer Scripts (return customers + questlines) features complete.

Completed step files are moved to [`archive/`](archive/).

---

### Core (`lua/core/`)

| File | What it does |
|------|-------------|
| `sprite.lua` | Single drawable unit — draws a PNG image scaled to `width × height` if set, colored rectangle otherwise; `color` always applies as a tint |
| `spriteset.lua` | Named collection of sprites, one active at a time; forwards x/y to active sprite on draw |
| `drawer.lua` | Holds drawables sorted by priority, calls draw() each frame |
| `camera.lua` | Translates world → screen; follow(target, lerp) with 0=instant, 1=no movement |
| `scene.lua` | Base class with drawer + camera; on_enter/on_exit lifecycle |
| `scene_manager.lua` | Swaps scenes, calls on_exit/on_enter, delegates update/draw |
| `fonts.lua` | Generic font factory — `from(path, hinting)` returns a `{new(size)}` object; no game-specific knowledge |

---

### Game (`lua/game/`)

| File | What it does |
|------|-------------|
| `assets.lua` | Loads all PNGs once at startup; require-cached so every file can `require` it cheaply; `sneakers`, `expand_slot`, `water_drone`, and `water_drone2` loaded conditionally via `try_img` (art not yet created); all other assets use `img()` and are required to exist |
| `config.lua` | Shared constants — `U`, `SLOT_COST`, `ZONE_WIDTH` (400px cashier zone) |
| `input.lua` | Polls keyboard each frame; A/D or arrows = move, E = pick up/down, F = interact |
| `game_state.lua` | Holds store, player, currency, `unlocked_plants`, `stage3_counts`, `seen_scripts`, `speed_level`, `growth_level`, `growth_mult`, `has_drone`; survives scene switches |
| `player.lua` | Moves left/right into cashier zone; holds one item; 4-variant SpriteSet (idle/walk × no-held/held), each backed by a PNG; `speed` upgradeable via shop; uses `ColorReplace` shader to swap pure-red mask pixels to the current speed tier color on draw |
| `slot.lua` | One store cell; single `slot.png` background sprite; positions its item every frame |
| `store.lua` | Array of slots; `slot_at(x)`, `grow()`, `draw_bubbles()` for high-priority bubble rendering; `draw_bg(A)` draws wall tiles and window frames using group-of-4 rule; all wall draws go through a `draw_wall(img, x)` helper that applies the `WallPattern` shader when `A.wall_pattern` is set |
| `customer.lua` | Cashier zone NPC; white PNG tinted per character via `primary_color`/`secondary_color`; optional `accessory_sprite` (120×120) drawn over the top half, synced to body flip; dialog lines reveal character-by-character (40 chars/s) inside a 9-slice `speech_bubble.png` box; F skips to full line, second F advances; `line_complete()` / `skip_reveal()` methods; state machine: idle → walking_in → waiting → **talking_after** → walking_out; `dismiss()` sends customer away without selling; when waiting, shows a 9-slice speech bubble containing the requested plant's stage-3 image; `after_messages` optional field plays post-sale lines before the heart bubble appears. |

### Items (`lua/game/items/`)

| File | What it does |
|------|-------------|
| `item.lua` | Base class for all carriable objects; `carriable = true`, `sellable = true`, `name = "Item"` by default |
| `watering_can.lua` | interact() waters the plant in the active slot; blue PNG |
| `pc_store.lua` | interact() opens BuyScene; blocked if player is holding anything; `sellable = false`; blue-grey PNG |
| `plant.lua` | 6 types, 3 stages each; per-type cooldown from `plant_data`; stage PNGs rendered as-is (no tinting); yellow bubble via `draw_bubble()` |
| `grafter.lua` | Clones a stage-3 plant (resets original to stage 1); auto-spawns clone into nearest empty slot; no-space bubble (60×60, `grafter_no_space_bubble.png`) shown for 1.5 s when no slot available; always shows orange PNG |
| `intercom.lua` | Purchasable tool ($50); shows the customer's plant request bubble above itself; `draw_bubble()` mirrors the customer's done-talking plant image; save/load safe via `_wire_intercom()` |
| `water_drone.lua` | One-time purchase ($10); autonomous drone that scans for water-ready plants, flies to them at a fixed elevation, waters them, idles in place, and increments `stage3_counts` when a plant reaches stage 3 (same as the player path); 2-frame sprite animation (10fps flip); drawn above heat lamps and below the player |
| `sell_bin.lua` | Sell station; F while holding any sellable item sells it for currency; red PNG |

### Scenes (`lua/game/scenes/`)

| File | What it does |
|------|-------------|
| `start_scene.lua` | Title screen with New Game / Continue / Settings / Exit buttons; up/down/W/S navigate, Enter/Space/F confirms; New Game and Continue both enter StoreScene; Settings opens the `SettingsMenu` overlay via callback; fonts saved and restored each draw so global font state is unaffected |
| `settings_menu.lua` | Pause overlay — six buttons (Fullscreen/Window, SFX Volume, Music Volume, Keybinds, Exit Settings, Leave Game); SFX and Music Volume rows each show `< XX% >` and respond to left/right keys in 10% steps; Keybinds opens a sub-screen listing all 6 actions with press-to-capture rebinding; navigation uses remapped move_up/move_down keys; `is_open` gates scene update in `main.lua`; drawn inside the canvas so it scales with the window; when opened opaque (from start screen), background alternates between `settings_pattern_1.png` and `settings_pattern_2.png` once per second |
| `settings_state.lua` | Holds user settings: `fullscreen` bool, `sfx_volume`/`music_volume` integers (0–100), and `keybinds` table (6 actions); `set_sfx_volume`/`set_music_volume` clamp and call `Sound` directly; `set_keybind` clears collisions; `key_map()` produces `Input`-compatible map; passed to `SettingsMenu.new(ss, input)` at startup |
| `store_scene.lua` | Main loop — player moves, camera follows on x then clamps to world bounds (left = -400+640, right = store width−640), pick up/interact handled here; cashier zone logic (F skips reveal → advances → sells, E dismisses); context HUD bottom-left shows F: SKIP while typing, F: NEXT when done, E: DISMISS when customer waiting; during `talking_after` (post-sale scripted lines) shows F: SKIP while typing, F: CONTINUE when line is done; `_active_script_key` tracks the current scripted customer (seen_scripts written on sale, not on spawn); `_script_cooldowns` counts down per completed sale — dismissed scripted customers return after 3 sales; unified parallax tiles `store_bg_*` across full world width pre-drawer; `Store:draw_bg` then stamps walls/windows on top; layered draw order for wall/bubbles |
| `buy_scene.lua` | Carousel UI — 14 items (6 plants + Watering Can + Grafter + Intercom + Expand Slot + Sneakers + Heat Lamps + Marketing + Water Drone); A/D cycle, F buy, E cancel; per-type price and preview color; one-time purchases show sold-out state after purchase; scene rendered to off-screen canvas and composited through CRT post-process shader |

### Data (`lua/game/data/`)

| File | What it does |
|------|-------------|
| `plant_data.lua` | Per-type name, buy cost, sell value, and cooldowns for all 6 plant types |
| `customer_scripts.lua` | Array of scripted customer chapters; each has `id`, `chapter`, `trigger` (plant_type + stage-3 count), name, body color, optional `accessory`, requested plant, and dialog messages; same `id` = same character across visits; chapter N requires all prior chapters seen |

### Assets (`assets/`)

PNG files for all sprites — player variants, plants (18 total: 6 types × 3 stages, rendered without tinting), items, UI elements, backgrounds, and speech bubbles.

Accessory PNGs for named customers (120×120, transparent background) live in `assets/images/`. Loaded lazily by `A.load_accessory(name)`; missing files are cached as `false` so no disk re-check occurs. Contains `monocle.png` (Sir Moneyton), `secretary_glasses.png` (Mayor Bloom), `shades.png` (The Collector), `hair_bow.png` (Mira), `antenna.png` (Mechafrog), `clown.png` (Dottie), `coat.png` (Agent Frogsby), `headphones.png` (Glen).

---

## Key Numbers

| Thing | Value |
|-------|-------|
| Base unit `U` | 20px |
| Slot size | 6U × 10U (120×200) |
| Player size | 6U × 12U (120×240) |
| All items | 6U × 6U (120×120) |
| Customer bubble | 6U × 6U (120×120) — matches plant sprite size |
| Plant bubble | 3U × 3U (60×60) |
| Initial slots | 10 |
| Player speed | 220 px/s (base); upgradeable |
| Camera lerp | 0.85 (smooth follow on x, locked y) |
| Cashier zone width | 20U (400px), at x = -400 to 0 |
| Customer walk speed | 80 px/s |
| Customer spawn interval | 3–6s |

---

## Controls

Defaults — all remappable via Settings → Keybinds.

| Key | Action |
|-----|--------|
| A | Move left |
| D | Move right |
| W / S | Navigate menus up / down |
| E | Pick up / put down (in cashier zone: dismiss customer) |
| F | Interact (water, open shop) |
| Escape | Open settings menu (in gameplay); quit (on start screen) |

---

## Full Loop

**Growing:**
1. Walk to slot 3 (PC) with empty hands → F to open shop
2. F to buy → plant appears in your hand
3. E over an empty slot → place plant
4. Walk to slot 1 → E to pick up watering can
5. Walk back to plant slot → wait for bubble
6. F → waters plant, bubble disappears, stage advances
7. Repeat for stage 2
8. Stage 3 = done, no more bubble

**Selling to a customer:**
1. Customer walks in from the left; if scripted, dialog begins
2. F to advance through their messages
3. Once done talking (or immediately if no dialog), a speech bubble with the plant image appears
4. Pick up the matching stage-3 plant
5. Walk into cashier zone (x < 0) → F to sell for 2× value

**Return customers / questlines:**
- Each time a plant type reaches stage 3, `stage3_counts[pt]` increments
- When a customer spawns, all script chapters whose trigger is met and whose prior chapters have been seen become eligible
- One eligible chapter is picked at random and marked seen (`seen_scripts["id:chapter"]`)
- Characters return across multiple visits as their thresholds are hit, carrying dialog continuity

---

## Up Next

See open questions in `game-design.md`.

### Recently completed

- **Settings persistence** — user settings (`sfx_volume`, `music_volume`, `fullscreen`, keybinds) now survive across sessions; `Save.write_settings`/`read_settings` write to a separate `settings.dat` (game-progress `save.dat` is untouched); `SettingsState` gains `to_save()` and `from_save(data)` — the latter applies values through the real setters so Sound and the window update immediately on load; settings are written on quit and when leaving the settings menu; 10 headless tests in `tests/test_settings_persistence.lua`

- **Inter font** — replaced Love2D's default Vera font with `assets/fonts/font.ttf` (Inter Variable) across all text-rendering sites; `lua/core/fonts.lua` is a generic `from(path, hinting)` factory; `lua/game/fonts.lua` binds it to the game's font file and `"light"` hinting; `main.lua` sets it as the default font so `StoreScene` HUD and customer speech bubbles inherit it automatically; `buy_scene`, `settings_menu`, and `start_scene` use `Fonts.new(size)` for their explicit fonts

- **Six speed tiers** — expanded the speed upgrade from 3 to 6 purchasable tiers (320/450/590/720/960/1200 px/s at $15/$30/$55/$100/$200/$360); primary shoe color now graduates blue → red from tier 0 onward (base tier 0 is pale sky blue `{0.5, 0.75, 1.0}`, replacing the old placeholder white) and every tier carries a `secondary` (dark brown sole/accent) color; `Player:set_speed_color(color, secondary)` (renamed from `set_speed_color(color)`) stores both and `draw()` passes both to `ColorReplace.apply`; `BuyScene` speed_boost preview updated to match; `tests/test_balance.lua` ROI loop now covers all 6 tiers, which surfaced and fixed a latent hang in the `walk_to` test helper (high-speed ticks could overshoot the 5px snap window and ping-pong forever — now exits as soon as the player crosses the target)

- **Water drone stage3_counts fix** — drone was calling `item:water()` directly without the stage-3 check that the player's interact handler does, so plants the drone advanced to stage 3 never incremented `gs.stage3_counts`; scripted customer triggers compare against those counts, so characters stopped spawning in drone-heavy runs; fix: `WaterDrone.new` now accepts `game_state` as a third arg and increments `stage3_counts[plant_type]` when `item.stage == 3` after a successful water; E5/E6 added to `test_water_drone.lua`; pre-existing E2 stub bug (missing `slot_width`) also fixed

- **Water Drone** — one-time purchase ($10) from the PC Store; autonomous drone flies at a fixed elevation (y=180) above heat lamps, scans for water-ready plants each frame, centers over the target slot, waters it and plays `"water_plant"` sound, then idles in place; 2-frame sprite animation swapping between `water_drone.png` and `water_drone2.png` at 20fps; drawn at priority 3.5 (above plant bubbles, below player); save/load safe via `_wire_drone()`; `has_drone` persists in `GameState`; 6 headless tests in `tests/test_water_drone.lua`

- **Plant growth rebalance** — cooldowns rewritten so grow time scales with value (Grass 7 s → Golden Lotus 90 s) instead of the old inverted curve where Golden Lotus was among the fastest; each plant now has a distinct stage-shape (e.g. Cactus slow-start/fast-bloom, Tulip fast-start/slow-bloom) to make them feel different at a glance; Heat Lamps remain the key upgrade for unlocking high-value plants at a competitive rate; `tests/test_plant_growth.lua` and `tests/test_grafter.lua` updated to drive timing from `PLANT_DATA` rather than hardcoded seconds

- **Intercom item** — purchasable from the PC Store for $50; shows the current customer's plant request bubble (same 9-slice visual and same timing as the bubble above the customer) when placed in any slot or held, so the player can see what plant is needed without walking to the cashier zone; carriable and discardable in the garbage bin; save/load preserves it; `tests/test_intercom.lua` (11 tests)

- **Speech bubble fix** — customer name prefix (`"Name: "`) removed from all dialogue lines (`make_full_text`, `serve`, `advance_after`); speech bubble now wraps long lines via `font:getWrap` with `MAX_BOX_W = 18 * U` (360px) so text never overflows the screen; bubble height grows to fit wrapped lines; typewriter reveal respects the same wrap limit

- **Web deploy** — game builds to WebAssembly via `love.js` and auto-deploys to GitHub Pages on every push to `main`; PRs get a live preview URL posted as a comment (`https://iyung.github.io/wip/pr-{n}/`) that is cleaned up on merge; on-screen controls (←↑↓→ d-pad + E / F / Esc action buttons) injected into the page for keyboard-less play; `conf.lua` gains `t.identity = "plantgame"` for save isolation

- **Background music + independent volume sliders** — looping `assets/music/background.mp3` plays via `Sound.load()` (silently skipped if the file is absent); `Sound.set_sfx_volume(v)` and `Sound.set_music_volume(v)` apply per-source volume so the two sliders are fully independent (global `love.audio.setVolume` no longer used); settings menu expanded to 6 items with a renamed "SFX Volume" row (index 2) and a new "Music Volume" row (index 3), both showing `< XX% >` and responding to left/right in 10% steps; `SettingsState` renamed `volume`→`sfx_volume` and added `music_volume`; Keybinds/Exit/Leave Game shifted to indices 4/5/6; 13/13 headless tests passing

- **Real sound effects** — `scripts/download_sounds.sh` downloads all 17 game-event sounds from craigsmith's public-domain freesound.org library and writes them to `assets/sounds/<event_name>.wav`; requires `FREESOUND_TOKEN` env var, `curl`, and `ffmpeg`; no code changes needed (filenames match the existing placeholders)

- **Keybind return validation** — the Keybinds sub-screen now blocks leaving (via Return button or Escape) until every action has a key assigned; the Return button renders at 0.4 alpha (matching the disabled Continue style on the start screen) with a red `"all keys must be bound"` hint line below it when any binding is nil; 4 new headless tests

- **Configurable keybinds** — all six game/menu actions (`move_up`, `move_down`, `move_left`, `move_right`, `pick_up_down`, `interact`) are remappable from Settings → Keybinds; press-to-capture flow (select action → next keypress sets binding); modifier keys ignored; binding a key to a new action automatically clears it from the old one; bindings live in `SettingsState.keybinds` and are applied to `input._map` immediately; 8 new settings-state tests + 8 new settings-menu tests (26 total)

- **SettingsState** — new `lua/game/settings_state.lua` data class holds `fullscreen` bool and owns the `love.window.setFullscreen` call via `toggle_fullscreen()`; `SettingsMenu` is now a pure view — it reads `_state.fullscreen` for the label and delegates all mutations to `SettingsState`; `main.lua` constructs `SettingsState.new()` and passes it to `SettingsMenu.new(ss)`; 3 headless tests added in `tests/test_settings_state.lua`; `tests/test_settings_menu.lua` updated to use a real `SettingsState` instance (18 tests total)

- **Settings menu** — Esc during gameplay (StoreScene, BuyScene) opens a pause overlay with "Fullscreen / Window", "Exit Settings", and "Leave Game"; start screen has a Settings button that opens the same overlay; game pauses while open; `esc_opens_settings = true` flag on each gameplay scene controls Esc behavior; draws `settings_background.png` when opened from start scene (via `open(true)`) so start menu buttons don't bleed through, semi-transparent in-game

- **Post-sale dialogue** — scripted characters can now say lines after a sale via `after_messages` in `customer_scripts.lua`; customer enters a `talking_after` state, player clicks through lines, then the heart bubble appears and they walk out; backwards-compatible (characters without `after_messages` walk out immediately as before)

- **Tutorial character (Sir Moneyton)** — 4-chapter scripted mentor; guaranteed first customer via `count=0` trigger; each chapter fires at a natural milestone (first grass, 3 grass sold, 3 cactus sold, 2 roses sold) and teaches a core mechanic (grow loop, PC store, store expansion, grafter); grafter tutorial comes after roses because roses cost $150 — grafting is how the player makes them profitable

- **Character accessories** — all scripted characters now have accessories as a visual signal distinguishing them from random customers; PNGs in `assets/` (`monocle`, `secretary_glasses`, `shades`, `clown`, `hair_bow`, `antenna`, `coat`, `flat_cap`)

- **Menu background shader** — `assets/shaders/menu_bg.glsl` + `lua/game/shaders/menu_bg.lua`; tiles a scrolling pattern texture over pure-red masked pixels in `start_bg.png`; scroll offset advances with time (60px/s horizontal, 30px/s vertical); pattern loaded from `assets/images/start_pattern.png` and gracefully disabled when absent; `_time` initialised in `StartScene.new()` so tests can call `update()` without `on_enter()`

- **Wall pattern shader** — `assets/shaders/wall_pattern.glsl` + `lua/game/shaders/wall_pattern.lua`; tiles a repeating pattern texture over pure-red pixels in wall/window images; world-space UV math keeps the pattern seamless across adjacent tiles; applied in both `Store:draw_bg` and the cashier wall in `StoreScene`; gracefully disabled when `assets/images/wall_pattern.png` is absent

- **CRT post-process shader (BuyScene)** — `assets/shaders/crt.glsl` + `lua/game/shaders/crt.lua`; BuyScene renders into a 1280×720 canvas then composites through the shader; effects: barrel distortion, chromatic aberration, scanlines, vignette; canvas pattern saves/restores `prev_canvas` so it works correctly inside main.lua's existing canvas wrapper

- **Visual test mode** — `--visual tests/foo.lua` flag runs a test file with a real window so you can watch each frame; `runner.tick` yields via coroutine after each update so `love.draw` fires between steps; `loadfile` used instead of `dofile` to avoid LuaJIT's yield-across-C-boundary restriction; `HeadlessInput` fixed: `_held` and `_queued` are now tracked separately so back-to-back `press()` calls on adjacent frames both fire as rising edges (previously the key lingered in `_down` and the second press was silently dropped)

- **Headless mode** — `--headless tests/foo.lua` flag stubs all Love2D graphics/audio and runs tests without a window; `lua/headless/` contains `stubs.lua`, `input.lua` (`HeadlessInput`), and `runner.lua` (`setup` / `tick` / `run`)

- **Golden Lotus timing test** — `tests/test_golden_lotus.lua` simulation test that grows and sells three grass plants (to reach $20), then buys and sells a Golden Lotus; measures total simulated seconds elapsed and asserts currency increased; uses `walk_to`, `fast_forward_until`, and `sell_plant` helpers with `math.randomseed(42)` for a deterministic run

- **Player speed sprites** — speed upgrades now apply a GLSL color-replace shader at draw time instead of swapping sprite sets; pure-red pixels in the player PNG are replaced with the tier's color (`speed_tiers.lua` now carries a `color` field per tier); `Player:set_speed_color(color, secondary)` stores the active colors; no extra PNG assets needed

- **Start screen** — `StartScene` with New Game / Continue / Exit buttons; keyboard navigation (up/down/W/S + Enter/Space/F); `main.lua` now opens `StartScene` first; `StoreScene` constructed lazily on confirm; font state saved/restored so store rendering is unaffected

- **Growth upgrade (Heat Lamps)** — purchasable 3-tier upgrade in the PC Store; tiers cost $20/$50/$100 and scale all plant timers by 1.25×/1.60×/2.00× via `gs.growth_mult` multiplied into `dt` in `StoreScene:update`; `SPEED_TIERS` moved from `config.lua` to `data/speed_tiers.lua` alongside new `data/growth_tiers.lua`

- **PC store item images** — Watering Can, Grafter, Expand Slot, Sneakers entries in buy_scene now show PNG previews instead of colored rectangles; Expand Slot and Sneakers fall back to a grey box until `expand_slot.png` / `sneakers.png` are created
- **Remove image fallbacks** — `slot_highlight`, `store_bg_*`, and `speech_bubble*` converted from `try_img` to `img()`; nil-checks removed from slot.lua and customer.lua draw sites; redundant `.color = {1,1,1,1}` assignments removed from player, watering_can, grafter, pc_store, and garbage_bin
- **Slot highlight image** — white rectangle replaced with `slot_highlight.png`
- **Plant images instead of tinting** — plant sprites now render their stage PNGs as-is; tint removed from `plant.lua`; customer request bubble replaced with a 9-slice speech bubble showing the stage-3 plant image; store preview shows stage-3 image; `colors` field no longer used for rendering
- **Customer dismiss** — E dismisses a waiting customer without selling; scripted characters go on a 3-sale cooldown and return (chapter stays unseen until served); `seen_scripts` now written on sale, not on spawn
- **Typewriter dialogue** — customer dialog lines reveal character-by-character at 40 chars/s inside a 9-slice `speech_bubble.png` box; F skips to the full line, a second F advances; HUD label switches between F: SKIP and F: NEXT; graceful fallback to text-only if the bubble asset is missing
- **Slot item centering** — items now centered using `spr.width`/`spr.height` instead of hardcoded offsets
- **Plant bubble while held** — `Player:draw()` calls `draw_bubble()` on the held item so the bubble is visible while carrying a ready plant
- **Garbage bin replaces sell bin** — `GarbageBin` (F: DISCARD) is the active discard station; `sell_bin.lua` removed
- **Store camera bounds** — camera x clamped after follow so neither screen edge overruns the world; active from the start with 6 slots (world 1800px > screen 1280px)
- **Store background walls** — `Store:draw_bg(A)` tiles `store_wall.png` and places `store_window.png` using a group-of-4 rule; parallax layers (`store_bg_*`) tile across full world width (-ZONE_WIDTH → store:width()) as a single unified system covering both the cashier zone and store; parallax factors 0.05/0.20/0.45
- **Initial slots set to 10** (for testing)

## Cut / Not Yet Built

- Win condition or idle loop
- Customer patience timer (customer never leaves until served)
