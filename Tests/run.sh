#!/bin/sh
# Kører regel-tests for straf, rank og meritter uden Xcode (kræver swiftc).
set -e
cd "$(dirname "$0")/.."
OUT="${TMPDIR:-/tmp}/discipline-tests"
swiftc -O Shared/Tuning.swift Shared/DayKey.swift Shared/Rank.swift Shared/Discipline.swift Tests/main.swift -o "$OUT"
"$OUT"
