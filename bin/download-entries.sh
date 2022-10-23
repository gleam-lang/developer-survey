#!/bin/sh

set -eu

NOW=$(date +%Y%m%d-%H%M%S)
DIR="$HOME/Desktop/gleam-developer-survey"
OUT="$DIR/entries-$NOW.jsonl"

mkdir -p "$DIR"
fly ssh sftp get /app/data/entries.jsonl "$OUT"

echo
echo "Entries: $(cat "$OUT" | wc -l | xargs echo -n)"
