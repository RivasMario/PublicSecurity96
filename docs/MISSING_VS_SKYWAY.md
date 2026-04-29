# PublicSecurity96 — Missing vs SKYWAY-96 (working reference)

Audit of `PublicSecurity96.kicad_sch` against SKYWAY-96 working PCB and Noah Kiser's RP2040 keyboard standards (`docs/reference/rp2040_keyboard_design.md`, `rp2040_designguide_schematic.md`). Companion to `FIX_PLAN.md` and `REWORK_INSTRUCTIONS.md`.

## TL;DR
PS96 has at least one fatal bug (wrong crystal frequency) plus several Kiser-standard omissions. Even after the U1 LDO swap from `FIX_PLAN.md`, the board would still not enumerate over USB.

---

## Critical (board cannot work)

### 1. Crystal frequency wrong
- **Schematic Value**: `16MHz` (line 18280)
- **Schematic Comment**: `8MHz 12pF ±10ppm SMD3225-4P` (line 18334)
- **JLCPCB part**: `C524715`
- **Required**: **12 MHz** SMD 3225, 22 pF load caps (already present)
- **Why**: RP2040 boot ROM hardcodes a 12 MHz reference for the USB PLL. Any other frequency means USB never enumerates and `RPI-RP2` mass-storage device never appears. SKYWAY-96 uses 12 MHz. Kiser §1 specifies 12 MHz SMD 3225.
- **Fix**: change Value + Comment to `12MHz`. **Verify JLCPCB part number** points at a 12 MHz 3225 4-pin crystal (existing `C524715` may be wrong — re-source from JLCPCB parts library if so).

### 2. U1 LDO mismatch (in progress)
- **Current**: `XC6206PxxxMR` (SOT-23-3, 150 mA, no thermal tab) — line 21237
- **Required**: `AMS1117-3.3` (SOT-223, 1 A, GND tab) — Skyway-96 part
- **Why**: see `FIX_PLAN.md` root cause #1 — XC6206 thermally collapses on RP2040 inrush. Burns skin.
- **Status**: commit `3aa170e` says "wip: U1 swap XC6206->AMS1117". Verify in KiCad that placed instance actually swapped (not just symbol library entry). Pinout differs:
  - XC6206: 1=VOUT, 2=GND, 3=VIN
  - AMS1117: 1=GND, 2=VOUT, 3=VIN
- **Fix path**: `REWORK_INSTRUCTIONS.md §2a`. Cannot be safely text-edited because wires would land on wrong pins.

### 3. Fuse F1 has no rating
- **Current**: Value `"Fuse"`, JLCPCB `C3035895`, Comment `"6V 500mA 100mA 1A"` (jumbled)
- **Required**: 500 mA hold / 1 A trip PTC polyfuse (Kiser §1, REWORK §2c)
- **Suggested**: LCSC `C2685389` 1206 polyfuse
- **Why**: undefined fuse means the LDO can cook before the fuse trips on a fault.

---

## Likely missing (need to verify in KiCad GUI)

### 4. USB D+/D- 27 Ω series resistors
- **PS96**: no `27R` series resistors found near MCU pins 46/47.
- **Required**: 2× 27 Ω 0402, placed **immediately before** RP2040 D+/D- pins (Kiser §1, calliah333 designguide R5/R6).
- **Why**: USB 2.0 impedance match. Without these, signal integrity is marginal — board may enumerate intermittently.

### 5. 1 kΩ inline on XOUT
- **PS96**: not found.
- **Required**: 1 kΩ resistor between RP2040 pin 21 (XOUT) and crystal pin 3 (Kiser §1, calliah333 R7).
- **Why**: dampens crystal drive level; without it the crystal can over-drive and stop oscillating reliably.

### 6. PWR_FLAG symbols (ERC)
- **PS96**: none found.
- **Required**: 3× `power:PWR_FLAG` — one each on `+5V` (USB-C VBUS), `+3V3` (LDO output), `GND`.
- **Why**: KiCad ERC complains "Input Power pin not driven by Output Power pin" because power enters from outside. Without PWR_FLAG you cannot get a clean ERC, so other real errors get hidden.

### 7. Per-pin 100 nF on every IOVDD
- **RP2040 IOVDD pins**: 1, 10, 22, 33, 42, 49 (6 total) — visible at lines 1732, 1895, 2112, 2311, 2474, 2601.
- **Required**: 6× 100 nF 0402 X7R, each within ~3 mm of its IOVDD pin.
- **Status**: schematic has decoupling caps but count + placement need verification.

### 8. VREG_VOUT (1.1 V) decoupling
- **RP2040 pin**: 44 → `VREG_VOUT` (line 2528)
- **Required**: 1 µF to GND, single cap, close to pin.
- **PS96**: `+1V1` net exists (line 26135) — verify the cap is actually placed on it.

---

## Layout-side (PCB editor — not in schematic)

After all schematic fixes are merged via `Tools → Update PCB from Schematic`:

| Check | Required by | Notes |
|---|---|---|
| AMS1117 thermal tab → ≥1 cm² GND copper pour | Skyway-96 pattern | Without this, AMS1117 still overheats. REWORK §3b. |
| Crystal at 45° to MCU, traces <10 mm, GND guard | Kiser §4 | Auto length-matches XIN/XOUT. |
| USB D+/D- as differential pair, single layer, no vias | Kiser §4 | Length-matched within 0.5 mm. |
| GND copper pour both layers + stitched vias | Kiser §4 | "GND is never a trace." |
| BOOTSEL switch pulls QSPI_SS to GND, no series resistor | NETLIST.md (deltasplit) | RP2040 boot mode prerequisite. |
| First power-up on bench supply, 5 V / 200 mA limit | REWORK §6 | Idle should be ~50 mA. |

---

## Already correct (don't touch)

- 5.1 kΩ on **both** CC1 and CC2 separately (lines 13941, 16202) — common bug avoided.
- 22 pF crystal load caps (line 22336) — correct for 12 MHz / CL≈12 pF crystal.
- SRV05-4 ESD on D+/D- — Kiser-equivalent to PRTR5V0U2X / USBLC6.
- MX25 series QSPI flash (line 33671) — same class as Skyway's W25Q128, pin-compatible.
- `+1V1` power net for VREG_VOUT.
- Most RP2040 IOVDD pins exposed for decoupling.

---

## Recommended fix order
1. Crystal `16MHz/8MHz` → `12MHz` + verify JLCPCB part number. **(safe text edit — done)**
2. F1 fuse Value `Fuse` → `500mA polyfuse`. **(safe text edit — done)**
3. Finish U1 LDO swap in KiCad GUI per REWORK §2a (cannot text-edit safely).
4. Add 2× 27 Ω D+/D- series in KiCad GUI.
5. Add 1 kΩ XOUT in KiCad GUI.
6. Drop 3× PWR_FLAG in KiCad GUI.
7. Verify 6× 100 nF per IOVDD + 1× 1 µF on +1V1.
8. PCB: AMS1117 thermal pour, crystal 45°, USB diff pair, GND stitching.
9. Bench supply bring-up before plugging into a real USB host.

## Reference files
- Working: `../SKYWAY-96/KiCAD Source Files/rivasmario 96% Hotswap Rp2040.kicad_sch`
- Kiser standards: `docs/reference/rp2040_keyboard_design.md`, `rp2040_designguide_schematic.md`
- Toolchain: `docs/reference/kicad_toolchain.md`
- Repo catalog: `docs/reference/nckiser_repos.md`
