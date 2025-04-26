#!/usr/bin/env bash
set -euo pipefail

DOMAIN="misc.rhumbs.fr"
TOKEN="OPqTpC4aDiYHTphMx5z1xw"

ROOT="$(cd "$(dirname "$0")" && pwd)/.."
DATA_DIR="${ROOT}/content/webmentions"
API_URL="https://webmention.io/api/mentions.jf2"
SINCE=$(date -d"3 days ago" +"%Y-%m-%d")

mkdir -p "$DATA_DIR"
curl -s "${API_URL}?domain=${DOMAIN}&token=${TOKEN}&since=${SINCE}&per-page=999" -o webmentions-all.jf2

# Fetch targets (blog posts)
targets=$(jq -r '.children[]."wm-target"' webmentions-all.jf2 | sort -u)
for target in $targets; do
  path=$(echo "$target" | sed -E "s~https?://$DOMAIN/?~~" | sed 's/\/$//')
  file="$DATA_DIR/${path}.jf2"
  mkdir -p "$(dirname "$file")"

  # Get webmentions for target
  jq --arg target "$target" '
  {
    type: "feed",
    name: "Webmentions",
    children: [.children[] | select(."wm-target" == $target)]
  }
  ' webmentions-all.jf2 >webmentions-current.jf2

  if [ -f "$file" ]; then
    jq -s '
    {
      type: "feed",
      name: "Webmentions",
      children: (
        (.[0].children + .[1].children)
        | unique_by(.["wm-id"])
        | sort_by(.published)
      )
    }
    ' "$file" webmentions-current.jf2 >"$file.tmp"
    mv "$file.tmp" "$file"
    rm webmentions-current.jf2
  else
    mv webmentions-current.jf2 "$file"
  fi

  echo "Updated: $file"
done

rm webmentions-all.jf2

echo "✅ Webmentions updated for all targets."
