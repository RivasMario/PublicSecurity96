# PublicSecurity96 — KiCad Rework Instructions (Path B: Skyway-96 power section)

Step-by-step. Follow in KiCad 8 with `PublicSecurity96.kicad_pro` open.

## Scope of changes
Only the **power input section** is being rebuilt. Matrix, USB-C connector, RP2040, crystal, and BOOTSEL all stay as-is.

## Changes summary

| Ref | Before | After | Reason |
|---|---|---|---|
| U1  | XC6206P (SOT-23-3, 150 mA) | AMS1117-3.3 (SOT-223, 1 A) | Thermal headroom |
| C?  | (verify) 0.1 µF in/out | **10 µF** ceramic in + **10 µF** out | AMS1117 ESR/stability |
| F1  | "Fuse" no rating, C3035895 | 500 mA hold / 1 A trip polyfuse | Trip before LDO cooks |
| U2  | SRV05-4 ESD | KEEP (functionally fine) | No change |

LCSC parts to add to BOM:
- AMS1117-3.3: **C6186**
- 10 µF 0805 X5R ceramic: **C15850** (×2)
- 500 mA polyfuse 1206: **C2685389** (or equivalent)

## Step 1 — Backup
```
git checkout -b fix/power-section-skyway96-style
```
(Already on `main` with FIX_PLAN.md committed. Branch protects the working state.)

## Step 2 — Schematic edits (Eeschema)

### 2a. Replace U1 (LDO)
1. Open `PublicSecurity96.kicad_sch`
2. Find U1 (XC6206P) — it's near the USB-C / VBUS area, around schematic coords (474, 96)
3. **Right-click U1 → "Change Symbol..."**
4. Pick `Regulator_Linear:AMS1117-3.3`
5. Click OK. KiCad will warn about pin mapping. The pin functions map cleanly:
   - XC6206 pin3 (VIN)  → AMS1117 pin3 (VIN)  — no rewire needed
   - XC6206 pin1 (VOUT) → AMS1117 pin2 (VOUT) — **wire moves**
   - XC6206 pin2 (GND)  → AMS1117 pin1 (GND) — **wire moves**
6. After swap, **drag the +3V3 wire** from old pin1 to new pin2, and the GND wire from old pin2 to new pin1. KiCad usually auto-updates if you accept the "remap pins" prompt — verify visually.
7. Set Footprint: `Package_TO_SOT_SMD:SOT-223-3_TabPin2`
8. Set "JLCPCB part#" property to `C6186`

### 2b. Add / verify input + output caps
Find the cap closest to U1's VIN (pin3) — likely C-something with value 0.1 µF or 1 µF.
1. Change its Value to `10uF`
2. Change its Footprint to `Capacitor_SMD:C_0805_2012Metric`
3. Add LCSC: `C15850`

Same for the cap on U1's VOUT (pin2 after swap):
1. Same edits as above
2. If no output cap exists, add one: `Place → Symbol → Device:C`, value `10uF`, between +3V3 and GND, place near U1 pin 2.

### 2c. Update F1
1. Click F1
2. Set Value to `500mA polyfuse`
3. Set JLCPCB part# to `C2685389` (verify in JLCPCB parts library — it's a 500 mA hold / 1 A trip 1206 polyfuse; pick equivalent if out of stock)
4. Footprint can stay `Fuse:Fuse_0805_2012Metric` if you want 0805, or change to `Resistor_SMD:R_1206_3216Metric` for higher current rating

### 2d. ERC
`Inspect → Electrical Rules Checker → Run ERC`. Fix any new "unconnected pin" errors created by the symbol swap.

## Step 3 — PCB edits (PCB Editor)

### 3a. Update PCB from schematic
`Tools → Update PCB from Schematic` (F8). KiCad will:
- Mark the old XC6206 SOT-23 footprint for deletion
- Add the new AMS1117 SOT-223 footprint
- Update cap footprints from 0402 to 0805 (if applicable)

### 3b. Place AMS1117 footprint
1. The new SOT-223 is much larger than SOT-23-3. Place it where U1 was — likely you'll need to nudge a few traces.
2. **Critical**: connect the SOT-223 thermal tab (pin 2) to a copper pour of at least 1 cm² connected to GND. Without this, you lose the thermal advantage. Skyway-96 PCB has this — open it as a reference.
3. Re-route VBUS (5 V from F1) to pin 3, +3V3 from pin 2 to the rest of the rail, GND from pin 1 to the GND pour.

### 3c. DRC
`Inspect → Design Rules Checker`. Fix any clearance / unconnected-net errors.

## Step 4 — Verify before manufacture

Before sending Gerbers to JLCPCB:

- [ ] Print 1:1 PDF of PCB (`File → Print` → Scale 1:1) and lay the AMS1117 chip on top — pads should align
- [ ] BOM (`Tools → Generate Bill of Materials`) lists C6186 for U1, C15850 ×2 for new caps
- [ ] Net `+3V3` connects: U1 pin 2 → all RP2040 IOVDD pins → all decoupling caps
- [ ] Net `GND` connects: U1 pin 1 + tab → all RP2040 GND/EP → USB-C GND/shield
- [ ] Net `VBUS` (5V): USB-C VBUS pins → F1 → U1 pin 3 (NOT to anything else unless intended)
- [ ] Run ERC + DRC clean
- [ ] If you have a working Skyway-96 BOM file, diff your PS96 BOM against it — power section should now match

## Step 5 — Order
Generate JLCPCB output:
- `File → Plot` → Gerbers (use SKYWAY-96/PCB Order Guide.txt as reference for layer mapping)
- BOM CSV
- CPL/POS file
- Order with **SMT Assembly enabled** so they install AMS1117 + caps for you (manual rework on a SOT-223 is doable but unnecessary)

## Step 6 — Bring-up (when board arrives)

⚠ **Never plug into a computer first time.** Use a current-limited bench supply.

1. Bench supply: 5 V, current limit **200 mA**
2. Connect to USB-C VBUS + GND only (use a USB-C breakout, or carefully tack wires)
3. Power on. Idle current should be ~50 mA (RP2040 + small leakage)
4. If current pegs at 200 mA → short somewhere → kill power, recheck
5. If current is normal, touch U1 with finger after 30 s — should be barely warm (< 40 °C)
6. If LDO is OK, then plug into a computer USB and check for `RPI-RP2` mass-storage device (means RP2040 booted into bootloader)
7. Flash QMK, test matrix.

## Rollback
If anything goes wrong at the schematic-edit stage:
```
git restore PublicSecurity96/PublicSecurity96.kicad_sch PublicSecurity96/PublicSecurity96.kicad_pcb
```

## Reference files
- Working: `../SKYWAY-96/KiCAD Source Files/rivasmario 96% Hotswap Rp2040.kicad_sch`
- Working PCB: `../SKYWAY-96/KiCAD Source Files/rivasmario 96% Hotswap Rp2040.kicad_pcb`
- BOM template: `../SKYWAY-96/Manufacturing & Assembly Files/`
