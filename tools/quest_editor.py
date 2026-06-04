"""
quest_editor.py — Quest Editor UI (Tasks A + B)
Parse and write lua/game/data/customer_scripts.lua, then display in a tkinter window.
"""

import re
import os
import tkinter as tk
from tkinter import messagebox, colorchooser, ttk

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS_PATH = os.path.join(REPO_ROOT, "lua", "game", "data", "customer_scripts.lua")

# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

def _parse_number(s):
    """Return int or float from a numeric string."""
    s = s.strip()
    if '.' in s:
        return float(s)
    return int(s)


def _parse_string_list(block):
    """
    Parse a Lua array of strings:  { "a", "b", ... }
    Returns a list of str (with surrounding quotes stripped).
    """
    items = []
    # Match every double-quoted string inside the block
    for m in re.finditer(r'"((?:[^"\\]|\\.)*)"', block):
        items.append(m.group(1))
    return items


def _parse_color(block):
    """
    Parse a Lua color array:  {0.75, 0.25, 0.40, 1}
    Returns a list of floats.
    """
    inner = block.strip().lstrip('{').rstrip('}')
    return [_parse_number(x) for x in inner.split(',')]


def _parse_trigger(block):
    """
    Parse an inline trigger table:  { plant_type = 3, count = 5 }
    Returns a dict with int values.
    """
    result = {}
    for m in re.finditer(r'(\w+)\s*=\s*(\d+)', block):
        result[m.group(1)] = int(m.group(2))
    return result


def _split_entries(body):
    """
    Split the top-level Lua table body into individual entry strings.
    Each entry is a balanced { ... } block.
    Skips comments and whitespace between entries.
    """
    entries = []
    i = 0
    n = len(body)
    while i < n:
        # skip whitespace and comments
        if body[i] in ' \t\r\n':
            i += 1
            continue
        if body[i:i+2] == '--':
            # line comment — skip to end of line
            end = body.find('\n', i)
            i = end + 1 if end != -1 else n
            continue
        if body[i] == '{':
            # find the matching closing brace
            depth = 0
            j = i
            while j < n:
                if body[j] == '{':
                    depth += 1
                elif body[j] == '}':
                    depth -= 1
                    if depth == 0:
                        entries.append(body[i:j+1])
                        i = j + 1
                        break
                j += 1
            else:
                break
        else:
            i += 1
    return entries


def _parse_entry(block):
    """
    Parse one Lua table entry (the { ... } block, without outer braces stripped)
    into a Python dict.
    """
    # Strip outer { }
    inner = block.strip()
    assert inner.startswith('{') and inner.endswith('}'), f"Unexpected block: {inner[:40]}"
    inner = inner[1:-1]

    entry = {}

    # We'll consume the inner text key by key.
    # Strategy: scan for   key = value   patterns.
    # Values can be: string, number, bool, inline table, or multi-line array.

    pos = 0
    n = len(inner)

    while pos < n:
        # Skip whitespace and commas between top-level fields
        if inner[pos] in ' \t\r\n,':
            pos += 1
            continue
        # Skip comments
        if inner[pos:pos+2] == '--':
            end = inner.find('\n', pos)
            pos = end + 1 if end != -1 else n
            continue

        # Match:  identifier  =
        m = re.match(r'(\w+)\s*=\s*', inner[pos:])
        if not m:
            pos += 1
            continue

        key = m.group(1)
        pos += m.end()

        # Now determine the value type
        if pos >= n:
            break

        ch = inner[pos]

        if ch == '"':
            # String value
            # Find matching close quote (handle escape sequences)
            end = pos + 1
            while end < n:
                if inner[end] == '\\':
                    end += 2
                elif inner[end] == '"':
                    end += 1
                    break
                else:
                    end += 1
            value = inner[pos+1:end-1]
            pos = end

        elif ch == '{':
            # Either inline table or array of strings
            # Find matching closing brace
            depth = 0
            j = pos
            while j < n:
                if inner[j] == '{':
                    depth += 1
                elif inner[j] == '}':
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            block_content = inner[pos:j+1]
            pos = j + 1

            # Determine whether it's a string array, color array, or trigger table
            # Check for quoted strings → string array
            if '"' in block_content:
                value = _parse_string_list(block_content)
            # Check for named keys (word = number) → table
            elif re.search(r'\w+\s*=', block_content):
                value = _parse_trigger(block_content)
            else:
                # Assume numeric array (color)
                value = _parse_color(block_content)

        elif inner[pos:pos+4] == 'true':
            value = True
            pos += 4

        elif inner[pos:pos+5] == 'false':
            value = False
            pos += 5

        else:
            # Number — read until comma, whitespace, or end
            end = pos
            while end < n and inner[end] not in ',\n\r \t':
                end += 1
            value = _parse_number(inner[pos:end])
            pos = end

        entry[key] = value

    return entry


def parse_scripts(path=SCRIPTS_PATH):
    """
    Read the Lua file at *path* and return a list of dicts.
    """
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Strip outer  return {  ...  }
    m = re.match(r'\s*return\s*\{(.*)\}\s*$', text, re.DOTALL)
    if not m:
        raise ValueError("File does not match expected  return { ... }  structure")

    body = m.group(1)
    raw_entries = _split_entries(body)

    return [_parse_entry(e) for e in raw_entries]


# ---------------------------------------------------------------------------
# Writer
# ---------------------------------------------------------------------------

def _fmt_number(v):
    """Format a number: ints stay int, floats get 2 decimal places."""
    if isinstance(v, int):
        return str(v)
    # Format float — strip trailing zeros but keep at least one decimal place
    s = f"{v:.2f}".rstrip('0')
    if s.endswith('.'):
        s += '0'
    return s


def _fmt_color(arr):
    """Format a color array on one line: {0.75, 0.25, 0.40, 1}"""
    parts = []
    for v in arr:
        if isinstance(v, int):
            parts.append(str(v))
        else:
            # keep two decimal places for color components
            s = f"{v:.2f}"
            parts.append(s)
    return '{' + ', '.join(parts) + '}'


def _fmt_trigger(d):
    """Format an inline trigger table: { plant_type = 3, count = 5 }"""
    parts = [f"{k} = {v}" for k, v in d.items()]
    return '{ ' + ', '.join(parts) + ' }'


def _fmt_string_list(strings, indent=12):
    """Format a multi-line string array."""
    pad = ' ' * indent
    lines = ['{\n']
    for s in strings:
        lines.append(f'{pad}"{s}",\n')
    # closing brace at 8-space indent
    lines.append(' ' * 8 + '}')
    return ''.join(lines)


# Field ordering to match the original file style
_FIELD_ORDER = [
    'id', 'chapter', 'no_dismiss', 'accessory', 'trigger', 'name',
    'voice_pitch', 'primary_color', 'secondary_color', 'plant_type',
    'messages', 'after_messages',
]


def _write_entry(entry):
    """Serialize one entry dict to a Lua table string (without trailing comma)."""
    lines = ['    {\n']

    # Determine the alignment column for '=' signs.
    # Compute maximum key length for keys present in this entry.
    present_keys = [k for k in _FIELD_ORDER if k in entry]
    # extra keys not in our order list
    extra_keys = [k for k in entry if k not in _FIELD_ORDER]
    all_keys = present_keys + extra_keys

    max_key_len = max(len(k) for k in all_keys) if all_keys else 0
    # Each key is padded to (max_key_len) chars; then ' = '
    # The original file uses varying alignment per entry.

    def key_part(k):
        return k.ljust(max_key_len)

    for k in present_keys + extra_keys:
        if k not in entry:
            continue
        v = entry[k]

        # Skip no_dismiss if False (default)
        if k == 'no_dismiss' and not v:
            continue

        kp = key_part(k)

        if k in ('messages', 'after_messages'):
            val_str = _fmt_string_list(v)
            lines.append(f'        {kp} = {val_str},\n')
        elif k in ('primary_color', 'secondary_color'):
            val_str = _fmt_color(v)
            lines.append(f'        {kp} = {val_str},\n')
        elif k == 'trigger':
            val_str = _fmt_trigger(v)
            lines.append(f'        {kp} = {val_str},\n')
        elif k == 'no_dismiss':
            lines.append(f'        {kp} = true,\n')
        elif isinstance(v, bool):
            lines.append(f'        {kp} = {"true" if v else "false"},\n')
        elif isinstance(v, str):
            lines.append(f'        {kp} = "{v}",\n')
        elif isinstance(v, float):
            lines.append(f'        {kp} = {_fmt_number(v)},\n')
        else:
            lines.append(f'        {kp} = {v},\n')

    lines.append('    }')
    return ''.join(lines)


def write_scripts(entries, path=SCRIPTS_PATH):
    """
    Serialize *entries* (list of dicts) back to Lua and write to *path*.
    """
    parts = ['return {\n']
    for i, entry in enumerate(entries):
        parts.append(_write_entry(entry))
        if i < len(entries) - 1:
            parts.append(',\n\n')
        else:
            parts.append(',\n')
    parts.append('}\n')

    with open(path, 'w', encoding='utf-8') as f:
        f.write(''.join(parts))


# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

class QuestEditorApp:
    """Main application window for the Quest Editor."""

    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("Quest Editor")
        self.root.geometry("1280x720")
        self.root.resizable(True, True)

        # Resolve the Lua file path relative to this tools/ directory
        tools_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.dirname(tools_dir)
        self.script_path = os.path.join(
            repo_root, "lua", "game", "data", "customer_scripts.lua"
        )

        # Load data
        if not os.path.isfile(self.script_path):
            messagebox.showerror(
                "File not found",
                f"Could not find customer_scripts.lua at:\n{self.script_path}",
            )
            root.destroy()
            return

        self.scripts = parse_scripts(self.script_path)
        self._editing_key   = None
        self.card_positions = {}   # (id, chapter) -> (x, y) top-left; persists across redraws
        self.item_to_card   = {}   # canvas item id -> (id, chapter)
        self.card_tags      = {}   # (id, chapter) -> canvas tag string
        self.card_coords    = {}   # (id, chapter) -> (x1, y1, x2, y2)
        self._drag_state    = None
        self._pan_mode      = False

        # ------------------------------------------------------------------ #
        # Layout                                                               #
        # ------------------------------------------------------------------ #

        # Top container holds the two panes side by side
        self.root.rowconfigure(0, weight=1)
        self.root.rowconfigure(1, weight=0)
        self.root.columnconfigure(0, weight=1)

        # Use a PanedWindow so the user can drag the divider
        self.paned = tk.PanedWindow(
            self.root,
            orient=tk.HORIZONTAL,
            sashrelief=tk.RAISED,
            sashwidth=4,
        )
        self.paned.grid(row=0, column=0, sticky="nsew")

        # -- Left pane: canvas with scrollbars -------------------------------
        left_frame = tk.Frame(self.paned)

        left_frame.rowconfigure(0, weight=1)
        left_frame.rowconfigure(1, weight=0)
        left_frame.columnconfigure(0, weight=1)
        left_frame.columnconfigure(1, weight=0)

        self.canvas = tk.Canvas(left_frame, bg="white", highlightthickness=0)
        self.canvas.grid(row=0, column=0, sticky="nsew")

        v_scroll = tk.Scrollbar(
            left_frame, orient=tk.VERTICAL, command=self.canvas.yview
        )
        v_scroll.grid(row=0, column=1, sticky="ns")

        h_scroll = tk.Scrollbar(
            left_frame, orient=tk.HORIZONTAL, command=self.canvas.xview
        )
        h_scroll.grid(row=1, column=0, sticky="ew")

        self.canvas.configure(
            yscrollcommand=v_scroll.set,
            xscrollcommand=h_scroll.set,
        )

        # -- Right pane: edit panel placeholder --------------------------------
        self.edit_panel = tk.Frame(self.paned, bg="#cccccc", width=192)
        self.edit_panel.pack_propagate(False)

        # Add both panes; set the initial split at ~85 % of 1280 = 1088
        self.paned.add(left_frame, stretch="always", minsize=200)
        self.paned.add(self.edit_panel, stretch="never", minsize=100)

        # Position the sash after the window is rendered
        self.root.update_idletasks()
        self.paned.sash_place(0, 1088, 0)

        # -- Bottom bar -------------------------------------------------------
        bottom_bar = tk.Frame(self.root, bd=1, relief=tk.GROOVE, pady=4)
        bottom_bar.grid(row=1, column=0, sticky="ew", padx=0, pady=0)

        btn_add = tk.Button(
            bottom_bar,
            text="+ Add Quest",
            command=self._add_quest,
        )
        btn_add.pack(side=tk.LEFT, padx=(8, 4))

        btn_save = tk.Button(
            bottom_bar,
            text="Save to Lua",
            command=self._save_to_lua,
        )
        btn_save.pack(side=tk.LEFT, padx=(0, 8))

        self.status_var = tk.StringVar(value="")
        status_label = tk.Label(
            bottom_bar,
            textvariable=self.status_var,
            anchor="e",
        )
        status_label.pack(side=tk.RIGHT, padx=8)

        # Initial draw
        self.draw_canvas()

    def _add_quest(self):
        """Open a dialog to create a new quest chapter and append it to self.scripts."""
        dialog = tk.Toplevel(self.root)
        dialog.title("Add Quest Chapter")
        dialog.resizable(False, False)
        dialog.grab_set()

        # Collect existing unique ids
        existing_ids = list(dict.fromkeys(e.get("id", "") for e in self.scripts))

        tk.Label(dialog, text="Character id").grid(row=0, column=0, sticky="w", padx=8, pady=(10, 2))
        id_var = tk.StringVar()
        id_combo = ttk.Combobox(dialog, textvariable=id_var, values=existing_ids)
        id_combo.grid(row=0, column=1, padx=8, pady=(10, 2))

        tk.Label(dialog, text="Chapter").grid(row=1, column=0, sticky="w", padx=8, pady=2)
        chapter_var = tk.IntVar(value=1)
        chapter_spin = tk.Spinbox(dialog, from_=1, to=999, width=6, textvariable=chapter_var)
        chapter_spin.grid(row=1, column=1, sticky="w", padx=8, pady=2)

        def _update_chapter(*_):
            """Set chapter to the next number after the highest existing chapter for this id."""
            chosen_id = id_var.get().strip()
            existing_chapters = [
                e.get("chapter", 0) for e in self.scripts
                if e.get("id") == chosen_id
            ]
            next_ch = max(existing_chapters) + 1 if existing_chapters else 1
            chapter_var.set(next_ch)

        id_combo.bind("<<ComboboxSelected>>", _update_chapter)
        id_var.trace_add("write", _update_chapter)

        result = {"ok": False}

        def _on_ok():
            result["ok"] = True
            dialog.destroy()

        def _on_cancel():
            dialog.destroy()

        btn_frame = tk.Frame(dialog)
        btn_frame.grid(row=2, column=0, columnspan=2, pady=(8, 10))
        tk.Button(btn_frame, text="OK", width=8, command=_on_ok).pack(side=tk.LEFT, padx=4)
        tk.Button(btn_frame, text="Cancel", width=8, command=_on_cancel).pack(side=tk.LEFT, padx=4)

        # Center dialog on parent
        dialog.update_idletasks()
        px = self.root.winfo_x() + (self.root.winfo_width() - dialog.winfo_width()) // 2
        py = self.root.winfo_y() + (self.root.winfo_height() - dialog.winfo_height()) // 2
        dialog.geometry(f"+{px}+{py}")

        self.root.wait_window(dialog)

        if not result["ok"]:
            return

        id_val = id_var.get().strip()
        if not id_val:
            return
        try:
            chapter_val = int(chapter_var.get())
        except (ValueError, tk.TclError):
            chapter_val = 1

        new_entry = {
            "id": id_val,
            "chapter": chapter_val,
            "name": id_val,
            "trigger": {"plant_type": 1, "count": 0},
            "plant_type": 1,
            "messages": [],
            "after_messages": [],
            "primary_color": [1.0, 1.0, 1.0, 1.0],
            "secondary_color": [0.5, 0.5, 0.5, 1.0],
            "voice_pitch": 1.0,
            "accessory": None,
            "no_dismiss": False,
        }
        self.scripts.append(new_entry)
        self.draw_canvas()
        self._populate_edit_panel(new_entry)

        # Scroll canvas to show the new card
        key = (id_val, chapter_val)
        coords = self.card_coords.get(key)
        if coords:
            x1, _y1, x2, _y2 = coords
            scroll_region = self.canvas.bbox("all")
            if scroll_region:
                total_w = scroll_region[2] - scroll_region[0]
                if total_w > 0:
                    frac = (x1 - scroll_region[0]) / total_w
                    self.canvas.xview_moveto(max(0.0, frac))
        else:
            self.canvas.xview_moveto(0)

    def _save_to_lua(self):
        """Serialize self.scripts to Lua and write it to disk."""
        write_scripts(self.scripts, self.script_path)
        self.status_var.set("Saved.")
        self.root.after(3000, lambda: self.status_var.set(""))

    # ---------------------------------------------------------------------- #
    # Drawing                                                                  #
    # ---------------------------------------------------------------------- #

    # Plant name lookup (type id → display name)
    PLANT_NAMES = {
        1: "Grass",
        2: "Cactus",
        3: "Rose",
        4: "Tulip",
        5: "Daisy",
        6: "Golden Lotus",
    }

    # Card background color per plant type (used for trigger plant_type)
    PLANT_COLORS = {
        1: "#a8d5a2",
        2: "#d4b483",
        3: "#e8a0b0",
        4: "#b0c8e8",
        5: "#f0e080",
        6: "#f0c040",
    }

    # ------------------------------------------------------------------ #
    # Whiteboard canvas                                                    #
    # ------------------------------------------------------------------ #

    CARD_W  = 200   # card width
    CARD_H  = 90    # card height
    H_GAP   = 60    # default horizontal gap between cards
    V_GAP   = 50    # default vertical gap between rows
    TOP_PAD = 40    # default top margin
    LFT_PAD = 40    # default left margin

    @staticmethod
    def _darken(hex_color: str, factor: float = 0.68) -> str:
        """Return *hex_color* (#rrggbb) darkened by *factor*."""
        h = hex_color.lstrip("#")
        r = max(0, int(int(h[0:2], 16) * factor))
        g = max(0, int(int(h[2:4], 16) * factor))
        b = max(0, int(int(h[4:6], 16) * factor))
        return f"#{r:02x}{g:02x}{b:02x}"

    def draw_canvas(self) -> None:
        """Full redraw.  Preserves any card positions the user has dragged."""
        self.canvas.delete("all")
        self.item_to_card = {}
        self.card_tags    = {}
        self.card_coords  = {}

        # ── group & sort ───────────────────────────────────────────────────────
        groups: dict[str, list[dict]] = {}
        for ch in self.scripts:
            groups.setdefault(ch["id"], []).append(ch)
        for gid in groups:
            groups[gid].sort(key=lambda c: c["chapter"])

        ordered_ids = sorted(
            groups.keys(),
            key=lambda gid: (min(c["trigger"]["count"] for c in groups[gid]), gid),
        )

        # ── default positions for cards not yet placed ─────────────────────────
        for row_i, gid in enumerate(ordered_ids):
            for col_j, ch in enumerate(groups[gid]):
                k = (gid, ch["chapter"])
                if k not in self.card_positions:
                    self.card_positions[k] = (
                        self.LFT_PAD + col_j * (self.CARD_W + self.H_GAP),
                        self.TOP_PAD + row_i * (self.CARD_H + self.V_GAP),
                    )

        # ── first-appearance badges ────────────────────────────────────────────
        first_badge: dict[int, tuple] = {}
        for pt in range(1, 7):
            candidates = [
                ch for ch in self.scripts
                if ch.get("trigger", {}).get("plant_type") == pt
                or ch.get("plant_type") == pt
            ]
            if candidates:
                candidates.sort(key=lambda c: (
                    c.get("trigger", {}).get("count", float("inf")),
                    c.get("id", ""),
                    c.get("chapter", 0),
                ))
                best = candidates[0]
                first_badge[pt] = (best["id"], best["chapter"])

        badges_for: dict[tuple, list[int]] = {}
        for pt, key in first_badge.items():
            badges_for.setdefault(key, []).append(pt)

        # ── arrows behind cards ────────────────────────────────────────────────
        self._draw_arrows_items(groups)

        # ── cards ──────────────────────────────────────────────────────────────
        for gid in ordered_ids:
            for ch in groups[gid]:
                self._draw_card(ch, badges_for.get((gid, ch["chapter"]), []))

        # ── scroll region ──────────────────────────────────────────────────────
        bbox = self.canvas.bbox("all")
        if bbox:
            pad = 40
            self.canvas.configure(scrollregion=(
                bbox[0] - pad, bbox[1] - pad,
                bbox[2] + pad, bbox[3] + pad,
            ))

        # ── event bindings ─────────────────────────────────────────────────────
        self.canvas.bind("<ButtonPress-1>",   self._on_canvas_press)
        self.canvas.bind("<B1-Motion>",        self._on_canvas_motion)
        self.canvas.bind("<ButtonRelease-1>", self._on_canvas_release)

    def _draw_card(self, chapter: dict, badges: list) -> None:
        """Draw one card and register all its canvas items."""
        gid    = chapter["id"]
        ch_num = chapter["chapter"]
        key    = (gid, ch_num)
        x, y   = self.card_positions[key]

        safe = re.sub(r"\W", "_", gid)
        tag  = f"ci_{safe}_{ch_num}"
        self.card_tags[key] = tag

        trig      = chapter.get("trigger", {})
        trig_type = trig.get("plant_type", 1)
        trig_cnt  = trig.get("count", 0)
        color     = self.PLANT_COLORS.get(trig_type, "#cccccc")
        dark      = self._darken(color)
        HDR       = 26

        def reg(item):
            self.item_to_card[item] = key

        # drop shadow
        reg(self.canvas.create_rectangle(
            x + 4, y + 4, x + self.CARD_W + 4, y + self.CARD_H + 4,
            fill="#bbbbbb", outline="", tags=(tag,),
        ))
        # card body
        reg(self.canvas.create_rectangle(
            x, y, x + self.CARD_W, y + self.CARD_H,
            fill=color, outline="#555555", width=1, tags=(tag,),
        ))
        # header band
        reg(self.canvas.create_rectangle(
            x, y, x + self.CARD_W, y + HDR,
            fill=dark, outline="", tags=(tag,),
        ))
        # header label
        ch_name = chapter.get("name", gid)
        reg(self.canvas.create_text(
            x + self.CARD_W // 2, y + HDR // 2,
            text=f"{ch_name} — Ch {ch_num}",
            anchor="center",
            font=("TkDefaultFont", 9, "bold"),
            fill="white",
            tags=(tag,),
        ))
        # body lines
        trig_plant = self.PLANT_NAMES.get(trig_type, "?")
        req_plant  = self.PLANT_NAMES.get(chapter.get("plant_type", 1), "?")
        ty = y + HDR + 7
        for line in (f"needs {trig_plant} ×{trig_cnt}", f"requests {req_plant}"):
            reg(self.canvas.create_text(
                x + 8, ty, text=line, anchor="nw",
                font=("TkDefaultFont", 9), tags=(tag,),
            ))
            ty += 17

        # first-appearance badges
        BADGE_C = "#b8860b"
        bx = x + self.CARD_W - 6
        by = y + HDR + 5
        for pt in sorted(badges):
            reg(self.canvas.create_text(
                bx, by, text="★", anchor="ne",
                fill=BADGE_C, font=("TkDefaultFont", 9, "bold"), tags=(tag,),
            ))
            reg(self.canvas.create_text(
                bx, by + 12, text=self.PLANT_NAMES.get(pt, str(pt)),
                anchor="ne", fill=BADGE_C,
                font=("TkDefaultFont", 7), tags=(tag,),
            ))
            by += 26

        self.card_coords[key] = (x, y, x + self.CARD_W, y + self.CARD_H)

    def _draw_arrows_items(self, groups: dict) -> None:
        """Draw S-curve arrows between sequential chapters of each character."""
        for gid, chapters in groups.items():
            for i in range(len(chapters) - 1):
                k1 = (gid, chapters[i]["chapter"])
                k2 = (gid, chapters[i + 1]["chapter"])
                if k1 not in self.card_positions or k2 not in self.card_positions:
                    continue
                x1, y1 = self.card_positions[k1]
                x2, y2 = self.card_positions[k2]
                ax1 = x1 + self.CARD_W
                ay1 = y1 + self.CARD_H // 2
                ax2 = x2
                ay2 = y2 + self.CARD_H // 2
                mx  = (ax1 + ax2) / 2
                self.canvas.create_line(
                    ax1, ay1, mx, ay1, mx, ay2, ax2, ay2,
                    arrow="last", smooth=True,
                    fill="#777777", width=1.5,
                    tags=("arrow",),
                )

    def _redraw_arrows_only(self) -> None:
        """Delete and redraw only arrows (called during card drag)."""
        self.canvas.delete("arrow")
        groups: dict[str, list[dict]] = {}
        for ch in self.scripts:
            groups.setdefault(ch["id"], []).append(ch)
        for gid in groups:
            groups[gid].sort(key=lambda c: c["chapter"])
        self._draw_arrows_items(groups)
        self.canvas.tag_lower("arrow")

    def _on_canvas_press(self, event: tk.Event) -> None:
        """Start a card drag or canvas pan."""
        cx = self.canvas.canvasx(event.x)
        cy = self.canvas.canvasy(event.y)

        items   = self.canvas.find_overlapping(cx - 2, cy - 2, cx + 2, cy + 2)
        hit_key = None
        for item in reversed(items):    # reversed = topmost first
            if item in self.item_to_card:
                hit_key = self.item_to_card[item]
                break

        if hit_key:
            self._drag_state = {
                "key": hit_key, "last_cx": cx, "last_cy": cy, "moved": False,
            }
            tag = self.card_tags.get(hit_key)
            if tag:
                self.canvas.tag_raise(tag)
        else:
            self._pan_mode = True
            self.canvas.scan_mark(event.x, event.y)

    def _on_canvas_motion(self, event: tk.Event) -> None:
        """Move a dragged card or pan the canvas."""
        cx = self.canvas.canvasx(event.x)
        cy = self.canvas.canvasy(event.y)

        if self._drag_state:
            dx  = cx - self._drag_state["last_cx"]
            dy  = cy - self._drag_state["last_cy"]
            key = self._drag_state["key"]
            tag = self.card_tags.get(key)

            if tag:
                self.canvas.move(tag, dx, dy)

            ox, oy = self.card_positions[key]
            self.card_positions[key] = (ox + dx, oy + dy)
            self.card_coords[key]    = (
                ox + dx, oy + dy,
                ox + dx + self.CARD_W, oy + dy + self.CARD_H,
            )
            self._drag_state["last_cx"] = cx
            self._drag_state["last_cy"] = cy
            if abs(dx) > 1 or abs(dy) > 1:
                self._drag_state["moved"] = True

            self._redraw_arrows_only()
            bbox = self.canvas.bbox("all")
            if bbox:
                self.canvas.configure(scrollregion=bbox)

        elif self._pan_mode:
            self.canvas.scan_dragto(event.x, event.y, gain=1)

    def _on_canvas_release(self, event: tk.Event) -> None:
        """End drag: a non-moving press opens the edit panel."""
        if self._drag_state and not self._drag_state["moved"]:
            key   = self._drag_state["key"]
            entry = next(
                (s for s in self.scripts if (s["id"], s["chapter"]) == key),
                None,
            )
            if entry:
                self._populate_edit_panel(entry)
        self._drag_state = None
        self._pan_mode   = False

    # ---------------------------------------------------------------------- #
    # Edit panel                                                               #
    # ---------------------------------------------------------------------- #

    @staticmethod
    def _color_to_hex(rgba):
        """Convert a [r, g, b, a] float list to a #rrggbb hex string."""
        r = max(0, min(255, int(round(rgba[0] * 255))))
        g = max(0, min(255, int(round(rgba[1] * 255))))
        b = max(0, min(255, int(round(rgba[2] * 255))))
        return f"#{r:02x}{g:02x}{b:02x}"

    @staticmethod
    def _hex_to_color(hex_str, alpha=1.0):
        """Convert a #rrggbb string back to a [r, g, b, a] float list."""
        hex_str = hex_str.lstrip('#')
        r = int(hex_str[0:2], 16) / 255.0
        g = int(hex_str[2:4], 16) / 255.0
        b = int(hex_str[4:6], 16) / 255.0
        return [r, g, b, alpha]

    def _delete_chapter(self):
        if self._editing_key is None:
            return
        if not messagebox.askyesno("Delete", "Delete this chapter?"):
            return
        edit_id, edit_chapter = self._editing_key
        self.scripts = [
            e for e in self.scripts
            if not (e.get("id") == edit_id and e.get("chapter") == edit_chapter)
        ]
        self.card_positions.pop((edit_id, edit_chapter), None)
        for child in self.edit_panel.winfo_children():
            child.destroy()
        self._editing_key = None
        self.draw_canvas()

    def _populate_edit_panel(self, script_entry):
        """Clear and rebuild the right edit_panel for the given script entry."""
        # Store editing key so _apply_edits can find the entry
        self._editing_key = (script_entry.get("id"), script_entry.get("chapter"))
        self._editing_widgets = {}

        # Clear existing widgets
        for child in self.edit_panel.winfo_children():
            child.destroy()

        # ── Section title ────────────────────────────────────────────────────
        title_text = f"{script_entry.get('name', '')} — Ch {script_entry.get('chapter', '')}"
        tk.Label(
            self.edit_panel,
            text=title_text,
            font=("TkDefaultFont", 10, "bold"),
            bg="#cccccc",
            anchor="w",
            wraplength=180,
        ).pack(fill=tk.X, padx=6, pady=(6, 2))

        # ── Delete button ─────────────────────────────────────────────────────
        tk.Button(
            self.edit_panel,
            text="Delete Chapter",
            fg="red",
            command=self._delete_chapter,
        ).pack(anchor="w", padx=6, pady=(0, 6))

        # ── Scrollable inner area ─────────────────────────────────────────────
        scroll_canvas = tk.Canvas(self.edit_panel, bg="#cccccc", highlightthickness=0)
        scrollbar = tk.Scrollbar(self.edit_panel, orient=tk.VERTICAL, command=scroll_canvas.yview)
        scroll_canvas.configure(yscrollcommand=scrollbar.set)

        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        scroll_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        inner = tk.Frame(scroll_canvas, bg="#cccccc")
        inner_window = scroll_canvas.create_window((0, 0), window=inner, anchor="nw")

        def _on_inner_configure(event):
            scroll_canvas.configure(scrollregion=scroll_canvas.bbox("all"))

        def _on_canvas_configure(event):
            scroll_canvas.itemconfig(inner_window, width=event.width)

        inner.bind("<Configure>", _on_inner_configure)
        scroll_canvas.bind("<Configure>", _on_canvas_configure)

        # ── Helper to bind apply on focus-out and Return ──────────────────────
        def _bind_apply(widget):
            widget.bind("<FocusOut>", lambda e: self._apply_edits())
            widget.bind("<Return>", lambda e: self._apply_edits())

        row = 0

        def lbl(text):
            nonlocal row
            tk.Label(inner, text=text, bg="#cccccc", anchor="w").grid(
                row=row, column=0, sticky="w", padx=(6, 2), pady=2
            )

        def next_row():
            nonlocal row
            row += 1

        # ── id ────────────────────────────────────────────────────────────────
        lbl("id")
        id_var = tk.StringVar(value=str(script_entry.get("id", "")))
        id_entry = tk.Entry(inner, textvariable=id_var)
        id_entry.grid(row=row, column=1, sticky="ew", padx=(0, 6), pady=2)
        _bind_apply(id_entry)
        self._editing_widgets["id"] = id_var
        next_row()

        # ── chapter ───────────────────────────────────────────────────────────
        lbl("chapter")
        chapter_var = tk.IntVar(value=int(script_entry.get("chapter", 1)))
        chapter_spin = tk.Spinbox(inner, from_=1, to=99, width=4, textvariable=chapter_var)
        chapter_spin.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        _bind_apply(chapter_spin)
        self._editing_widgets["chapter"] = chapter_var
        next_row()

        # ── name ──────────────────────────────────────────────────────────────
        lbl("name")
        name_var = tk.StringVar(value=str(script_entry.get("name", "")))
        name_entry = tk.Entry(inner, textvariable=name_var)
        name_entry.grid(row=row, column=1, sticky="ew", padx=(0, 6), pady=2)
        _bind_apply(name_entry)
        self._editing_widgets["name"] = name_var
        next_row()

        # ── trigger plant_type ────────────────────────────────────────────────
        lbl("trigger plant_type")
        trig = script_entry.get("trigger", {})
        trig_plant_var = tk.IntVar(value=int(trig.get("plant_type", 1)))
        trig_plant_spin = tk.Spinbox(inner, from_=1, to=6, width=4, textvariable=trig_plant_var)
        trig_plant_spin.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        _bind_apply(trig_plant_spin)
        self._editing_widgets["trigger_plant_type"] = trig_plant_var
        next_row()

        # ── trigger count ─────────────────────────────────────────────────────
        lbl("trigger count")
        trig_count_var = tk.IntVar(value=int(trig.get("count", 0)))
        trig_count_spin = tk.Spinbox(inner, from_=0, to=999, width=5, textvariable=trig_count_var)
        trig_count_spin.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        _bind_apply(trig_count_spin)
        self._editing_widgets["trigger_count"] = trig_count_var
        next_row()

        # ── plant requested ───────────────────────────────────────────────────
        lbl("plant requested")
        plant_req_var = tk.IntVar(value=int(script_entry.get("plant_type", 1)))
        plant_req_spin = tk.Spinbox(inner, from_=1, to=6, width=4, textvariable=plant_req_var)
        plant_req_spin.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        _bind_apply(plant_req_spin)
        self._editing_widgets["plant_type"] = plant_req_var
        next_row()

        # ── voice_pitch ───────────────────────────────────────────────────────
        lbl("voice_pitch")
        voice_var = tk.StringVar(value=str(script_entry.get("voice_pitch", "")))
        voice_entry = tk.Entry(inner, textvariable=voice_var, width=6)
        voice_entry.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        _bind_apply(voice_entry)
        self._editing_widgets["voice_pitch"] = voice_var
        next_row()

        # ── accessory ─────────────────────────────────────────────────────────
        lbl("accessory")
        accessory_val = script_entry.get("accessory") or ""
        accessory_var = tk.StringVar(value=str(accessory_val))
        accessory_entry = tk.Entry(inner, textvariable=accessory_var)
        accessory_entry.grid(row=row, column=1, sticky="ew", padx=(0, 6), pady=2)
        _bind_apply(accessory_entry)
        self._editing_widgets["accessory"] = accessory_var
        next_row()

        # ── no_dismiss ────────────────────────────────────────────────────────
        lbl("no_dismiss")
        no_dismiss_var = tk.BooleanVar(value=bool(script_entry.get("no_dismiss", False)))
        no_dismiss_cb = tk.Checkbutton(
            inner, variable=no_dismiss_var, bg="#cccccc",
            command=self._apply_edits,
        )
        no_dismiss_cb.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        self._editing_widgets["no_dismiss"] = no_dismiss_var
        next_row()

        # ── primary_color ─────────────────────────────────────────────────────
        lbl("primary_color")
        primary_rgba = list(script_entry.get("primary_color", [1.0, 1.0, 1.0, 1.0]))
        primary_hex = self._color_to_hex(primary_rgba)

        def _pick_primary():
            result = colorchooser.askcolor(color=primary_hex, title="Pick primary color")
            if result and result[1]:
                new_hex = result[1]
                alpha = primary_rgba[3] if len(primary_rgba) > 3 else 1.0
                primary_rgba[:] = self._hex_to_color(new_hex, alpha)
                primary_btn.configure(bg=new_hex)
                self._apply_edits()

        primary_btn = tk.Button(
            inner, bg=primary_hex, width=4,
            relief=tk.RAISED, command=_pick_primary,
        )
        primary_btn.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        # Store the mutable rgba list and the hex string via the button reference
        self._editing_widgets["primary_color"] = primary_rgba
        next_row()

        # ── secondary_color ───────────────────────────────────────────────────
        lbl("secondary_color")
        secondary_rgba = list(script_entry.get("secondary_color", [1.0, 1.0, 1.0, 1.0]))
        secondary_hex = self._color_to_hex(secondary_rgba)

        def _pick_secondary():
            result = colorchooser.askcolor(color=secondary_hex, title="Pick secondary color")
            if result and result[1]:
                new_hex = result[1]
                alpha = secondary_rgba[3] if len(secondary_rgba) > 3 else 1.0
                secondary_rgba[:] = self._hex_to_color(new_hex, alpha)
                secondary_btn.configure(bg=new_hex)
                self._apply_edits()

        secondary_btn = tk.Button(
            inner, bg=secondary_hex, width=4,
            relief=tk.RAISED, command=_pick_secondary,
        )
        secondary_btn.grid(row=row, column=1, sticky="w", padx=(0, 6), pady=2)
        self._editing_widgets["secondary_color"] = secondary_rgba
        next_row()

        # Allow column 1 to expand
        inner.columnconfigure(1, weight=1)

        # ── messages section ──────────────────────────────────────────────────
        tk.Label(inner, text="messages", bg="#cccccc", font=("TkDefaultFont", 9, "bold"), anchor="w").grid(
            row=row, column=0, columnspan=2, sticky="w", padx=6, pady=(8, 2)
        )
        next_row()

        msg_listbox = tk.Listbox(inner, height=4, selectmode=tk.SINGLE)
        msg_listbox.grid(row=row, column=0, columnspan=2, sticky="ew", padx=6, pady=2)
        for line in script_entry.get("messages", []):
            msg_listbox.insert(tk.END, line)
        next_row()

        msg_entry_var = tk.StringVar()
        msg_entry = tk.Entry(inner, textvariable=msg_entry_var)
        msg_entry.grid(row=row, column=0, sticky="ew", padx=(6, 2), pady=2)

        def _add_message():
            text = msg_entry_var.get().strip()
            if text:
                msg_listbox.insert(tk.END, text)
                msg_entry_var.set("")
                self._apply_edits()

        def _remove_message():
            sel = msg_listbox.curselection()
            if sel:
                msg_listbox.delete(sel[0])
                self._apply_edits()

        tk.Button(inner, text="Add", command=_add_message).grid(
            row=row, column=1, sticky="w", padx=(0, 6), pady=2
        )
        next_row()

        tk.Button(inner, text="Remove", command=_remove_message).grid(
            row=row, column=0, columnspan=2, sticky="w", padx=6, pady=(0, 4)
        )
        self._editing_widgets["messages"] = msg_listbox
        next_row()

        # ── after_messages section ────────────────────────────────────────────
        tk.Label(inner, text="after_messages", bg="#cccccc", font=("TkDefaultFont", 9, "bold"), anchor="w").grid(
            row=row, column=0, columnspan=2, sticky="w", padx=6, pady=(8, 2)
        )
        next_row()

        amsg_listbox = tk.Listbox(inner, height=4, selectmode=tk.SINGLE)
        amsg_listbox.grid(row=row, column=0, columnspan=2, sticky="ew", padx=6, pady=2)
        for line in script_entry.get("after_messages", []):
            amsg_listbox.insert(tk.END, line)
        next_row()

        amsg_entry_var = tk.StringVar()
        amsg_entry = tk.Entry(inner, textvariable=amsg_entry_var)
        amsg_entry.grid(row=row, column=0, sticky="ew", padx=(6, 2), pady=2)

        def _add_after_message():
            text = amsg_entry_var.get().strip()
            if text:
                amsg_listbox.insert(tk.END, text)
                amsg_entry_var.set("")
                self._apply_edits()

        def _remove_after_message():
            sel = amsg_listbox.curselection()
            if sel:
                amsg_listbox.delete(sel[0])
                self._apply_edits()

        tk.Button(inner, text="Add", command=_add_after_message).grid(
            row=row, column=1, sticky="w", padx=(0, 6), pady=2
        )
        next_row()

        tk.Button(inner, text="Remove", command=_remove_after_message).grid(
            row=row, column=0, columnspan=2, sticky="w", padx=6, pady=(0, 4)
        )
        self._editing_widgets["after_messages"] = amsg_listbox
        next_row()

    def _apply_edits(self):
        """Read all widget values and write them back to the matching entry in self.scripts."""
        if not hasattr(self, "_editing_key") or self._editing_key is None:
            return
        edit_id, edit_chapter = self._editing_key

        # Find the entry
        target = None
        for entry in self.scripts:
            if entry.get("id") == edit_id and entry.get("chapter") == edit_chapter:
                target = entry
                break
        if target is None:
            return

        w = self._editing_widgets

        # Simple string/int fields
        if "id" in w:
            target["id"] = w["id"].get()
        if "chapter" in w:
            try:
                target["chapter"] = int(w["chapter"].get())
            except (ValueError, tk.TclError):
                pass
        if "name" in w:
            target["name"] = w["name"].get()
        if "plant_type" in w:
            try:
                target["plant_type"] = int(w["plant_type"].get())
            except (ValueError, tk.TclError):
                pass
        if "voice_pitch" in w:
            raw = w["voice_pitch"].get().strip()
            if raw:
                try:
                    target["voice_pitch"] = float(raw)
                except ValueError:
                    target["voice_pitch"] = raw
            else:
                target.pop("voice_pitch", None)
        if "accessory" in w:
            val = w["accessory"].get()
            target["accessory"] = val if val else None
        if "no_dismiss" in w:
            target["no_dismiss"] = w["no_dismiss"].get()

        # Trigger sub-fields
        trigger = target.setdefault("trigger", {})
        if "trigger_plant_type" in w:
            try:
                trigger["plant_type"] = int(w["trigger_plant_type"].get())
            except (ValueError, tk.TclError):
                pass
        if "trigger_count" in w:
            try:
                trigger["count"] = int(w["trigger_count"].get())
            except (ValueError, tk.TclError):
                pass

        # Colors (stored as mutable lists updated in-place by the pickers)
        if "primary_color" in w:
            target["primary_color"] = list(w["primary_color"])
        if "secondary_color" in w:
            target["secondary_color"] = list(w["secondary_color"])

        # Messages lists
        if "messages" in w:
            target["messages"] = list(w["messages"].get(0, tk.END))
        if "after_messages" in w:
            target["after_messages"] = list(w["after_messages"].get(0, tk.END))

        # Update editing key in case id/chapter changed
        self._editing_key = (target.get("id"), target.get("chapter"))

        self.draw_canvas()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    root = tk.Tk()
    app = QuestEditorApp(root)
    root.mainloop()
