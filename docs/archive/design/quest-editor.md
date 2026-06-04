# Quest Editor Tool

## Goal

A standalone Python/tkinter desktop tool that reads and writes `lua/game/data/customer_scripts.lua`, letting you visualize all questlines side-by-side and edit individual quest chapters without touching the Lua file by hand.

---

## Affected files

| Path | Change |
|------|--------|
| `tools/quest_editor.py` | New — the entire tool |
| `lua/game/data/customer_scripts.lua` | Written by the tool on Save; format preserved |

---

## What changes

### New file: `tools/quest_editor.py`

A single-file Python script, zero dependencies beyond the standard library (`tkinter`, `re`, `os`). Run with:

```
python3 tools/quest_editor.py
```

Looks for `lua/game/data/customer_scripts.lua` relative to the repo root (two directories up from `tools/`). If the file is not found it shows an error dialog.

---

### Layout

```
┌─────────────────────────────────────────────┬──────────────────────┐
│  SWIMLANE CANVAS (scrollable)               │  EDIT PANEL          │
│                                             │                      │
│  sage    [ch1]──[ch2]──[ch3]──[ch4]         │  (empty until a      │
│  mira    [ch1]──[ch2]                       │   chapter is         │
│  dottie  [ch1]──[ch2]──[ch3]               │   clicked)           │
│  agent_frogsby [ch1]──[ch2]                 │                      │
│  ...                                        │  Fields:             │
│                                             │  - id                │
│                                             │  - chapter           │
├─────────────────────────────────────────────│  - name              │
│  [+ Add Quest]   [Save to Lua]              │  - trigger plant/cnt │
└─────────────────────────────────────────────│  - plant requested   │
                                              │  - messages (list)   │
                                              │  - after_messages    │
                                              │  - primary color     │
                                              │  - secondary color   │
                                              │  - voice_pitch       │
                                              │  - accessory         │
                                              │  - no_dismiss (bool) │
                                              │                      │
                                              │  [Delete Chapter]    │
                                              └──────────────────────┘
```

---

### Swimlane canvas

- One horizontal row per unique character `id`, ordered by the trigger count of their first chapter.
- Chapters within each row are ordered left-to-right by chapter number.
- Each chapter is a rounded rectangle ("card") showing:
  - `Name — Ch N`
  - Trigger line: `needs [Plant] ×N`  (e.g. `needs Grass ×3`)
  - Request line: `requests [Plant]`
- Cards are color-coded by the **requested plant type** using the plant's sell color (derived from plant_data order: each plant type gets a distinct hue).
- Cards are connected by horizontal arrows within a row.
- **First appearance badge**: a small star/label on the first card (across all rows, ranked by trigger count) where each plant type appears for the first time — either as a trigger or a request. This answers "where is Tulip first introduced?".
- Canvas is horizontally scrollable if there are many chapters.

---

### Edit panel

Appears on the right when a card is clicked. All fields are editable in-place via text entries, spinboxes, and listboxes (for messages). Color fields show a small colored swatch and open a color picker on click.

Pressing **Delete Chapter** removes that chapter from the in-memory data (with a confirmation dialog). All changes are local until **Save to Lua** is pressed.

---

### Add Quest

Clicking **+ Add Quest** opens a dialog asking for:
- Character id (new or existing)
- Chapter number (auto-incremented if existing id selected)

A blank chapter is inserted with default values and immediately selected in the edit panel.

---

### Lua parser / writer

- **Parser**: Custom Python regex/line parser. Reads the `return { ... }` block, splits on top-level `{` `}` pairs to isolate each entry, extracts keys with typed parsing (string, number, bool, inline table, array).
- **Writer**: Serializes the in-memory list back to Lua table notation matching the original file style (aligned `=`, quoted strings, inline color arrays, multi-line message arrays). Does not reformat lines it didn't touch — the output format matches the existing file closely enough to produce clean diffs.
- No Lua interpreter is required; the format is regular enough for regex handling.

---

## What stays the same

- All game code (`lua/`) — the tool only reads/writes `customer_scripts.lua`.
- The Lua data format and field names — no schema changes.
- CI/test pipeline — the tool is not part of the test suite or build.

---

## Open questions

None — implementation can proceed.
