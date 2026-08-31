import sys
import re

path = '/Users/bhatts/claude-workspace/supervisor-2.0-rearchitecture.md'
with open(path, 'r') as f:
    content = f.read()

# Bug 1
content = re.sub(
    r'\*\*⚠️ CORRECTED 2026-08-10\*\* — the row below originally named.*?(?=\*\*The anchor claim, stated precisely \(from your source\):\*\*)',
    '',
    content,
    flags=re.DOTALL
)

# Bug 4 remaining bits
content = re.sub(
    r'## Notes on how I compressed your source.*?(?=$)',
    '',
    content,
    flags=re.DOTALL
)

with open(path, 'w') as f:
    f.write(content)

print("Done")