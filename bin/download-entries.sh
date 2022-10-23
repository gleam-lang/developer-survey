#!/bin/sh

set -eu

NOW=$(date +%Y%m%d-%H%M%S)
DIR="$HOME/Desktop/gleam-developer-survey"
OUT="$DIR/entries-$NOW.jsonl"

mkdir "$DIR"

echo "Downloading to $OUT"
fly ssh sftp get /app/data/entries.jsonl "$OUT"
