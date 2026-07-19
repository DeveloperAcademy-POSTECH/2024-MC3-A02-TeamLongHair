#!/bin/bash
set -e
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/canvas_logic_tests"
swiftc -o "$OUT" \
  TeamLongHair/TeamLongHair/Project/Page/Canvas/TreeLayout.swift \
  TeamLongHair/TeamLongHair/Project/Page/Canvas/DropValidator.swift \
  TeamLongHair/TeamLongHair/Utils/LinkMetadataParsing.swift \
  TeamLongHair/TeamLongHair/Utils/CaptureTargetResolver.swift \
  TeamLongHair/TeamLongHair/Utils/HotKeyModifiers.swift \
  TeamLongHair/TeamLongHair/Home/ProjectCardFormatting.swift \
  CanvasLogicTests/main.swift
"$OUT"
