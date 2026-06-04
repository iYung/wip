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
        self._editing_key = None

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

    def draw_canvas(self) -> None:
        """Render the swimlane quest visualization onto the canvas."""
        self.canvas.delete("all")

        # ------------------------------------------------------------------ #
        # Layout constants                                                     #
        # ------------------------------------------------------------------ #
        LEFT_MARGIN = 160
        CARD_W      = 180
        CARD_H      = 80
        H_GAP       = 40   # horizontal gap between cards in a row
        V_GAP       = 30   # vertical gap between rows
        TOP_MARGIN  = 20

        # ------------------------------------------------------------------ #
        # Group chapters by id, order groups by min trigger["count"] asc      #
        # (ties broken alphabetically), then chapters within each group asc   #
        # ------------------------------------------------------------------ #
        groups: dict[str, list[dict]] = {}
        for ch in self.scripts:
            gid = ch["id"]
            groups.setdefault(gid, []).append(ch)

        # Sort chapters within each group by chapter number
        for gid in groups:
            groups[gid].sort(key=lambda c: c["chapter"])

        # Sort groups: primary = min trigger count, secondary = id string
        def group_sort_key(gid):
            min_count = min(c["trigger"]["count"] for c in groups[gid])
            return (min_count, gid)

        ordered_ids = sorted(groups.keys(), key=group_sort_key)

        # ------------------------------------------------------------------ #
        # Draw rows                                                            #
        # ------------------------------------------------------------------ #
        self.card_coords: dict[tuple, tuple] = {}

        # Bind click handler once
        self.canvas.bind("<Button-1>", self._on_canvas_click)
        self.selected_card = None

        for row_i, gid in enumerate(ordered_ids):
            chapters = groups[gid]
            y1 = TOP_MARGIN + row_i * (CARD_H + V_GAP)
            y2 = y1 + CARD_H
            cy = (y1 + y2) // 2  # vertical midpoint for label

            # Row label (character id, right-aligned to x=155)
            self.canvas.create_text(
                155, cy,
                text=gid,
                anchor="e",
                font=("TkDefaultFont", 10),
            )

            for col_j, chapter in enumerate(chapters):
                x1 = LEFT_MARGIN + col_j * (CARD_W + H_GAP)
                x2 = x1 + CARD_W

                # Card background color based on trigger plant_type
                trigger_type = chapter.get("trigger", {}).get("plant_type", 1)
                bg_color = self.PLANT_COLORS.get(trigger_type, "#cccccc")

                # Draw card rectangle
                self.canvas.create_rectangle(
                    x1, y1, x2, y2,
                    fill=bg_color,
                    outline="#555555",
                    width=1,
                )

                # Text content
                ch_name    = chapter.get("name", gid)
                ch_num     = chapter.get("chapter", col_j + 1)
                trig_count = chapter.get("trigger", {}).get("count", "?")
                trig_plant = self.PLANT_NAMES.get(trigger_type, str(trigger_type))
                req_plant  = self.PLANT_NAMES.get(
                    chapter.get("plant_type", 1), "?"
                )

                tx = x1 + 8
                ty = y1 + 8
                line_h = 18

                # Line 1: name — Ch N  (bold)
                self.canvas.create_text(
                    tx, ty,
                    text=f"{ch_name} — Ch {ch_num}",
                    anchor="nw",
                    font=("TkDefaultFont", 9, "bold"),
                )
                # Line 2: needs PlantName ×count
                self.canvas.create_text(
                    tx, ty + line_h,
                    text=f"needs {trig_plant} ×{trig_count}",
                    anchor="nw",
                    font=("TkDefaultFont", 9),
                )
                # Line 3: requests PlantName
                self.canvas.create_text(
                    tx, ty + line_h * 2,
                    text=f"requests {req_plant}",
                    anchor="nw",
                    font=("TkDefaultFont", 9),
                )

                # Store bounding box
                self.card_coords[(gid, ch_num)] = (x1, y1, x2, y2)

                # Draw arrow from previous card to this one
                if col_j > 0:
                    prev_x2 = LEFT_MARGIN + (col_j - 1) * (CARD_W + H_GAP) + CARD_W
                    arrow_y  = cy
                    self.canvas.create_line(
                        prev_x2, arrow_y,
                        x1, arrow_y,
                        arrow="last",
                        fill="#555555",
                        width=1,
                    )

        # ------------------------------------------------------------------ #
        # First-appearance plant badges                                       #
        # ------------------------------------------------------------------ #
        # For each plant type 1-6, find the chapter that is the first
        # appearance (lowest trigger count; tie-break: id alpha, chapter asc).
        # That card gets a gold star + plant-name badge in its top-right corner.

        BADGE_COLOR = "#b8860b"  # dark-gold

        for pt in range(1, 7):
            # Collect all chapters that involve this plant type
            candidates = [
                ch for ch in self.scripts
                if ch.get("trigger", {}).get("plant_type") == pt
                or ch.get("plant_type") == pt
            ]
            if not candidates:
                continue

            # Sort: primary = trigger count asc, secondary = id alpha, tertiary = chapter asc
            candidates.sort(key=lambda c: (
                c.get("trigger", {}).get("count", float("inf")),
                c.get("id", ""),
                c.get("chapter", 0),
            ))
            first = candidates[0]
            key = (first.get("id", ""), first.get("chapter", 0))

            coords = self.card_coords.get(key)
            if coords is None:
                continue

            x1, y1, x2, y2 = coords
            star_x = x2 - 12
            star_y = y1 + 8
            name_x = x2 - 4
            name_y = star_y + 12

            # Gold star
            self.canvas.create_text(
                star_x, star_y,
                text="★",
                anchor="center",
                fill=BADGE_COLOR,
                font=("TkDefaultFont", 9, "bold"),
                tags="badge",
            )
            # Plant name in tiny font, right-aligned
            plant_label = self.PLANT_NAMES.get(pt, str(pt))
            self.canvas.create_text(
                name_x, name_y,
                text=plant_label,
                anchor="ne",
                fill=BADGE_COLOR,
                font=("TkDefaultFont", 8),
                tags="badge",
            )

        # Expand scroll region to fit all drawn content
        self.canvas.configure(scrollregion=self.canvas.bbox("all"))

    def _on_canvas_click(self, event) -> None:
        """Handle a click on the canvas: select the card under the cursor."""
        cx = self.canvas.canvasx(event.x)
        cy = self.canvas.canvasy(event.y)

        for (gid, chapter), (x1, y1, x2, y2) in self.card_coords.items():
            if x1 <= cx <= x2 and y1 <= cy <= y2:
                self.selected_card = (gid, chapter)
                # Find the matching script entry and populate the panel
                for entry in self.scripts:
                    if entry.get("id") == gid and entry.get("chapter") == chapter:
                        self._populate_edit_panel(entry)
                        return
                return

        self.selected_card = None

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
