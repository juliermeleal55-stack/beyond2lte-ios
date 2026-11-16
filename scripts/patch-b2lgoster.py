#!/usr/bin/env python3
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
replacements = [
    ("    UINT64                 Tepe;\n    UINT32                 Parca;\n", "    UINT64                 Tepe;\n"),
    ("    Tepe   = 0;\n    Parca  = 0;\n", "    Tepe   = 0;\n"),
    ("          Sayfa += D->NumberOfPages;\n          Parca++;\n", "          Sayfa += D->NumberOfPages;\n"),
]
for old, new in replacements:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"Expected exactly one B2LGoster source fragment, found {count}: {old!r}")
    text = text.replace(old, new, 1)
if "Parca" in text:
    raise SystemExit("Unused Parca identifier remains after patch")
path.write_text(text)
print(f"Patched {path}: removed unused Parca counter without changing memory-map logic")
