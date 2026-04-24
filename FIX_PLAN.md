# PublicSecurity96 — Fix Plan (Heat / Burn Issue)

Symptoms (as built / received): board did not enumerate, a component on the power section heated up enough to **burn skin on contact**. Skyway-96 (same MCU, similar layout) worked first try.

## Root cause hypothesis — ranked

### #1 (most likely): undersized LDO + thermal disaster
PS96 uses **XC6206P (U1)** in **SOT-23-3**:
- Rated **150 mA max** continuous
- **No exposed pad / thermal tab** — SOT-23 θJA ≈ 250 °C/W
- At 5 V in / 3.3 V out, drop = 1.7 V
- 200 mA load → 0.34 W → ~85 °C rise above ambient → ~110 °C package
- 400 mA load → 0.68 W → ~170 °C rise → **>200 °C package = skin burn**

RP2040 cold-boot inrush + USB enumeration + any flash erase pulse can briefly exceed 150 mA. If the LDO enters thermal shutdown it oscillates (turn on → overcurrent → shutdown → cool → repeat), which is when chips get genuinely hot.

Skyway-96 uses **AMS1117-3.3** in **SOT-223** instead:
- Rated **1 A**
- Tab pad on pin 2 (GND) acts as heatsink
- θJA ≈ 60 °C/W with reasonable copper pour

### #2: footprint pin-mapping mismatch
PS96 schematic was copy-pasted from "60%_mini / 60% / alice / Macropad" projects (the symbol's `instances` block lists all 6 donor projects). If the original symbol assumed AMS1117 pinout (pin1=GND, pin2=VOUT, pin3=VIN) but the PCB footprint is XC6206 (pin1=VOUT, pin2=GND, pin3=VIN), then **VBUS feeds into the GND pin** = dead short through the LDO die = instant cook on power-up.

**Verify in KiCad:** open the PCB, click U1, check that the pad numbered 3 receives VBUS and pad 2 connects to GND. If pin1 is on VBUS = wrong, swap.

### #3: missing / wrong input + output capacitors
XC6206 datasheet requires:
- ≥ 0.1 µF input cap (between VIN and GND)
- ≥ 0.1 µF output cap (between VOUT and GND)

Without these, LDO can oscillate at MHz, dissipating its own switching loss as heat. **Verify both caps exist within ~3 mm of the LDO pins** in the PCB layout.

### #4: fuse rating wrong
F1 schematic value = literally just "Fuse" with no rating. JLCPCB part `C3035895` should be looked up — if it's a higher-rated fuse than the LDO can handle, the fuse won't trip during a short. Skyway-96 PCB Order Guide should be checked for what worked.

## Fix path — recommended

### Path A: minimum-touch (rework the existing PCB)
1. **Replace U1**: desolder XC6206, hand-solder an AMS1117-3.3 in its place. Footprints are different (SOT-23 vs SOT-223) — won't drop in. Use a small adapter PCB or reroute.
2. **Add bulk cap**: 10 µF 0805 across VBUS and GND, 10 µF across +3V3 and GND. Solder onto existing pads or tack to capacitor pads on RP2040.
3. **Verify with current-limited bench supply**: 5 V, 200 mA limit. If it pulls > 150 mA at idle, there's still a short somewhere.

### Path B: redesign (recommended — borrow Skyway-96 power section)
Copy the verified Skyway-96 power tree into PS96:
- AMS1117-3.3 (LCSC C6186) in SOT-223 — replaces U1
- 10 µF input + 10 µF output ceramic caps (LCSC C15850 0805)
- PRTR5V0U2X ESD diode (LCSC C16223) — replaces SRV05-4 (drop-in functionally, different footprint)
- USB-C with **5.1 kΩ pull-downs on CC1 and CC2 separately** (verify PS96 has both — single shared pull-down is a common bug)
- Polyfuse 500 mA hold / 1 A trip (e.g. LCSC C2685389)

### Path C: full RP2040-SMD redesign
Use the deltasplit75-rp2040 schematic as the template — same MCU, same flash, same proven power section. Just rebuild matrix on a fresh PCB.

## Verification checklist before powering it up again
- [ ] U1 footprint pin 3 = VBUS, pin 2 = GND (probed with multimeter on unpowered board)
- [ ] No continuity between VBUS and GND on USB-C connector pins
- [ ] No continuity between +3V3 and GND
- [ ] Crystal load caps present (12 MHz xtal needs ~15 pF each)
- [ ] USB CC1 and CC2 each have own 5.1 kΩ to GND (not shared)
- [ ] First power-on: bench supply, 5 V, **current limit 200 mA**. Idle should be ~50 mA. If LDO gets warm to touch (> 50 °C) within 30 s, kill power and re-diagnose.

## Differences vs Skyway-96 (working reference)

| Component | PS96 (broken) | Skyway-96 (works) |
|---|---|---|
| LDO | XC6206P SOT-23-3 (150 mA) | AMS1117-3.3 SOT-223 (1 A) |
| ESD | SRV05-4 | PRTR5V0U2X |
| Flash | (not visible in PS96 sch — verify) | W25Q128JVS |
| MCU | RP2040 | RP2040 |
| Schematic provenance | Copy-pasted from 6 unrelated projects | Purpose-built |

## Files
- PS96 schematic: `PublicSecurity96/PublicSecurity96.kicad_sch`
- Skyway reference: `../SKYWAY-96/KiCAD Source Files/rivasmario 96% Hotswap Rp2040.kicad_sch`
- RP2040 SMD blueprint: `../deltasplit75-rp2040/docs/RP2040_SMD_GUIDE.md`
