# Floating Action Prompts

## Goal

Players don't know which of the 3 action buttons (J/K/L) to press in a given situation. This causes them to guess wrong, feel lost, or stop playing. The fix is to make the correct button visible at the point of decision — spatially connected to the item they need to act on — rather than in the corner of the screen.

## Root cause

The game has 3 action buttons with context-sensitive behavior:

| Button | Default key | Meaning changes based on... |
|---|---|---|
| Interact | J | What you're holding + what's in the active slot + zone (store vs. cashier) |
| Pick Up / Put Down | K | Whether you're holding something + what's in the slot |
| Cancel | L | Only useful in the cashier zone to dismiss a customer |

The only existing hint is a small box in the bottom-left corner that lists available actions. Players miss it because:
- Their eyes are on the player / active slot in the center of the screen
- The corner HUD is there but disconnected from the action spatially
- On first play there is no indication that the corner box exists

## What changes

Add **floating action prompts** rendered in screen-space above the active slot (or near the customer bubble in the cashier zone). Each prompt shows the button key and a brief action label — identical content to what the corner HUD already computes — but positioned right where the player is looking.

### Store zone (player.x >= 0)

When the player is hovering a slot:
- Show `[K] PICK UP` or `[K] SWAP` or `[K] PUT DOWN` above the slot if K has an action
- Show `[J] WATER`, `[J] CLONE`, `[J] DISCARD`, `[J] OPEN SHOP`, etc. above the slot if J has an action
- Both can appear stacked (K above J, or J above K by priority)

The prompt anchor is the slot's world-space x + half-width, at a fixed Y above the slot top (e.g. `slot.y - 24`). This position is projected through the camera transform so it moves with the world correctly.

### Cashier zone (player.x < 0)

When the player is in the cashier zone and a customer is present:
- Show `[J] NEXT`, `[J] SELL ($n)`, `[J] SKIP` above the customer bubble position
- Show `[L] DISMISS` near the customer if applicable

### Visual design

- Small speech-bubble-style box (reuse the existing `draw9` / `A.speech_bubble` assets) or bare text with a key chip
- Key name displayed in a distinct style (larger or bold or enclosed in brackets) so it reads at a glance
- Fade in on slot enter, fade out on slot leave (simple alpha tween, ~0.15s)
- Does not replace the corner HUD — that stays as a reference; the floating prompts are the primary affordance

## What stays the same

- Control scheme unchanged (J/K/L, fully remappable)
- Corner HUD box remains (same content, same position)
- Item behavior and game mechanics are untouched
- No changes to `lua/game/items/` files
- No changes to player, store, or customer logic

## Affected files

- `lua/game/scenes/store_scene.lua` — add `_floating_prompts()` method (similar to existing `_hud_labels()`) and render floating prompts in `draw()` after the camera detach, projected from world-space slot positions to screen-space
- `lua/game/ui.lua` — optionally extract a `draw_action_chip(key, label, x, y)` helper if the floating prompt drawing is complex enough to share

## Open questions

None — proceed to checklist.
