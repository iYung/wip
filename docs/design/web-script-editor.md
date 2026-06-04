# Web Script Editor

## Goal

A GitHub Pages web app in a new standalone repo that lets you view and edit
`lua/game/data/customer_scripts.lua` from the browser and submit a WIP pull
request to `iYung/wip` without touching a terminal.

---

## Affected files

**New repo** — `iYung/wip-editor` (GitHub Pages, single static HTML page)
- `index.html` — app shell + markup
- `editor.js` — all app logic (parse, render, serialize, GitHub API calls)
- `styles.css` — layout and form styling

**`iYung/wip` repo** — no files change; the editor reads and writes it via
GitHub API only.

---

## What changes

### New repo: `iYung/wip-editor`

A single-page static app with no build step.

**Auth**
- On load, if no PAT in `sessionStorage`, show a modal prompting for a GitHub
  Personal Access Token (scope: `repo`).
- Store in `sessionStorage` (cleared on tab close; never written to
  `localStorage`).
- Show "Connected" indicator + a "Clear token" link once set.

**Fetch**
- On load (after PAT is set), call
  `GET /repos/iYung/wip/contents/lua/game/data/customer_scripts.lua`
  (GitHub REST API) to get the Base64-encoded file content and the file's
  SHA (needed later for the commit).
- Decode → parse Lua into a JS array of entry objects.

**Parse / Serialize**
- JavaScript port of the regex-based parser already in `tools/quest_editor.py`.
- Fields per entry: `id`, `chapter`, `name`, `voice_pitch`, `accessory`,
  `trigger {plant_type, count}`, `primary_color [r,g,b,a]`,
  `secondary_color [r,g,b,a]`, `plant_type`, `messages []`,
  `after_messages []`, optional `no_dismiss`.
- Serialize back to clean Lua (regenerated, not diffed) using a fixed
  indentation template that matches the existing file's style.

**UI**

```
┌─────────────────────────────────────────────────────────────┐
│  [PAT: ●●●●●●●  ✕]                     [Submit PR]         │
├──────────────┬──────────────────────────────────────────────┤
│ mayor_bloom  │  mayor_bloom  ·  chapter 1                   │
│ the_collector│  ┌──────────────────────────────────────┐   │
│ mira         │  │ name         [Mayor Bloom           ] │   │
│ mechafrog    │  │ voice_pitch  [0.82                  ] │   │
│ dottie       │  │ accessory    [secretary_glasses     ] │   │
│ agent_frogsby│  │ primary_color [■ #BF4066            ] │   │
│ sage         │  │ secondary_color [■ #263380          ] │   │
│              │  │ plant_type   [3                     ] │   │
│              │  │ trigger      plant_type [3] count [6] │   │
│              │  │ messages     [line 1               ] │   │
│              │  │              [line 2               ] │   │
│              │  │              [+ add line]             │   │
│              │  │ after_msgs   [line 1               ] │   │
│              │  │              [+ add line]             │   │
│              │  │ no_dismiss   [ ]                      │   │
│              │  └──────────────────────────────────────┘   │
│              │  ── chapter 2 ─────────────────────────────  │
│              │  ...                                         │
│   [+ add     │                              [+ add chapter] │
│    character]│                                              │
└──────────────┴──────────────────────────────────────────────┘
```

- Left sidebar: character list (one row per unique `id`, showing `name`).
- Right panel: all chapters for the selected character, stacked vertically.
- Color fields: clicking the color swatch opens `<input type="color">`;
  value stored as `[r,g,b,a]` floats (0–1 range) converted to/from hex.
- Messages / after_messages: one `<textarea>` per line; "add line" appends;
  an ✕ on each line removes it.
- "Add chapter" appends a new chapter entry pre-filled from the previous
  chapter's metadata.
- "Add character" appends a new character (all blank).

**Submit PR flow**
1. Click "Submit PR" → modal asks for branch name (default:
   `wip/scripts-{YYYY-MM-DD}`) and PR title (default:
   `wip: update character scripts`).
2. App calls:
   a. `GET /repos/iYung/wip/git/ref/heads/main` → get base SHA
   b. `POST /repos/iYung/wip/git/refs` → create branch
   c. `PUT /repos/iYung/wip/contents/lua/game/data/customer_scripts.lua`
      → commit serialized Lua (using original file SHA for conflict check)
   d. `POST /repos/iYung/wip/pulls` → open PR targeting `main`
3. On success, show a toast with a link to the new PR.

---

## What stays the same

- `lua/game/data/customer_scripts.lua` format is unchanged — the serializer
  regenerates the same field names and structure.
- `tools/quest_editor.py` (tkinter) still works locally; this is a parallel
  tool, not a replacement.
- No changes to `iYung/wip`'s CI, game code, or any existing workflow.

---

## Open questions

_None — all answered before writing this doc._
