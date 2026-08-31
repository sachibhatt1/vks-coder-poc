import sys
import re

path = '/Users/bhatts/claude-workspace/supervisor-2.0-rearchitecture.md'
with open(path, 'r') as f:
    content = f.read()

# Make sure all internal notes are gone
content = re.sub(r'Status: \*\*draft — grounded in your Confluence source, but a few claims need your confirmation before this is customer-ready \(flagged with ⚠️ below\)\. Nothing below is invented; anywhere I compressed or attributed a persona that your source table left blank, I marked it\.\*\*\n', '', content)
content = re.sub(r'⚠️ \*\*Confirm:\*\* I pulled these 4 as the VI-admin set from your table.*?that I didn\'t pick\.', '', content, flags=re.DOTALL)
content = re.sub(r'⚠️ \*\*Confirm:\*\* same caveat — these 4 are my pick as the platform-eng set; adjust if needed\.', '', content)
content = re.sub(r'⚠️ \*\*This one I can\'t confirm from your pasted source\.\*\*.*?isn\'t in the source material\.', '', content, flags=re.DOTALL)

with open(path, 'w') as f:
    f.write(content)

print("Done")