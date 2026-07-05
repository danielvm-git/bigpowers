#!/bin/bash
# Fix the broken regex in migrate-version.sh
cd /Users/danielvm/Developer/bigpowers
python3 -c '
path = "scripts/migrate-version.sh"
with open(path) as f:
    content = f.read()

old = """    pat = re.compile(rf\"^\"+re.escape(md_key.rstrip(\":\"))+\"\\\\s*[:=]\\\\s*(.+)$\", re.MULTILINE | re.IGNORECASE)"""
new = """    pat = re.compile(r\"^\" + re.escape(md_key.rstrip(\":\")) + r\"\\s*[:=]\\s*(.+)$\", re.MULTILINE | re.IGNORECASE)"""

content = content.replace(old, new)
with open(path, "w") as f:
    f.write(content)
print("Fixed")
'