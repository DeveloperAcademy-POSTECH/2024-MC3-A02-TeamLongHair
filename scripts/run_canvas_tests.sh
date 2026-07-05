#!/bin/bash
set -e
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/canvas_logic_tests"
swiftc -o "$OUT" \
  TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift \
  CanvasLogicTests/main.swift
"$OUT"
