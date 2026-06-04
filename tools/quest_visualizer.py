#!/usr/bin/env python3
"""Quest grid: plant tiers as columns, characters as rows, chapter arrows per row."""

import re, os, sys
import tkinter as tk

SCRIPT_PATH = os.path.join(os.path.dirname(__file__), "..", "lua", "game", "data", "customer_scripts.lua")

PLANTS     = [(1,"Grass"),(2,"Cactus"),(3,"Rose"),(4,"Tulip"),(5,"Daisy"),(6,"Golden Lotus")]
PLANT_NAME = {pt: n for pt, n in PLANTS}
PLANT_IDX  = {pt: i for i, (pt, _) in enumerate(PLANTS)}

NODE_FILL = {
    1: "#b2dfdb",  # Grass
    2: "#c5e1a5",  # Cactus
    3: "#f48fb1",  # Rose
    4: "#ce93d8",  # Tulip
    5: "#fff176",  # Daisy
    6: "#ffd54f",  # Golden Lotus
}
PULL_OUTLINE = "#e64a19"
BG = "#f9f9f6"

LEFT  = 160   # px reserved for character name column
COL_W = 130   # px per plant-tier column
TOP   = 58    # px reserved for headers
ROW_H = 96    # px per character row
NW, NH = 92, 38  # node width, height


def col_x(plant_type):
    return LEFT + PLANT_IDX[plant_type] * COL_W + COL_W // 2


def row_y(idx):
    return TOP + idx * ROW_H + ROW_H // 2


# ── parsing ────────────────────────────────────────────────────────────────────

def parse_scripts(path):
    with open(path) as f:
        text = f.read()

    # Extract top-level entry blocks by tracking brace depth.
    # re.split on },\s*{ breaks when Lua comments sit between entries.
    raw_blocks = []
    depth, start, i = 0, -1, 0
    while i < len(text):
        c = text[i]
        if c == '-' and i + 1 < len(text) and text[i + 1] == '-':
            while i < len(text) and text[i] != '\n':
                i += 1
        elif c == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                if text[i] == '\\':
                    i += 1
                i += 1
        elif c == '{':
            depth += 1
            if depth == 2:
                start = i + 1
        elif c == '}':
            if depth == 2 and start >= 0:
                raw_blocks.append(text[start:i])
                start = -1
            depth -= 1
        i += 1

    entries = []
    for block in raw_blocks:
        e = {}
        m = re.search(r'\bid\s*=\s*"([^"]+)"', block)
        if m: e["id"] = m.group(1)
        m = re.search(r'\bchapter\s*=\s*(\d+)', block)
        if m: e["chapter"] = int(m.group(1))
        m = re.search(r'\bname\s*=\s*"([^"]+)"', block)
        if m: e["name"] = m.group(1)
        m = re.search(r'\btrigger\s*=\s*\{[^}]*plant_type\s*=\s*(\d+)[^}]*count\s*=\s*(\d+)', block)
        if m:
            e["trig_pt"]    = int(m.group(1))
            e["trig_count"] = int(m.group(2))
        for m2 in re.finditer(r'\bplant_type\s*=\s*(\d+)', block):
            e["buy_pt"] = int(m2.group(1))
        m = re.search(r'\bmessages\s*=\s*\{([^}]*)\}', block)
        msgs = re.findall(r'"([^"]+)"', m.group(1)) if m else []
        e["first_msg"] = msgs[0] if msgs else ""
        e["no_dismiss"] = bool(re.search(r'\bno_dismiss\s*=\s*true', block))
        if "id" in e and "chapter" in e and "trig_pt" in e:
            entries.append(e)
    return entries


def group_characters(entries):
    seen, order = {}, []
    for e in entries:
        if e["id"] not in seen:
            seen[e["id"]] = {"name": e["name"], "chapters": []}
            order.append(e["id"])
        seen[e["id"]]["chapters"].append(e)
    chars = [(cid, seen[cid]) for cid in order]
    chars.sort(key=lambda x: (
        PLANT_IDX[x[1]["chapters"][0]["trig_pt"]],
        x[1]["chapters"][0]["trig_count"],
    ))
    return chars


def compute_positions(chars):
    """Return {char_id: {chapter_num: (x, y)}}."""
    pos = {}
    for row_i, (cid, cdata) in enumerate(chars):
        pos[cid] = {}
        ry = row_y(row_i)
        by_col = {}
        for ch in cdata["chapters"]:
            by_col.setdefault(ch["trig_pt"], []).append(ch)
        for pt, chs in by_col.items():
            cx = col_x(pt)
            n = len(chs)
            offsets = [-(n - 1) * 22 + i * 44 for i in range(n)]
            for ch, off in zip(chs, offsets):
                pos[cid][ch["chapter"]] = (cx, ry + off)
    return pos


# ── drawing ────────────────────────────────────────────────────────────────────

def draw_grid(cv, n_rows, cw, ch):
    for i in range(len(PLANTS) + 1):
        x = LEFT + i * COL_W
        cv.create_line(x, 0, x, ch, fill="#ddd", dash=(3, 4))
    for i in range(n_rows + 1):
        y = TOP + i * ROW_H
        cv.create_line(0, y, cw, y, fill="#ddd", dash=(3, 4))


def draw_row_shading(cv, n_rows, cw):
    for i in range(n_rows):
        if i % 2 == 1:
            y0 = TOP + i * ROW_H + 1
            y1 = y0 + ROW_H - 1
            cv.create_rectangle(0, y0, cw, y1, fill="#f0f0ec", outline="")


def draw_headers(cv):
    for i, (pt, name) in enumerate(PLANTS):
        x0 = LEFT + i * COL_W + 1
        x1 = x0 + COL_W - 2
        cv.create_rectangle(x0, 1, x1, TOP - 1, fill=NODE_FILL[pt], outline="")
        cx = x0 + COL_W // 2 - 1
        cv.create_text(cx, TOP // 2, text=name, font=("Helvetica", 11, "bold"), fill="#333")


def draw_char_labels(cv, chars):
    for row_i, (cid, cdata) in enumerate(chars):
        y = row_y(row_i)
        cv.create_text(LEFT - 10, y, text=cdata["name"], anchor="e",
                       font=("Helvetica", 10), fill="#333")


def draw_arrows(cv, chars, pos):
    for cid, cdata in chars:
        chs = cdata["chapters"]
        for i in range(len(chs) - 1):
            a, b = chs[i], chs[i + 1]
            ax, ay = pos[cid][a["chapter"]]
            bx, by = pos[cid][b["chapter"]]

            if ax == bx:                  # same column → vertical
                x0, y0 = ax, ay + NH // 2 + 1
                x1, y1 = bx, by - NH // 2 - 1
            elif bx > ax:                 # going right
                x0, y0 = ax + NW // 2 + 1, ay
                x1, y1 = bx - NW // 2 - 1, by
            else:                         # going left (regression)
                x0, y0 = ax - NW // 2 - 1, ay
                x1, y1 = bx + NW // 2 + 1, by

            cv.create_line(x0, y0, x1, y1,
                           arrow=tk.LAST, fill="#555", width=2,
                           arrowshape=(9, 11, 4))


def draw_nodes(cv, chars, pos, tip_var):
    for cid, cdata in chars:
        for ch in cdata["chapters"]:
            nx, ny = pos[cid][ch["chapter"]]
            trig_pt = ch["trig_pt"]
            buy_pt  = ch.get("buy_pt", trig_pt)
            is_pull = PLANT_IDX.get(buy_pt, 0) > PLANT_IDX.get(trig_pt, 0)

            fill    = NODE_FILL.get(trig_pt, "#eee")
            outline = PULL_OUTLINE if is_pull else "#888"
            lw      = 2 if is_pull else 1

            x0, y0 = nx - NW // 2, ny - NH // 2
            x1, y1 = nx + NW // 2, ny + NH // 2
            tag = f"node_{cid}_{ch['chapter']}"

            rect = cv.create_rectangle(x0, y0, x1, y1,
                                       fill=fill, outline=outline, width=lw, tags=tag)

            line1 = f"Ch{ch['chapter']}  ≥{ch['trig_count']}"
            line2 = f"→ {PLANT_NAME.get(buy_pt, '?')}" if is_pull else ""
            label = line1 + ("\n" + line2 if line2 else "")

            txt = cv.create_text(nx, ny, text=label, font=("Helvetica", 9),
                                  justify=tk.CENTER, fill="#222", tags=tag)

            tip = (f"{cdata['name']}  ch{ch['chapter']}  ·  "
                   f"trigger: ≥{ch['trig_count']} {PLANT_NAME.get(trig_pt,'?')} sold  ·  "
                   f"buys: {PLANT_NAME.get(buy_pt,'?')}")
            if ch.get("first_msg"):
                tip += f"  ·  \"{ch['first_msg']}\""

            def on_enter(_, t=tip): tip_var.set(t)
            def on_leave(_):        tip_var.set("")

            for item in (rect, txt):
                cv.tag_bind(item, "<Enter>", on_enter)
                cv.tag_bind(item, "<Leave>", on_leave)


def draw_legend(cv, cw, ch):
    lx, ly = LEFT + 4, ch - 20
    cv.create_rectangle(lx, ly - 8, lx + 14, ly + 8,
                        fill="#eee", outline=PULL_OUTLINE, width=2)
    cv.create_text(lx + 20, ly, text="pull  (triggers on earlier tier, buys next)",
                   anchor="w", font=("Helvetica", 8), fill="#666")


# ── main ───────────────────────────────────────────────────────────────────────

def main():
    path    = sys.argv[1] if len(sys.argv) > 1 else SCRIPT_PATH
    entries = parse_scripts(path)
    chars   = group_characters(entries)
    pos     = compute_positions(chars)

    cw = LEFT + len(PLANTS) * COL_W + 20
    ch = TOP + len(chars) * ROW_H + 36

    root = tk.Tk()
    root.title("Quest Grid")
    root.configure(bg=BG)
    root.resizable(False, False)

    cv = tk.Canvas(root, width=cw, height=ch, bg=BG, highlightthickness=0)
    cv.pack()

    draw_row_shading(cv, len(chars), cw)
    draw_grid(cv, len(chars), cw, ch)
    draw_headers(cv)
    draw_char_labels(cv, chars)
    draw_arrows(cv, chars, pos)

    tip_var = tk.StringVar()
    draw_nodes(cv, chars, pos, tip_var)
    draw_legend(cv, cw, ch)

    tip_bar = tk.Label(root, textvariable=tip_var, anchor="w", bg="#fffff0",
                       fg="#444", font=("Helvetica", 9), relief="flat", padx=8, pady=3)
    tip_bar.pack(fill=tk.X, side=tk.BOTTOM)

    root.mainloop()


if __name__ == "__main__":
    main()
