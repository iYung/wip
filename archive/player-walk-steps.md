# Player Walk Sprite Steps

Goal: 4-frame walk animation that distinguishes held vs not-held, with neutral feet as the resting pose.

---

## Frames

| Key | Condition | Pose |
|-----|-----------|------|
| `"idle"` | no held item, stopped or end-of-step | neutral feet |
| `"walk"` | no held item, mid-step | feet separated |
| `"idle_held"` | holding item, stopped or end-of-step | neutral feet |
| `"walk_held"` | holding item, mid-step | feet separated |

Walk cycle alternates `idle ↔ walk` (or `idle_held ↔ walk_held`) every 0.15s while moving. When movement stops, always snap back to `idle` or `idle_held`.

---

## Step 1 — Sprite Assets

- [ ] Replace the two placeholder sprites (`sa`, `sb`) in `Player.new()` with four:
  - `idle` — distinct placeholder color A
  - `walk` — distinct placeholder color B (slightly different shade)
  - `idle_held` — distinct placeholder color C
  - `walk_held` — distinct placeholder color D (slightly different shade from C)
- [ ] Register all four under their key names in the SpriteSet
- [ ] Set initial frame to `"idle"`

---

## Step 2 — Animation Logic

- [ ] Remove `_anim_frame = "a"/"b"` references from `Player:update()`
- [ ] At the start of the animation block, derive the two relevant keys:
  ```
  idle_key = held_item and "idle_held" or "idle"
  walk_key = held_item and "walk_held" or "walk"
  ```
- [ ] While moving: toggle `_anim_frame` between `idle_key` and `walk_key` on timer tick
- [ ] While stopped: snap `_anim_frame` to `idle_key`
- [ ] Call `self.sprite:set(self._anim_frame)` after any change

---

## Step 3 — Held-State Switch on Pick Up / Put Down

When the player picks up or puts down an item mid-walk, the frame keys change immediately. No extra work needed — Step 2 re-derives `idle_key`/`walk_key` every frame from `held_item`, so the switch is automatic.

Verify:
- [ ] Pick up while walking → switches to `walk_held` on the next timer tick
- [ ] Put down while stopped → immediately shows `idle`

---

## Step 4 — End-to-End Test

- [ ] Standing still, no item → `idle` frame
- [ ] Walking, no item → alternates `idle ↔ walk`, ends on `idle` when stopped
- [ ] Pick up item, stand still → `idle_held`
- [ ] Walking with item → alternates `idle_held ↔ walk_held`, ends on `idle_held` when stopped
- [ ] Put item down mid-walk → switches to no-held cycle immediately
