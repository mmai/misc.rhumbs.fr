#!/usr/bin/env bash

ROOT="$(cd "$(dirname "$0")" && pwd)/.."

TYPE="blog"
DATE_FMT="+%F" # YYYY-MM-DD
TITLE=$1

if [ "$TITLE" = "microblog" ]; then
  TYPE="microblog"
  TITLE=""
  DATE_FMT="+%FT%T%:z" # YYYY-MM-DDTHH:MM:SS+HH:MM
fi

DATE=$(date $DATE_FMT)
if [ -z "$TITLE" ]; then
  TITLE=$DATE
fi

FOLDER="$ROOT/content/$TYPE"
COUNT=$(ls "$FOLDER" | wc -l)
SLUG=$(echo $TITLE | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)
FILE="$FOLDER/$SLUG/index.md"

mkdir -p "$FOLDER/$SLUG"
cat <<-EOF >$FILE
+++
title="$TITLE"
id=$COUNT
date=$DATE

[taxonomies]
tags=[]
+++

<!-- more -->
EOF

nvim $FILE
