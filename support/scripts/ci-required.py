"""The `required` job of CI waits for every other job: branch protection asks only for `required`, so a job missing
from its `needs` could fail without stopping a merge.   python3 support/scripts/ci-required.py [workflow]"""

import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else ".github/workflows/ci.yml"
text = open(path, encoding="utf-8").read()
body = text.split("\njobs:\n", 1)[1]
jobs = re.findall(r"^  ([A-Za-z0-9_-]+):\s*$", body, flags=re.M)
needs = re.search(r"^  required:\n(?:    .*\n)*?    needs: \[([^\]]*)\]", body, flags=re.M)
if not needs:
    sys.exit("the required job has no needs list")
listed = {n.strip() for n in needs.group(1).split(",")}
missing = sorted(set(jobs) - listed - {"required"})
if missing:
    sys.exit(f"required does not wait for: {', '.join(missing)}")
print(f"required waits for all {len(listed)} jobs: {', '.join(sorted(listed))}")
