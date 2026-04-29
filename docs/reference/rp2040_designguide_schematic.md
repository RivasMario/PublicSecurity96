# RP2040 Design Guide — canonical reference schematic

Source: [calliah333/RP2040-designguide](https://github.com/calliah333/RP2040-designguide) — `PCB/RP2040-Guide.pdf`. Mirrored at `../../NCKiser_refs/rp2040_designguide/RP2040-Guide.pdf`.

**What it is:** a **single-page KiCad 6.0.4 schematic** (dated 2021-12-07, "Sleepdealer" revision 0.1) that shows the complete canonical RP2040 implementation. Noah Kiser references this in the first video of his RP2040 keyboard series.

This schematic confirms every constant in `rp2040_keyboard_design.md` and adds a few:

## Reference designators from the PDF

| Ref | Part | Value |
|---|---|---|
| U3 | RP2040 QFN-56 | MCU |
| U1 | W25Q128JVSC | QSPI flash |
| U2 | USBLC6-2SC6 | USB ESD protection (alt to SRV05-4, same class) |
| U4 | XC6206PxxxMR | 3V3 LDO |
| J1 | HRO TYPE-C receptacle | USB_C_Receptacle_USB2.0 footprint |
| J2 | 1×4 header | SWD + 3V3 (SWCLK / SWDIO / GND / 3V3) |
| J3, J4, J5 | 1×11 headers | GPIO breakout expansion |
| Y1 | 12 MHz crystal | SMD 3225 |
| F1 | 500 mA PTC fuse | on VBUS |
| SW1 | SW_Push | USB_BOOT button, with R1 1k pulldown |

## Passive values (from the PDF)

| Ref | Value | Role |
|---|---|---|
| C1 | 100 nF | RP2040 3V3 decoupling |
| C2 | 1 µF | RP2040 internal 1V1 reg (VREG_VOUT) |
| C3, C17 | 22 pF | crystal load caps |
| C4 | 1 µF | (context-dependent decoupling) |
| C5 | 1 µF | LDO output |
| C6 | 100 nF | QSPI flash decoupling |
| C7 | 10 µF | main 3V3 bulk |
| C8 | 1 µF | |
| C9 | 100 nF | 3V3 decoupling |
| C10–C15 | 100 nF each | per-3V3-pin decoupling |
| C16 | 1 µF | LDO input |
| R1 | 1 kΩ | USB_BOOT button pulldown |
| R2 | 1 kΩ | (likely reset pull) |
| R3, R4 | **5.1 kΩ** | **CC1 / CC2 pulldowns** |
| R5, R6 | **27 Ω** | **USB D+/D− series** |
| R7 | 1 kΩ | **inline on XOUT** |

## Additions over the Gemini summary

1. **SWD header** (J2, 1×4) — call out in the schematic for debugger access. Pinout: SWCLK / SWDIO / GND / 3V3.
2. **USB_BOOT button** — SW_Push + R1 1kΩ pulldown on GPIO… (check silkscreen). Required to put the chip in bootsel mode without pulling DVDD. Include in any keyboard build even if hidden under the case.
3. **USB-C footprint name** — `USB_C_Receptacle_USB2.0` (standard KiCad symbol). USB 2.0-only, SBU1/SBU2 unused.
4. **ESD part** — `USBLC6-2SC6` is what calliah333 picked; interchangeable with SRV05-4. Both in SOT23-6.
5. **GPIO breakouts** — 3× 1×11 headers (J3, J4, J5) expose all user GPIO. Not needed in a keyboard, but useful for prototyping.

## Apply to DeltaSplit 75 rebuild

Use this PDF as the schematic sheet layout. In KiCad 10, open the PDF side-by-side with the schematic editor and replicate component placement + net names. Then attach the 86-switch matrix sheet (hierarchical) that scans columns → rows through RP2040 GPIO.

**BOM order (suggested source):** LCSC for all parts — they stock every P/N in the PDF.
