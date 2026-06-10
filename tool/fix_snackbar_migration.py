#!/usr/bin/env python3
"""Fix corrupted SnackBar migration artifacts."""
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'lib' / 'features'
changed = 0
for path in root.rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    orig = text
    text = re.sub(r',\);,\s*\n\s*\),\s*\n\s*\);', ');', text)
    text = re.sub(r',\);,', ');', text)
    text = re.sub(r'\);;', ');', text)
    text = re.sub(r';\s*;', ';', text)
    if text != orig:
        path.write_text(text, encoding='utf-8')
        changed += 1
        print(path.relative_to(root.parent.parent))

print(f'Fixed {changed} files')
