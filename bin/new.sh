#!/usr/bin/env bash

TITLE=$1
DATE=$(date +%F)

if [ -z "$TITLE" ]; then
  TITLE=$DATE
fi

COUNT=$(ls content | wc -l)

SLUG=$(echo $TITLE | iconv -t ascii//TRANSLIT | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)
FILE="content/$SLUG/index.md"

mkdir -p "content/$SLUG/"
cat <<-EOF >$FILE
+++
title="$TITLE"
id=$COUNT
date=$DATE
tags=[]
+++

EOF

nvim $FILE
