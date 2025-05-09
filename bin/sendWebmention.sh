#!/usr/bin/env bash

TARGET="https://misc.rhumbs.fr/blog/pierre-feline/"
SOURCE="http://misc.rhumbs.fr/blog/webmention-without-hcard/"

DATA="target=$TARGET&source=$SOURCE"
curl \
  -d "$DATA" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -X POST "https://webmention.io/misc.rhumbs.fr/webmention"
