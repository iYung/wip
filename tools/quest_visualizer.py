#!/usr/bin/env python3
"""Visualize quest pull chain and character details from customer_scripts.lua."""

import re
import sys
import os

SCRIPT_PATH = os.path.join(os.path.dirname(__file__), "..", "lua", "game", "data", "customer_scripts.lua")

PLANT_NAMES = {
    1: "Grass",
    2: "Cactus",
    3: "Rose",
    4: "Tulip",
    5: "Daisy",
    6: "Golden Lotus",
}

PLANT_ORDER = [1, 2, 3, 4, 5, 6]


def parse_scripts(path):
    with open(path) as f:
        text = f.read()

    entries = []
    for block in re.split(r"\},\s*\{", text):
        entry = {}

        m = re.search(r'\bid\s*=\s*"([^"]+)"', block)
        if m:
            entry["id"] = m.group(1)

        m = re.search(r'\bchapter\s*=\s*(\d+)', block)
        if m:
            entry["chapter"] = int(m.group(1))

        m = re.search(r'\bname\s*=\s*"([^"]+)"', block)
        if m:
            entry["name"] = m.group(1)

        m = re.search(r'\btrigger\s*=\s*\{\s*plant_type\s*=\s*(\d+)\s*,\s*count\s*=\s*(\d+)', block)
        if m:
            entry["trigger_type"] = int(m.group(1))
            entry["trigger_count"] = int(m.group(2))

        # plant_type line (what they buy) — comes after trigger block
        for m in re.finditer(r'\bplant_type\s*=\s*(\d+)', block):
            entry["plant_type"] = int(m.group(1))

        m = re.search(r'\bno_dismiss\s*=\s*true', block)
        entry["no_dismiss"] = bool(m)

        if "id" in entry and "chapter" in entry:
            entries.append(entry)

    return entries


def group_by_character(entries):
    seen = {}
    ordered = []
    for e in entries:
        if e["id"] not in seen:
            seen[e["id"]] = []
            ordered.append(e["id"])
        seen[e["id"]].append(e)
    return [(k, seen[k]) for k in ordered]


def is_pull(entry):
    trigger = entry.get("trigger_type")
    buys = entry.get("plant_type")
    if trigger is None or buys is None:
        return False
    try:
        return PLANT_ORDER.index(buys) > PLANT_ORDER.index(trigger)
    except ValueError:
        return False


def print_pull_chain(entries):
    pulls = [e for e in entries if is_pull(e)]

    # Build a map: from_plant -> list of (to_plant, entry)
    chain = {}
    for e in pulls:
        t = e["trigger_type"]
        chain.setdefault(t, []).append(e)

    print("=" * 60)
    print("  PULL CHAIN")
    print("=" * 60)

    for i, plant_id in enumerate(PLANT_ORDER[:-1]):
        from_name = PLANT_NAMES[plant_id].ljust(12)
        to_name = PLANT_NAMES[PLANT_ORDER[i + 1]]
        pulls_here = chain.get(plant_id, [])

        if pulls_here:
            for e in pulls_here:
                label = f"{e['name']} Ch{e['chapter']}: {e['trigger_count']} sold"
                buys_name = PLANT_NAMES.get(e["plant_type"], "?")
                arrow = f"──[{label}]──▶  {buys_name}"
                print(f"  {from_name} {arrow}")
        else:
            print(f"  {from_name} ── (no pull) ──▶  {to_name}  ⚠")

    print()


def print_character_details(groups):
    print("=" * 60)
    print("  CHARACTER DETAILS")
    print("=" * 60)

    for char_id, chapters in groups:
        name = chapters[0]["name"]
        print(f"\n  {name}  ({len(chapters)} chapter{'s' if len(chapters) > 1 else ''})")
        print(f"  {'-' * (len(name) + 14)}")

        for e in chapters:
            t_plant = PLANT_NAMES.get(e.get("trigger_type"), "?")
            t_count = e.get("trigger_count", "?")
            buys = PLANT_NAMES.get(e.get("plant_type"), "?")
            pull = "  ← pull" if is_pull(e) else ""
            no_dismiss = "  [no dismiss]" if e.get("no_dismiss") else ""
            trigger_str = f"{t_count} {t_plant} sold" if t_count != "?" else "— (intro)"
            print(f"    Ch{e['chapter']}  trigger: {trigger_str:<22} buys: {buys}{pull}{no_dismiss}")

    print()


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else SCRIPT_PATH
    entries = parse_scripts(path)
    groups = group_by_character(entries)

    print()
    print_pull_chain(entries)
    print_character_details(groups)


if __name__ == "__main__":
    main()
