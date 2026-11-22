#!/bin/sh
# Deploys worker.js + page.html to Cloudflare (worker "calendar", D1 binding DB, KEY var),
# to Cloudflare Pages (daybook-office), and pushes the public files to GitHub
# (repo amy-brooks-fa/daybook-calendar, GitHub Pages https://amy-brooks-fa.github.io/daybook-calendar/?k=<KEY>).
T=$(grep -o 'cfut_[A-Za-z0-9_-]*' ~/notes/accounts/cloudflare.md); A=8bcd93500375c6b4d6b955453b34953e
KEY=$(cat "$(dirname "$0")/key.txt")
META='{"main_module":"worker.js","compatibility_date":"2025-06-01","bindings":[{"type":"d1","name":"DB","id":"b0e84bb7-47ac-46ec-8d67-a3d607cb1949"},{"type":"plain_text","name":"KEY","text":"'$KEY'"}]}'
cd "$(dirname "$0")"
curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/$A/workers/scripts/calendar" -H "Authorization: Bearer $T" \
  -F "metadata=$META;type=application/json" \
  -F "worker.js=@worker.js;type=application/javascript+module" \
  -F "page.html=@page.html;type=text/plain" | python3 -c "import json,sys;d=json.load(sys.stdin);print('success',d['success'],d.get('errors'))"
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$A/workers/scripts/calendar/subdomain" -H "Authorization: Bearer $T" -H 'Content-Type: application/json' -d '{"enabled":true,"previews_enabled":false}' | python3 -c "import json,sys;d=json.load(sys.stdin);print('subdomain',d['success'],d.get('errors'))"
# Round 5: same app on Cloudflare Pages (daybook-office.pages.dev) - _worker.js with page.html inlined, same D1 + KEY (pages/wrangler.toml)
python3 - <<'PY'
import json,os
d=os.path.dirname(os.path.abspath("worker.js"))+"/"
w=open(d+"worker.js").read().replace('import PAGE from "./page.html";','const PAGE = '+json.dumps(open(d+"page.html").read())+';')
open(d+"pages/public/_worker.js","w").write(w)
PY
(cd pages && CLOUDFLARE_API_TOKEN=$T CLOUDFLARE_ACCOUNT_ID=$A npx -y wrangler@latest pages deploy --branch main 2>&1 | grep -E "Success|complete|ERROR")

# GitHub (2026-11-22): copy ONLY the public files into the repo folder, refuse to push if the access key,
# a Cloudflare/GitHub token or any client name is in them, then commit and push. GitHub Pages rebuilds in ~1 minute.
R=$HOME/agent/results/daybook-calendar-repo
GT=$(grep -o 'ghp_[A-Za-z0-9]*' ~/notes/accounts/github.md)
[ -d "$R/.git" ] || { git clone -q "https://x-access-token:$GT@github.com/amy-brooks-fa/daybook-calendar.git" "$R" 2>&1 | grep -v "empty repository"; git -C "$R" remote set-url origin https://github.com/amy-brooks-fa/daybook-calendar.git; }
git -C "$R" config user.name "Amy Brooks"; git -C "$R" config user.email "amy.brooks@fromassistant.com"
cp page.html "$R/index.html"; cp page.html worker.js deploy.sh gen-holidays.mjs README.md "$R/"; touch "$R/.nojekyll"
curl -s "https://calendar.daybook-amy.workers.dev/c/$KEY/api/clients" | python3 -c '
import json,sys,re
cl=json.load(sys.stdin)["clients"]; out=set()
for c in cl:
  out.add(c["name"])
  for w in re.findall(r"[A-Za-z]{4,}", c["name"]):
    if w.lower() not in ("esther",): out.add(w)   # Esther = also the holiday name Taanis Esther in the page
print("\n".join(sorted(out)))' > /tmp/gh-names.txt
[ -s /tmp/gh-names.txt ] || { echo "GITHUB: could not read the client list for the name check - NOT pushed"; exit 1; }
BAD=$(cd "$R" && { grep -rIl --exclude-dir=.git -F "$KEY" .; grep -rIlE --exclude-dir=.git 'cfut_[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{30,}' .; grep -rIlw --exclude-dir=.git -F -f /tmp/gh-names.txt .; ls | grep -E '^backup|key\.txt|wrangler\.toml'; } | sort -u)
[ -z "$BAD" ] || { echo "GITHUB: key/token/client name/private file found in: $BAD - NOT pushed"; exit 1; }
cd "$R" && git add -A && { git diff --cached --quiet && echo "GITHUB: no changes"; } || { git commit -q -m "Update $(date '+%Y-%m-%d %H:%M %Z')" && git push -q "https://x-access-token:$GT@github.com/amy-brooks-fa/daybook-calendar.git" HEAD:main 2>&1 | sed "s/$GT/***/g"; echo "GITHUB: pushed $(git rev-parse --short HEAD)"; }
