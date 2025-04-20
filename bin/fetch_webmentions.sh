#!/usr/bin/env bash
set -euo pipefail

DOMAIN="misc.rhumbs.fr"
TOKEN="OPqTpC4aDiYHTphMx5z1xw"

ROOT="$(cd "$(dirname "$0")" && pwd)/.."
DATA_DIR="${ROOT}/content/webmentions"
API_URL="https://webmention.io/api/mentions.jf2"
SINCE=$(date -d"3 days ago" +"%Y-%m-%d")

mkdir -p "$DATA_DIR"
curl -s "${API_URL}?domain=${DOMAIN}&token=${TOKEN}&since=${SINCE}&per-page=999" -o webmentions-all.json

# Fetch targets (blog posts)
targets=$(jq -r '.children[]."wm-target"' webmentions-all.json | sort -u)
for target in $targets; do
  path=$(echo "$target" | sed -E "s~https?://$DOMAIN/?~~" | sed 's/\/$//')
  file="$DATA_DIR/${path}.json"
  mkdir -p "$(dirname "$file")"

  # Get webmentions for target
  jq --arg target "$target" '
    [.children[] | select(."wm-target" == $target)]
  ' webmentions-all.json >webmentions-current.json

  if [ -f "$file" ]; then
    jq -s '
      (.[0] + .[1]) | unique_by(.["wm-id"]) | sort_by(.published)
    ' "$file" webmentions-current.json >"$file.tmp"
    mv "$file.tmp" "$file"
  else
    mv webmentions-current.json "$file"
  fi

  echo "Updated: $file"
done

rm webmentions-all.json

echo "✅ Webmentions updated for all targets (as JSON arrays)."
