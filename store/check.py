"""Checks the store listing texts against the stores' length limits.

App Store Connect: name 30, subtitle 30, promotional text 170, keywords 100
(comma-separated, no spaces), description 4000. Google Play: title 30, short
description 80, full description 4000. Run: python3 store/check.py
"""
import pathlib
import re
import sys

LIMITS = {"app-store": [30, 30, 170, 100, 4000], "google-play": [30, 80, 4000]}

ok = True
here = pathlib.Path(__file__).parent
for store, limits in LIMITS.items():
    for path in sorted((here / store).glob("*.md")):
        if path.name == "README.md":
            continue
        sections = [s.strip() for s in re.split(r"^## .*$", path.read_text(), flags=re.M)[1:]]
        if len(sections) != len(limits):
            ok = False
            print(f"{store}/{path.name}: expected {len(limits)} sections, found {len(sections)}")
            continue
        for text, limit in zip(sections, limits):
            good = len(text) <= limit
            ok &= good
            print(f"{store}/{path.name}: {len(text):>4}/{limit} {'ok' if good else 'TOO LONG'}")
        if store == "app-store" and (", " in sections[3] or " " in sections[3]):
            ok = False
            print(f"{store}/{path.name}: keywords must be separated by commas, no spaces")
sys.exit(0 if ok else 1)
