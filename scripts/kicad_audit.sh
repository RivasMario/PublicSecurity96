#!/usr/bin/env bash
# PublicSecurity96 — headless audit via kicad-cli (KiCad 8+)
# Runs ERC + DRC + exports BOM + schematic PDF without opening GUI.
# Usage: bash scripts/kicad_audit.sh
# Requires kicad-cli on PATH (Windows: add C:\Program Files\KiCad\<ver>\bin to PATH).

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCH="$PROJECT_DIR/PublicSecurity96/PublicSecurity96.kicad_sch"
PCB="$PROJECT_DIR/PublicSecurity96/PublicSecurity96.kicad_pcb"
OUT="$PROJECT_DIR/audit_output"

mkdir -p "$OUT"

echo "[1/4] Schematic ERC -> $OUT/erc.json"
kicad-cli sch erc \
  --severity-error --severity-warning \
  --format json \
  --output "$OUT/erc.json" \
  "$SCH"

echo "[2/4] BOM CSV -> $OUT/bom.csv"
kicad-cli sch export bom \
  --output "$OUT/bom.csv" \
  --fields 'Reference,Value,Footprint,${QUANTITY},JLCPCB part#,Comment' \
  --group-by 'Value,Footprint' \
  "$SCH"

echo "[3/4] Schematic PDF -> $OUT/schematic.pdf"
kicad-cli sch export pdf \
  --output "$OUT/schematic.pdf" \
  "$SCH"

echo "[4/4] PCB DRC -> $OUT/drc.json"
kicad-cli pcb drc \
  --severity-error --severity-warning \
  --format json \
  --output "$OUT/drc.json" \
  "$PCB"

echo
echo "Audit done. Inspect:"
echo "  $OUT/erc.json    — schematic errors (PWR_FLAG missing will show here)"
echo "  $OUT/drc.json    — PCB errors"
echo "  $OUT/bom.csv     — verify Y1=12MHz, F1=500mA polyfuse, U1=AMS1117-3.3"
echo "  $OUT/schematic.pdf — visual review"
