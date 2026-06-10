#!/usr/bin/env python3
"""Generate a slightly emboldened Dank Mono variant for VS Code.

Dank Mono's strokes are a touch too thin on a hidpi Linux setup. This takes
the installed DankMono Nerd Font OTFs and produces a "DankMono Thick Nerd
Font" family with fattened stems, keeping Regular/Italic/Bold roles intact so
editor bold/italic mapping still works.

Run under fontforge's python:  fontforge -script scripts/make-dankmono-thick.py [stem_add]
Fonts land in ~/.local/share/fonts/DankMonoThick/ ; run fc-cache after.
"""

import os
import sys

import fontforge

SRC_DIR = os.path.expanduser("~/.local/share/fonts/DankMonoNerdFont")
DST_DIR = os.path.expanduser("~/.local/share/fonts/DankMonoThick")
STEM_ADD = int(sys.argv[1]) if len(sys.argv) > 1 else 20  # em-units (em = 1000)

STYLES = ["Regular", "Italic", "Bold"]

os.makedirs(DST_DIR, exist_ok=True)

for style in STYLES:
    src = os.path.join(SRC_DIR, f"DankMonoNerdFont-{style}.otf")
    f = fontforge.open(src)
    f.selection.all()
    f.changeWeight(STEM_ADD, "auto", 0, 0, "auto")

    f.familyname = "DankMono Thick Nerd Font"
    f.fontname = f"DankMonoThickNF-{style}"
    f.fullname = f"DankMono Thick Nerd Font {style}"
    # Drop inherited name-table entries (preferred family etc.) that would
    # otherwise keep the font grouped under the original family.
    f.sfnt_names = ()

    dst = os.path.join(DST_DIR, f"DankMonoThickNF-{style}.otf")
    f.generate(dst)
    f.close()
    print(f"  -> {dst}")

print(f"Done (stem add {STEM_ADD}). Run: fc-cache -f {DST_DIR}")
