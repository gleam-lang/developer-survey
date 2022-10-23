#!/bin/sh

set -eu

fly ssh console -C 'wc -l /app/data/entries.jsonl'
