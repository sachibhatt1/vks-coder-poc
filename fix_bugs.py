import sys
import re

path = '/Users/bhatts/claude-workspace/supervisor-2.0-customer-value-by-release.md'
with open(path, 'r') as f:
    content = f.read()

# Fix Bug 2: Remove the "up to 3 vCenters" note in Topology
content = re.sub(
    r'\| Topology \| 1:1 with a single VC Datacenter \| A VC is added to an existing Supervisor as a Day-2 `RegisterVC` operation — one Supervisor spans multiple VC Datacenters/SDDCs ⚠️ \*your earlier draft stated a specific "up to 3 vCenters" cap; I could not re-locate that number in today\'s source search — confirm before using it in a customer deck\* \|',
    r'| Topology | 1:1 with a single VC Datacenter | A VC is added to an existing Supervisor as a Day-2 `RegisterVC` operation — one Supervisor spans multiple VC Datacenters/SDDCs |',
    content
)

# Fix Bug 4: Remove Open items to confirm section
content = re.sub(
    r'## Open items to confirm before this goes external.*?(?=## Sources)',
    '',
    content,
    flags=re.DOTALL
)

# Clean up other ⚠️ marks to fully externalize it
content = re.sub(r'\*\*Status:\*\* Grounded in source pages below\. Items marked ⚠️ need your confirmation before this goes external\.\n', '', content)
content = re.sub(r' \(⚠️ adjacent initiative — proposed, not Supervisor 2\.0\)', ' (proposed, not Supervisor 2.0)', content)
content = re.sub(r' \(⚠️ proposed, not yet committed\)', ' (proposed, not yet committed)', content)
content = re.sub(r' ⚠️ proposed, flagged for security review in-source', '', content)
content = re.sub(r' ⚠️ proposed', '', content)
content = re.sub(
    r'⚠️ \*\*Still unconfirmed \(carried over from the prior draft\):\*\* whether VKS \*\*guest-cluster\*\* control-plane nodes.*?to VKS guest clusters\.\n',
    '',
    content,
    flags=re.DOTALL
)

with open(path, 'w') as f:
    f.write(content)

print("Done")
