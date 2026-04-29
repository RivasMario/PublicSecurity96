# Noah Kiser reference repos

Cloned to sibling dir: `../../NCKiser_refs/` (not tracked in this repo — shared reference for all future keyboard builds).

Source: [github.com/NCKiser](https://github.com/NCKiser) (50 public repos as of 2026-04-20).

## What's here and why it matters

### Gold-standard template — `le_chiffre_keyboard_stm32`

Complete, modern keyboard project with the layout structure DeltaSplit 75 should mirror:

```
le_chiffre_keyboard_stm32/
├── kicad/pcb/
│   ├── key_matrix.kicad_sch          ← hierarchical schematic pattern
│   ├── library/
│   │   ├── MX_Alps_Hybrid.pretty/    ← 1U, 1.25U, 1.5U, 1.75U, 2U, 2.25U, 2.75U, 3U, 10U + vertical/reversed-stab variants
│   │   ├── modified_footprints.pretty/   (custom SK6812, rotary encoder, SPST)
│   │   └── 3d_models/                ← HRO TYPE-C-31-M-12.step, Kailh Hotswap.step, CherryMX.step, keycap .steps
│   └── config.kibot.yaml             ← CI config for auto-gerbers
├── case/                             ← STL for 3D print
├── documentation/                    ← auto-generated schematic PDF, Edge_Cuts.dxf, ibom.html, 3D step
├── firmware/                         ← prebuilt vial .bin
└── .github/workflows/kibot.yml       ← CI that rebuilds docs on push
```

**Action:** copy this directory skeleton when we start `pcb/kicad/` in Delta-Split-75.

### Raw tutorial artifact — `TKL_VIDEO`

Actual KiCad 7 project built live in Noah's TKL tutorial. Files: `TKL_Video.kicad_pcb`, `TKL_Video.kicad_sch`, `TKL_Video.kicad_pro`. Plus `TKL_Video-backups/` — 15+ incremental snapshots from 2023-05-23 → 2023-05-31 showing the exact sequence of design steps. **Open in KiCad and step through the backups in order to trace his workflow.**

### Footprint libraries

| Lib | Count | What |
|---|---|---|
| `marbastlib/marbastlib-mx.pretty` | 36 | MX switch + hotswap variants, all U widths |
| `marbastlib/marbastlib-choc.pretty` | 10 | Kailh Choc low-profile |
| `marbastlib/marbastlib-various.pretty` | 27 | USB-C (HRO TYPE-C-31-M-14), ProMicro, rotary encoders, nRF52840 modules, mousebites |
| `Keebio-Parts.pretty` | 20+ | ATMEGA32U4, ProMicro variants, crystals (3225 pkg — **exactly the 12MHz pkg our reference calls for**), 0402/0603/0805 passives |

**Action:** add these as KiCad project libraries. Neither has a direct **RP2040 QFN-56** footprint — use KiCad 10's built-in `MCU_RaspberryPi:RP2040` + `Package_DFN_QFN:QFN-56-1EP_7x7mm_P0.4mm_EP3.2x3.2mm`.

### Closest sibling board — `kiao`

STM32F072 in a Seeedstudio XIAO form factor. Relevant because it's a complete, compact MCU carrier with USB-C + decoupling + crystal — same class of design as an RP2040 carrier. Full KiCad project + production files (BOM, placement CSV, gerbers zip).

**Note:** NOT RP2040. Noah doesn't have a published RP2040 repo in the list. For the RP2040 reference design, fall back to the official Raspberry Pi RP2040 Minimal Design or the Pico schematic (both public) — then apply our `rp2040_keyboard_design.md` constants on top.

### Useful secondaries

- **`Monorail-Memoria`** — hotswap drop-in PCB with `rev 1.1/` and `rev 2.0/` side by side. Study the diff to learn what Noah changed in revision.
- **`Piggyback`** — 32u4 carrier that sits between switches. Same mechanical constraint DeltaSplit's seam switch imposes — study the board-outline + clearance tricks.
- **`le_chiffre_keyboard_stm32`** also has the cleanest `kibot.yml` — copy for CI.

## Reuse plan for DeltaSplit 75 RP2040 rebuild

1. **Structure**: clone `le_chiffre_keyboard_stm32`'s directory tree under our `pcb/kicad/`.
2. **Libraries**: symlink or vendor `marbastlib-mx.pretty` + `Keebio-Parts.pretty` + `le_chiffre .../MX_Alps_Hybrid.pretty` into `pcb/kicad/library/`.
3. **Schematic scaffold**: start from `TKL_Video.kicad_sch` (open in KiCad 10 — it'll auto-upgrade from 7). Strip the TKL-specific 87 switches, replace matrix block with the DeltaSplit 86-key grid.
4. **RP2040 block**: use KiCad 10 built-in symbols + `docs/reference/rp2040_keyboard_design.md` constants for passive values.
5. **CI**: copy `le_chiffre .../kibot.yml` to `.github/workflows/` once the KiCad project compiles.

## License note

All NCKiser repos are permissively licensed (check individual LICENSE files — `le_chiffre` is GPL v2, `marbastlib` has its own terms). Any vendored footprints must preserve their license headers.
