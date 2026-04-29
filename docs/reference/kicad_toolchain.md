# KiCad toolchain for DeltaSplit 75 rebuild

Install once; reuse for every future keyboard project.

## 1. KiCad 10.0.1 (released 2026-04-15)

Stable. All reference schematics here are KiCad 6/7 — KiCad 10 auto-upgrades on open.

## 2. Libraries — install via PCM (Plugin & Content Manager)

### marbastlib (upstream, **not** the NCKiser fork)

- URL: [github.com/ebastler/marbastlib](https://github.com/ebastler/marbastlib)
- Install: PCM → add repository OR manually symlink `ebastler_marbastlib/footprints/*.pretty` + `symbols/*.kicad_sym` into project `fp-lib-table` / `sym-lib-table`.
- Contents (upstream is richer than the NCKiser fork):
  - `marbastlib-mx.pretty` — MX + hotswap
  - `marbastlib-choc.pretty` — Kailh Choc low-profile
  - `marbastlib-he.pretty` — Hall Effect
  - `marbastlib-hitek.pretty` — Hi-Tek
  - `marbastlib-various.pretty` — USB-C (HRO M-14), ProMicro, encoders, nRF52840, mousebites
  - Matching `.kicad_sym` for each

### Keebio-Parts.pretty (from NCKiser fork)

- Local: `../../NCKiser_refs/Keebio-Parts.pretty/`
- Contents: ATMEGA32U4, ProMicro variants, **Crystal_SMD_3225-4pin** (exact crystal package our reference specifies), 0402/0603/0805 passives, audio jack, RJ-45.
- Add to `fp-lib-table`.

### KiCad 10 built-ins (for RP2040 specifically)

- Symbol: `MCU_RaspberryPi:RP2040`
- Footprint: `Package_DFN_QFN:QFN-56-1EP_7x7mm_P0.4mm_EP3.2x3.2mm`
- Crystal footprint: use Keebio-Parts `Crystal_SMD_3225-4pin_3.2x2.5mm.kicad_mod`
- USB-C: use `marbastlib-various/USB_C_Receptacle_HRO_TYPE-C-31-M-14.kicad_mod`
- ESD: `Package_TO_SOT_SMD:SOT-23-6`

## 3. KLE auto-placer — zykrah/kicad-kle-placer

- Source: [github.com/zykrah/kicad-kle-placer](https://github.com/zykrah/kicad-kle-placer)
- Local: `../../NCKiser_refs/kicad-kle-placer/`
- **Install via PCM**: Repository manager → paste `https://raw.githubusercontent.com/zykrah/zykrah-kicad-repository/main/repository.json` → install "KLE Placer" → Apply.
- What it does: reads a KLE JSON, auto-places matching switch/stab/diode footprints onto the PCB based on schematic reference order (SW1, SW2, ...).
- Also places diodes: check `Move Diodes` + `Move diodes based on first switch and diode`; place the first switch+diode pair manually, plugin replicates the offset to all others.

### Workflow for DeltaSplit 75

1. Finalize the schematic (86 switches named SW1–SW86 + matching D1–D86 diodes + stabilizers S7/S10/S25/…).
2. Open PCB editor; import netlist.
3. Place first switch + its diode exactly where you want them relative to each other.
4. Tools → External Plugins → KLE Placer.
5. Select `kle/deltasplit75_raw.json`.
6. Enable **Specific Reference Mode** if rotated keys are added (required for any non-zero rotation).
7. Run → all 86 switches + diodes + stabs snap into place on the 0.79375 mm grid.

### KLE label guidelines (for the placer)

- Label position **3** — multilayout index (for ANSI/ISO variants).
- Label position **4** — reference number (e.g. `1` means `SW1`). **Required** for Specific Reference Mode + rotated keys.
- Label position **5** — multilayout value.
- Label position **9** — `F` to flip stabilizer.
- Label position **10** — extra rotation in degrees (for north-facing keys etc.).

The current `kle/deltasplit75_raw.json` has none of these — add them before running the placer.

## 4. Reference schematic — calliah333 RP2040-Guide.pdf

- Source: [github.com/calliah333/RP2040-designguide](https://github.com/calliah333/RP2040-designguide)
- Local: `../../NCKiser_refs/rp2040_designguide/RP2040-Guide.pdf`
- See `rp2040_designguide_schematic.md` for a ref-designator breakdown of every component on the schematic.

## Install order (one-time)

1. Install KiCad 10.0.1.
2. Open PCM → add marbastlib repository, install.
3. PCM → add zykrah's repository (URL above), install KLE Placer.
4. Clone ebastler/marbastlib (done) and sym/fp-link it into our project.
5. Clone Keebio-Parts.pretty (done via NCKiser fork) and link.
