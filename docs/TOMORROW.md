# Resume Tomorrow

## Where you left off
- Branch: `fix/power-section-skyway96-style`
- Last commit: `9f81e0e wip: place R20 27R on D+ (right-pad snap to pin 47 pending)`

## Done so far
- ✅ U1 swap: XC6206 → AMS1117-3.3, footprint `SOT-223-3_TabPin2`, JLCPCB `C6186`
- ✅ Y1 crystal value: 16MHz → 12MHz (text edit earlier)
- ✅ F1 fuse: Value `Fuse` → `500mA polyfuse`, JLCPCB → `C2685389`
- ✅ R20 placed (27R) — left pad connected to D+ side
- ⚠ R20 right pad → RP2040 pin 47 NOT connected (snap fight)

## The grid lesson (read first thing tomorrow)
- **Schematic grid = always 1.27 mm (50 mil).** Don't touch.
- R20 currently placed at `(432.2982, 178.308)` — OFF 1.27mm grid by ~0.5mm. That's why nothing snaps.
- Press **`N`** / **`Shift+N`** to cycle grid. Watch bottom-left status bar.

## First action tomorrow
1. Open KiCad → schematic.
2. Confirm grid = `1.27 mm` (bottom-left status).
3. Either:
   - Delete R20, re-add fresh with `A` → `Device:R`, will land on 1.27mm grid. Set value `27R`, footprint `Resistor_SMD:R_0402_1005Metric`, JLCPCB `C25092`.
   - OR hover R20 → `M` → drop on clean 1.27mm grid point near pin 47.
4. Wires can **bend**. Press `W` → click pad → click intermediate point (90° bend) → click target.
5. Verify: backtick `` ` `` → click any segment → all R20 wires + RP2040 pin 47 + D+ side glow same color.

## Then continue (in order)
1. **R21** (27R on D−) — mirror of R20 process between SRV05-4 and RP2040 USB_DM pin (pin 46).
2. **R22** (1k on XOUT) — between Y1 pin 3 and RP2040 pin 21. 22pF cap stays on crystal side of R22.
3. **PWR_FLAG ×3** — drop on `+5V`, `+3V3`, `GND` nets. Press `A` → `power:PWR_FLAG` → wire to net.
4. **IOVDD audit** — count 100nF caps on RP2040 IOVDD pins (1, 10, 22, 33, 42, 49). Need 6 total. Add missing.
5. **Run ERC** — should now show 0 `power_pin_not_driven` errors.
6. **F8** — push to PCB. Open pcbnew. Place new footprints near MCU.
7. **AMS1117 thermal pour** — bottom GND zone ≥1cm² around U1, stitching vias.
8. **DRC** — fix all errors.
9. **Plot Gerbers** + BOM + .pos → JLCPCB.

## Files for reference (in this repo)
- `docs/GUI_FIX_STEPS.md` — full beginner walkthrough Parts 0–13
- `docs/MISSING_VS_SKYWAY.md` — what's missing + why
- `docs/reference/rp2040_keyboard_design.md` — Kiser standards
- `scripts/kicad_audit.sh` — headless ERC/DRC/BOM (after kicad-cli on PATH)

## JLCPCB part numbers (cheat sheet)
| Part | LCSC | Footprint |
|---|---|---|
| AMS1117-3.3 | C6186 | SOT-223-3_TabPin2 |
| 500mA polyfuse | C2685389 | 1206 |
| 27R 0402 | C25092 | R_0402_1005Metric |
| 1k 0402 | C11702 | R_0402_1005Metric |
| 100nF 0402 | C1525 | C_0402_1005Metric |
| 1µF 0402 | C15849 | C_0402_1005Metric |
| 10µF 0805 | C15850 | C_0805_2012Metric |

## Pin map — RP2040 USB / clock (so you don't search again)
- pin 20 = XIN → Y1 pin 1
- pin 21 = XOUT → R22 → Y1 pin 3
- pin 46 = USB_DM (D−) → R21 → SRV05-4
- pin 47 = USB_DP (D+) → R20 → SRV05-4
