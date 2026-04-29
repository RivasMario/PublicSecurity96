# RP2040 Keyboard PCB Design — Reference

Source: Gemini extraction of Noah Kiser's RP2040 hotswap keyboard build videos. Target KiCad ≥ 10.0.1 (2026-04-15). Use this as the schematic + layout scaffold for the DeltaSplit 75 v3 / RP2040 upgrade.

---

## 1. MCU — RP2040 power + peripheral baseline

### Power delivery

| Block | Part | Detail |
|---|---|---|
| USB-C receptacle | HRO TYPE-C-31-M-12 (or equiv) | CC1 + CC2 each pulled to GND via **5.1 kΩ 0402** (power negotiation) |
| ESD protection | SRV05-4 diode array | On D+/D−; routable footprint lets diff pair pass through IC center |
| Inrush protection | 500 mA PTC fuse | On VBUS before LDO |
| 3V3 LDO | XC6206 (or equiv) | VBUS → 3V3 |
| LDO decoupling | 1 µF in, 1 µF out | |
| RP2040 bulk | 10 µF | On 3V3 main input |
| RP2040 per-pin | 100 nF | Physically close to **every** 3V3 pin |
| Internal 1.1V reg | 1 µF | Dedicated |

### High-speed peripherals

| Block | Requirements |
|---|---|
| **QSPI flash** | W25Q128 (or equiv). 6 signals: CS, CLK, IO0–IO3. Direct pin-to-pin match to MCU. |
| **Oscillator** | 12 MHz SMD 3225 crystal → XIN/XOUT. **1 kΩ inline on XOUT**. 22 pF load caps on both lines, tied to GND plane. |
| **USB data** | **27 Ω series** on D+ and D−, placed immediately before MCU pins. |

---

## 2. Switch matrix footprint rules

- **Per-switch diode**: SOD-123 SMD, one per key, column → row direction (anti-ghost).
- **Diode placement**: bottom copper, physically between the large central mounting-pin hole and the two small switch contact holes. Saves space, enables cleaner trace routing.
- **CAD grid**: **0.79375 mm** (= 19.05 mm ÷ 24). This is the only grid on which 1U, 1.25U, 1.5U, 1.75U, 2.25U, 2.75U all land on exact fractions. Snap everything to it.

---

## 3. Multi-layout collision rules

Critical for DeltaSplit 75 since the KLE has a detachable seam switch and the plate variants support MX / ALPS / ALPS+MX / Costars.

### Soldered boards
- Multiple physical layouts can share one PCB with minimal issues — metal pins drop into shared holes.
- Minor pad vs stabilizer-screw conflict? **Rotate switch 180°** to resolve.

### Hotswap boards (DeltaSplit RP2040 target)
- Kailh hotswap sockets protrude horizontally off the back. Overlap with stab screw holes is common when supporting two layouts (e.g. ANSI Enter + ISO 1U).
- **90° rotation is forbidden.** MX stem cross is asymmetric (horizontal bar is thicker) — a 90°-rotated switch distorts keycaps.
- Resolution order:
  1. Drop screw-in stab support for the conflicting keys → force plate-mount stabs.
  2. If that's not enough, fork to separate Gerber sets per layout (e.g. ANSI-only vs ISO-only).

---

## 4. Trace routing hierarchy

Priority order for router / manual-routing:

1. **USB D+ / D−** — differential pair, side-by-side, **single layer, no vias**. Match length by routing.
2. **Crystal lines** — orient crystal at **45° to the MCU** so XIN/XOUT are inherently length-matched and short. Keep over a solid ground plane.
3. **Power (VBUS, 3V3)** — thick net class, ≥ **0.3 mm**. VBUS especially.
4. **Matrix grid**:
   - **Columns → top copper, vertical**
   - **Rows → bottom copper, horizontal**
   - No signal-blocking crossovers.
5. **GND** — never a trace. Fill all remaining space on both layers with **copper pour tied to GND**. Stitch front ↔ back with **aggressive via pattern** across the board.

---

## 5. Apply to DeltaSplit 75 rebuild

Matching this reference against the existing DeltaSplit 75 gerbers + KLE:

- **86 switches** (KLE count) → 86 diodes, 1 matrix, split into two blocks if the spread-split mode needs independent wiring. More likely: one matrix, ribbon/flex cable across the seam for the spread variant. Confirm from gerbers.
- **Edge.Cuts** is ~322 × 120 mm (single board, not split electrically) → matches "one PCB, two mounting modes" read.
- **Controller section** on DeltaSplit V2 gerbers sits in the LEFT-top region (see silkscreen "split left-F.SilkS.gto"). RP2040 + USB-C + QSPI + crystal + LDO all need to fit there. Measure available area before committing.
- **Grid**: redo all switch placements on 0.79375 mm grid when re-entering in KiCad.
- **Seam switch**: wire as normal matrix key, but call out in README that the key is physically optional depending on case mode.

---

## 6. Next actions

- [ ] Create `pcb/kicad/` with a fresh KiCad 10 project.
- [ ] Import gerbers as reference layer (KiCad: File → Import → Gerber).
- [ ] Build schematic from this scaffold: RP2040 + QSPI + USB-C + LDO + crystal + 86× switch/diode.
- [ ] Derive key-position table from KLE → CSV → switch footprint placements on the 0.79375 grid.
- [ ] Route per hierarchy §4.
- [ ] Cross-check board outline against `case/` plate DXFs — mounting holes must match.
