# PublicSecurity96 — Beginner KiCad Walkthrough

This guide assumes you have **never used KiCad** or have only opened it a couple of times. Every click is described. Read top to bottom; do not skip parts.

If anything goes wrong, see **Part 13 — Recovery**. You can always `Ctrl+Z` (undo) and `git restore .` to roll back.

---

## What you are doing (in plain English)

The PublicSecurity96 board is broken. The reasons are documented in `FIX_PLAN.md` and `MISSING_VS_SKYWAY.md`. Your job here is to use KiCad to:

1. Replace one part on the schematic (the LDO voltage regulator).
2. Add a few small parts that were missing (resistors, power flags, capacitors).
3. Update the physical PCB to match.
4. Run two automated checks (ERC and DRC) that catch wiring mistakes.
5. Generate the files you send to JLCPCB to fabricate a new board.

**Time estimate:** 2–4 hours the first time, including reading.

---

## Part 0 — Install and open the project

### 0.1 Install KiCad
Download KiCad 8 (or KiCad 10 if available) from https://www.kicad.org/download/. On Windows, run the installer with defaults. After install, KiCad adds itself to your Start menu as **"KiCad 8.0"** (the number is the version).

### 0.2 Open the project
1. Launch **KiCad 8.0** from Start menu. The first window that opens is called the **KiCad project manager** — it is *not* the schematic editor.
2. In project manager: **File → Open Project…**
3. Navigate to:
   `C:\Users\v-mariorivas\OneDrive - Microsoft\Documents\GitHub\PublicSecurity96\PublicSecurity96\`
4. Select **`PublicSecurity96.kicad_pro`** and click **Open**.
5. The project manager now lists files on the left. The two you care about are:
   - `PublicSecurity96.kicad_sch` — the schematic (wiring diagram).
   - `PublicSecurity96.kicad_pcb` — the PCB (the physical board layout).

### 0.3 Open the schematic editor
**Double-click `PublicSecurity96.kicad_sch`** in the file list. A new window opens called **"Schematic Editor"** (also called "Eeschema" — same thing). This is where you'll do Parts 1–6.

> If KiCad complains about missing libraries or symbols on opening, click **Cancel** or **Ignore** on each warning. The project will still open. The schematic will display.

### 0.4 Get oriented in the Schematic Editor

Look at the screen. You should see:
- **Top:** menu bar (File, Edit, View, Place, Inspect, Tools, Preferences, Help).
- **Just below menu:** two rows of toolbar buttons (icons).
- **Left side:** narrow column of icons — selection mode tools.
- **Right side:** a narrow column of icons — placement tools (this is where Add Symbol, Add Wire, Add Power Port etc. live).
- **Center:** the schematic itself — a sheet of components and wires. You may see one main sheet titled something like "Hotswap Switch Matrix" or "Top". If a hierarchy is set up, double-click rectangular sheet symbols to drill into sub-sheets.

### 0.5 Pan and zoom

- **Zoom in/out:** scroll the mouse wheel.
- **Pan:** hold middle mouse button and drag, OR use arrow keys.
- **Zoom to fit:** press **`Home`** key. (Use this often — it shows the whole sheet.)
- **Zoom to selection:** press **`F1`**.

### 0.6 Save your work
At any point: **`Ctrl+S`** saves the schematic. Save after every section of this walkthrough. KiCad does not auto-save.

---

## Part 1 — Backup before you change anything

### 1.1 Confirm git branch
1. Open a terminal (Git Bash, PowerShell, or VS Code terminal).
2. `cd` into the project root:
   ```
   cd "C:\Users\v-mariorivas\OneDrive - Microsoft\Documents\GitHub\PublicSecurity96"
   ```
3. Run `git status`. Confirm it says **`On branch fix/power-section-skyway96-style`**. If it doesn't, stop and ask for help — you may be on the wrong branch.
4. Run `git status` once more. If anything is uncommitted that you didn't make, run `git stash` to save it aside.

### 1.2 Make a snapshot commit
Before editing in KiCad:
```
git add -A
git commit -m "snapshot before GUI fixes"
```
This way every step below is reversible with `git restore .`.

---

## Part 2 — Replace U1 (XC6206 → AMS1117-3.3)

This is the biggest single change. Do it slowly.

### 2.1 Find U1
1. In the Schematic Editor, press **`Ctrl+F`** (Find).
2. In the search box type `U1` and press Enter.
3. The view jumps to component **U1**. It is currently labeled `XC6206PxxxMR` (or similar) and looks like a small box with three pins.
4. Press **`Esc`** to close the search bar.

### 2.2 Read the existing wiring (so you know what's correct)
Hover the mouse over each of U1's three pins. The bottom status bar shows the **net name** for that pin — e.g. `+5V`, `GND`, `+3V3`. Write down on paper:
- U1 pin **1** = ___________
- U1 pin **2** = ___________
- U1 pin **3** = ___________

For XC6206 the typical mapping is:
- pin 1 = `+3V3` (output)
- pin 2 = `GND`
- pin 3 = `+5V` / VBUS (input)

### 2.3 Open the Change Symbol dialog
1. **Right-click** anywhere on U1 (the body, not the wires).
2. In the popup menu choose **Change Symbol…** (it may be near the bottom of the menu, or under a sub-menu called "Properties" or "Change").
3. A dialog appears titled **"Change Symbols"**.

### 2.4 Pick the new symbol
1. In the dialog, set **"Change symbols matching reference designator"** = `U1`.
2. Below, find the **"New library identifier"** field. Click the small folder/browse icon next to it.
3. Another window opens: the **Symbol Picker**. On the left is a tree of libraries.
4. In the search bar at the top of the symbol picker, type: `AMS1117-3.3`.
5. Pick the result that says **`Regulator_Linear:AMS1117-3.3`**. The right-hand panel previews the symbol — it should show 3 pins labeled GND (pin 1), VOUT (pin 2), VIN (pin 3).
6. Click **OK**.
7. Back in the Change Symbols dialog, leave default options checked for "Update field text" and "Update properties". Click **Apply**, then **Close**.

### 2.5 Read what KiCad did to the wires
The placed U1 symbol now looks different (3 pins but with new labels: GND/VOUT/VIN). KiCad tries to keep wires attached to the same physical pin numbers. **This is a problem** because the pin *numbers* are the same (1, 2, 3) but the *functions* moved:

| Pin | XC6206 (old) | AMS1117 (new) |
|-----|-------------|---------------|
| 1   | VOUT        | **GND**       |
| 2   | GND         | **VOUT**      |
| 3   | VIN         | VIN           |

So:
- The wire that was on `+3V3` (correct for XC6206 pin 1 = VOUT) is now on AMS1117 pin 1, **which is GND**. **WRONG — must move.**
- The wire that was on `GND` (correct for XC6206 pin 2 = GND) is now on AMS1117 pin 2, **which is VOUT**. **WRONG — must move.**
- The wire on pin 3 was VIN, still VIN. **OK.**

### 2.6 Fix the wires (this is the careful part)
You need to **swap the wires on pins 1 and 2**.

Easiest method:
1. Hover the wire connected to U1 pin 1 (the `+3V3` wire). Press **`M`** (move). Drag it to pin 2.
2. The wire endpoint will follow your cursor. Click to drop it on AMS1117 pin 2 (VOUT).
3. Now hover the wire on U1 pin 2 (the `GND` wire). Press **`M`**, drag to pin 1, click.
4. Both wires are now on the correct pins.
5. Hover each pin and confirm the bottom status bar shows the right net:
   - pin 1 = `GND`
   - pin 2 = `+3V3`
   - pin 3 = `+5V`

If the bottom bar shows nothing or `<no net>`, the wire is **not actually touching the pin**. Press **`M`** again and nudge the wire endpoint until it snaps to the pin (you'll see a small green dot or square at the connection point).

### 2.7 Set the AMS1117 footprint and JLCPCB part
1. Hover U1, press **`E`** (edit properties). The Symbol Properties dialog opens.
2. Find the **Footprint** field. Click the small folder/browse icon.
3. In the Footprint Picker, search for: `SOT-223-3_TabPin2`.
4. Pick `Package_TO_SOT_SMD:SOT-223-3_TabPin2`. Click **OK**.
5. Back in Symbol Properties, look for a custom field named **`JLCPCB part#`** (it may be at the bottom of the field list).
   - If it exists, set its value to **`C6186`**.
   - If it doesn't exist, click **`+`** below the field list to add a new field. Name it `JLCPCB part#`, value `C6186`, leave other settings default.
6. Click **OK**.

### 2.8 Save and run ERC
1. **`Ctrl+S`** to save the schematic.
2. **Inspect → Electrical Rules Checker**.
3. In the ERC dialog, click **Run ERC**.
4. The dialog shows a list of errors and warnings. Look at each one:
   - "Pin not connected" on U1 → means a wire isn't touching a pin. Go back to 2.6 and fix.
   - "Conflict between net X and Y" on U1 → means a wire is on the wrong pin. Go back to 2.6.
   - "Power input pin not driven by Power output pin" → expected. Will be fixed in Part 5 (PWR_FLAG).
5. Close ERC dialog when U1 is clean (or only the PWR_FLAG warning remains for U1).

### 2.9 Commit progress
In your terminal:
```
git add -A
git commit -m "kicad: swap U1 XC6206 -> AMS1117-3.3 (SOT-223 + C6186)"
```

---

## Part 3 — Add 27 Ω resistors on USB D+ / D−

You'll add two resistors inline on the USB data lines, between the SRV05-4 ESD chip and the RP2040 microcontroller.

### 3.1 Find the USB section
1. **`Ctrl+F`** → search `USB_DP` (or `D+`) → Enter. View jumps to the wire labeled USB_DP.
2. Look around: you'll see the USB-C connector (refdes `J1` or similar), the SRV05-4 ESD chip (`U2` probably), and a long wire heading toward the RP2040 with a label `USB_DP` (and parallel `USB_DM` for D-).

### 3.2 Place the first resistor (R20, 27 Ω)
1. Press **`A`** (add symbol). The Symbol Picker opens.
2. Search: `R` → pick **`Device:R`** (a plain resistor symbol). Click **OK**.
3. The cursor now carries a "ghost" resistor. Click on a clean spot near the D+ wire, between the SRV05-4 and the RP2040, to drop it.
4. Press **`R`** to rotate it 90° if it's vertical and you need horizontal (or vice versa). Press `Esc` to stop placing more.

### 3.3 Configure the resistor properties
1. Hover the new resistor → press **`E`**.
2. In Symbol Properties:
   - **Reference**: KiCad will have auto-assigned something like `R?` or `R20`. If it's `R?`, type a real refdes. To find a free number, look at your schematic and pick the next free `R` — most likely `R20`. (Or run **Tools → Annotate Schematic** later, which auto-numbers all `R?`.)
   - **Value**: type `27R` (or `27`).
   - **Footprint**: browse → `Resistor_SMD:R_0402_1005Metric`.
   - **JLCPCB part#**: add field if missing, value `C25092`.
3. Click **OK**.

### 3.4 Splice it into the D+ trace
The resistor is sitting *next to* the wire, not *in* it. You need to break the wire and reroute through the resistor.

1. Hover the existing D+ wire (the long line between SRV05-4 and RP2040).
2. Click once to select it. The wire highlights.
3. Press **`Delete`**. The wire vanishes — now there's a gap.
4. Drag the new resistor (press **`M`**, click new location) so its two pads sit roughly between the gap endpoints — i.e. the resistor is now where a piece of the wire used to be.
5. Press **`W`** (add wire). Click on the SRV05-4 D+ pin → click on R20 left pad. A wire appears connecting them. Press `Esc`.
6. Press **`W`** again. Click R20 right pad → click on the RP2040 USB_DP pin (or the existing wire stub leading to it). Press `Esc`.
7. Hover each new wire — the bottom status bar should still say `USB_DP` or `Net-USB_DP` or similar. If it splits into two different net names, you have a wiring break — `Ctrl+Z` and try again.

### 3.5 Add the second resistor (R21) for D−
Repeat 3.2–3.4 for the D− line. Use refdes `R21`, same value `27R`, same footprint, same JLCPCB part `C25092`. Splice it inline on the D− wire between SRV05-4 and RP2040 USB_DM pin.

### 3.6 Save, ERC, commit
```
Ctrl+S
Inspect → Electrical Rules Checker → Run ERC
```
Fix any new "unconnected pin" errors first. Then:
```
git add -A
git commit -m "kicad: add 27R series on USB D+/D- (R20, R21)"
```

---

## Part 4 — Add 1 kΩ on XOUT (crystal damping)

### 4.1 Find the crystal
**`Ctrl+F`** → search `Y1`. View jumps to the 12 MHz crystal (it should now read `12MHz` after our earlier text edit). The crystal has 4 pins (XIN, GND, XOUT, GND).

### 4.2 Identify the XOUT trace
- Crystal pin **1** = XIN (connects to RP2040 pin 20).
- Crystal pin **3** = XOUT (connects to RP2040 pin 21).
- Pins **2 and 4** = GND.

Hover each pin to confirm with the status bar. The XOUT wire goes from crystal pin 3 to RP2040 pin 21.

### 4.3 Place R22 (1 kΩ)
1. **`A`** → search `R` → `Device:R` → OK.
2. Click to drop near the XOUT trace.
3. Hover → **`E`**:
   - Reference: `R22`
   - Value: `1k`
   - Footprint: `Resistor_SMD:R_0402_1005Metric`
   - JLCPCB part#: `C11702`

### 4.4 Splice into the XOUT trace
Same pattern as Part 3.4: select XOUT wire → Delete → place R22 in the gap → press `W` → wire crystal pin 3 to R22 left pad → wire R22 right pad to RP2040 pin 21.

> Important: the **22 pF load capacitor** that goes from XOUT to GND should connect on the **crystal side of R22** (between crystal pin 3 and R22 left pad), not on the RP2040 side. If the existing cap is on the RP2040 side, move it: hover cap → `M` → drop on the crystal-side wire.

### 4.5 Save, ERC, commit
```
Ctrl+S
git add -A
git commit -m "kicad: add 1k on XOUT (R22) for crystal damping"
```

---

## Part 5 — Add PWR_FLAG × 3

PWR_FLAG is a special symbol that tells the ERC engine "this net is powered from outside the schematic, not driven by another component." Without it, ERC can't tell the difference between a real disconnected power net and a normal external supply.

### 5.1 Place the first PWR_FLAG (on +5V / VBUS)
1. **`Ctrl+F`** → search `+5V` (or `VBUS`). Find a wire on that net, ideally near the USB-C connector.
2. **`A`** → search `PWR_FLAG` → pick **`power:PWR_FLAG`** → OK.
3. Click to drop the symbol close to the +5V wire. Press `Esc`.
4. Press **`W`** → click the PWR_FLAG arrow tip → click the +5V wire to connect them. Press `Esc`.
5. Hover the new connection. Status bar should say `+5V` (or `VBUS` — match whatever the existing label was).

### 5.2 Place the second PWR_FLAG (on +3V3)
1. Find a +3V3 wire, ideally near U1 pin 2 (the AMS1117 output).
2. Same as 5.1, with the connection on +3V3.

### 5.3 Place the third PWR_FLAG (on GND)
1. Find any GND wire. Easy spots: USB-C GND pin, U1 pin 1, or any decoupling cap's GND side.
2. Same as 5.1, with the connection on GND.

### 5.4 Save, ERC
**`Ctrl+S`** → **Inspect → Electrical Rules Checker → Run ERC**.

The "Power input pin not driven by Power output pin" warnings on every power net should now be **gone**. Any remaining errors are real wiring problems — fix them before continuing.

### 5.5 Commit
```
git add -A
git commit -m "kicad: add 3x PWR_FLAG (+5V, +3V3, GND) for clean ERC"
```

---

## Part 6 — Verify IOVDD decoupling

The RP2040 has 6 IOVDD pins (1, 10, 22, 33, 42, 49). Each needs its own 100 nF cap to GND, placed within ~3 mm of the pin on the PCB. The schematic must reflect 6 caps total.

### 6.1 Count existing 100 nF caps near RP2040
1. **`Ctrl+F`** → search `100nF`. Step through the matches with `F3` (find next).
2. For each cap found, hover and verify:
   - One pad is on `+3V3` net.
   - Other pad is on `GND`.
   - The `+3V3` side electrically connects (visible wire) to one of the 6 IOVDD pins (or close to it).
3. Tally how many decoupling caps exist for the RP2040. You need **6 total** for IOVDD.

### 6.2 Add any missing caps
For each missing IOVDD pin:
1. **`A`** → search `C` → pick **`Device:C`** → OK.
2. Click to drop near the missing IOVDD pin.
3. Hover → **`E`**:
   - Reference: next free `C` number (e.g. `C30`).
   - Value: `100nF`.
   - Footprint: `Capacitor_SMD:C_0402_1005Metric`.
   - JLCPCB part#: `C1525`.
4. Press **`W`** → wire one cap pad to `+3V3` (use a power port: **`P`** → pick `power:+3V3`), other pad to GND (**`P`** → `power:GND`).

### 6.3 Verify the +1V1 / VREG_VOUT cap
1. **`Ctrl+F`** → search `+1V1` or `VREG_VOUT`.
2. There should be a 1 µF cap from `+1V1` to GND.
3. If missing: same procedure, value `1uF`, footprint `Capacitor_SMD:C_0402_1005Metric`, JLCPCB `C15849`.

### 6.4 Save, ERC, commit
```
Ctrl+S
Inspect → ERC → Run ERC   (should be clean)
git add -A
git commit -m "kicad: verify+complete RP2040 IOVDD/VREG_VOUT decoupling"
```

---

## Part 7 — Push schematic changes to the PCB

Up to now you've only edited the schematic. The physical board (PCB) doesn't know about the new parts yet.

### 7.1 Update PCB from Schematic
1. Still in the Schematic Editor: **Tools → Update PCB from Schematic** (or press **`F8`**).
2. A dialog opens listing every change: "Add R20", "Change U1 footprint", etc.
3. Read through. If something says "Delete" for a part you didn't expect, **stop** and re-check your schematic.
4. Click **Update PCB**.
5. The PCB Editor (also called **pcbnew**) opens automatically with the new footprints **floating outside the board outline**.

### 7.2 First look at pcbnew
- The PCB editor has a similar layout: menus on top, toolbar, side panels.
- The **board outline** (the gray rectangle = your physical board edge) is on the `Edge.Cuts` layer.
- Layers panel on the right: **F.Cu** = front copper, **B.Cu** = back copper. Click a layer to make it active.
- Existing parts are placed; new parts (your additions) are loose, near the cursor when you opened pcbnew.

---

## Part 8 — Place the new parts on the PCB

### 8.1 Find the new footprints
They are clustered together off the side of the board. Press **`Home`** to zoom to fit. Look for:
- **U1** = SOT-223 (medium rectangle with a tab) if it didn't replace the old SOT-23.
- **R20, R21, R22** = small rectangles (0402 — about 1×0.5 mm).
- **PWR_FLAG** symbols don't appear on the PCB (schematic-only).
- New caps if you added any.

### 8.2 Move parts onto the board
For each new part:
1. Hover the part → press **`M`** (move).
2. Drag to its target location:
   - **U1 (AMS1117)**: where the old XC6206 was — should already be there post-update. Confirm.
   - **R20, R21**: each near the RP2040 USB pins (D+/D−), as close to the chip as possible.
   - **R22**: between Y1 (crystal) and RP2040 pin 21 (XOUT).
   - **New caps**: each within 3 mm of its target IOVDD pin on the RP2040.
3. Press **`R`** to rotate if needed. Click to drop.

### 8.3 Route any broken or new traces
After moving parts, some traces may show as light blue "ratsnest" lines (unrouted connections):
1. Switch to top copper: click `F.Cu` in the layer panel.
2. Press **`X`** (route track). Click the start pad → click the end pad to route.
3. Press `Esc` when done.
4. Repeat for each ratsnest line.

> If you find this overwhelming: leave routing for last. Place all parts first; then route everything in one pass.

---

## Part 9 — AMS1117 thermal pour (critical for not burning out U1)

The AMS1117 dissipates heat through its center tab (pin 2 = GND). Without a copper "thermal pour" connected to that tab, the chip overheats just like the XC6206 did.

### 9.1 Verify pin 2 is GND
Click U1. The pads highlight. Hover pin 2 (the big tab pad). Status bar must say `GND`. If not — go back to Part 2 and re-check the schematic.

### 9.2 Add a filled zone (copper pour)
1. Click the bottom copper layer: `B.Cu` in the layer panel.
2. **Place → Add Filled Zone** (or press **`Ctrl+Shift+Z`**).
3. The cursor changes; a Zone Properties dialog appears immediately as you click the first corner.
4. In Zone Properties:
   - **Net**: select `GND` from the dropdown.
   - **Layer**: `B.Cu` only.
   - **Clearance**: `0.2 mm`.
   - **Minimum width**: `0.25 mm`.
   - **Pad connections**: `Thermal reliefs` (default) is fine.
5. Click **OK**.
6. Now click 4 corners on the PCB to define a rectangle around U1 — at least **1 cm × 1 cm** (= 10 mm × 10 mm). Double-click to close.

### 9.3 Fill the zone
Press **`B`**. The zone fills with a solid hatched copper pattern. U1 pin 2 should now have small "thermal relief" spokes connecting it to the pour.

### 9.4 Add stitching vias around U1
Stitching vias tie the bottom GND pour to the top GND pour, helping with heat and EMI:
1. Press **`V`** (place via).
2. Click 6–10 spots in the GND pour around U1, spaced 2–3 mm apart.
3. Press `Esc` when done.

### 9.5 Re-fill and check
Press **`B`** again to refill zones with the new vias. Save with **`Ctrl+S`**.

---

## Part 10 — Crystal placement, USB diff pair, GND fill

### 10.1 Crystal at 45° to MCU
1. Click Y1 (the crystal). Press **`R`** to rotate. Try each 90° step until the XIN/XOUT pins point diagonally toward RP2040 pins 20/21.
2. Press **`M`** to move. Position so the trace lengths from Y1 pins 1 and 3 to RP2040 pins 20 and 21 are short (< 10 mm) and roughly equal.
3. The 22 pF load caps should sit close to the crystal pins, with their GND pads connecting straight to the GND pour.

### 10.2 USB D+/D− differential pair
1. Click an existing D+ trace.
2. **Route → Tune Differential Pair Skew/Phase** (or via the right-click route menu).
3. KiCad guides you: the goal is **D+ and D− trace lengths within 0.5 mm of each other**, **single layer (top, F.Cu)**, **no vias**.
4. If your existing D+/D− have vias, delete the vias and re-route on F.Cu.

### 10.3 GND pour both layers
1. Confirm two GND zones exist (one on F.Cu, one on B.Cu) covering the whole board:
   - Click an empty area on F.Cu. If a zone exists, it highlights.
   - Repeat on B.Cu.
2. If a zone is missing: repeat 9.2–9.3 for that layer, but draw the zone over the **entire board** instead of just around U1.
3. Add stitching vias all over the board (especially along USB-C trace edges and around the crystal). Press `V`, click many spots. Aim for a via every ~5 mm.
4. **`B`** to refill zones.

### 10.4 Save and commit
```
Ctrl+S
git add -A
git commit -m "kicad: PCB - thermal pour, crystal 45deg, USB diff pair, GND stitch"
```

---

## Part 11 — Run DRC (Design Rules Check)

DRC catches physical errors: traces too close, missing connections, parts off the board, etc.

### 11.1 Run DRC
1. **Inspect → Design Rules Checker** (in pcbnew menu).
2. Click **Run DRC**.
3. The dialog lists errors and warnings.
4. Click each error — pcbnew highlights the problem location.
5. Common errors and fixes:
   - **"Unconnected items"**: a ratsnest line still exists. Route it (Part 8.3).
   - **"Clearance violation"**: two traces too close. Move one with `M` or shrink with route editor.
   - **"Holes too close"**: a via or pad is overlapping another. Move one.
6. Re-run DRC after each fix until **zero errors**. Warnings can sometimes be ignored, but read each.

### 11.2 Save
**`Ctrl+S`**.

---

## Part 12 — Generate fab files

This is what you send to JLCPCB.

### 12.1 Gerbers (the artwork files)
1. **File → Plot**.
2. In the Plot dialog:
   - **Plot format**: Gerber.
   - **Output directory**: `gerbers/` (KiCad will create it).
   - **Layers to plot** (check these): F.Cu, B.Cu, F.Mask, B.Mask, F.Silkscreen, B.Silkscreen, Edge.Cuts.
   - General options: enable **"Use Protel filename extensions"** if JLCPCB prefers it.
3. Click **Plot**. KiCad writes 7 files into `gerbers/`.

### 12.2 Drill files
1. Still in the Plot dialog, click **Generate Drill Files…**.
2. Defaults are usually fine. Click **Generate Drill File**.
3. Two more files appear in `gerbers/` (`.drl`).

### 12.3 BOM (Bill of Materials)
1. **Tools → Generate Legacy Bill of Materials**, or in newer KiCad: **File → Export → Bill of Materials**.
2. Output: a CSV listing every component, its value, footprint, and `JLCPCB part#`.
3. Verify by opening the CSV: Y1 = 12MHz, F1 = 500mA polyfuse / C2685389, U1 = AMS1117-3.3 / C6186, R20/R21 = 27R / C25092, R22 = 1k / C11702.

### 12.4 Position file (for SMT assembly)
1. **File → Fabrication Outputs → Component Placement (.pos)**.
2. Format: CSV. Units: mm. Files: separate (one for top, one for bottom).
3. Click **Generate Position File**.

### 12.5 Zip and upload
1. Zip everything in `gerbers/` plus the BOM CSV plus the .pos files.
2. Go to https://jlcpcb.com/ → **Order Now** → upload the zip.
3. Enable **PCB Assembly**. JLCPCB will read your BOM and .pos files automatically.

> Compare your Gerber preview against `../SKYWAY-96/Manufacturing & Assembly Files/` to spot anything obviously wrong before placing the order.

### 12.6 Headless audit (optional, recommended)
If you've installed `kicad-cli` and added it to PATH, run:
```
bash scripts/kicad_audit.sh
```
This generates `audit_output/erc.json`, `drc.json`, `bom.csv`, and `schematic.pdf` without opening the GUI. Catches issues you might have missed.

---

## Part 13 — Recovery

### Undo
- Inside KiCad: **`Ctrl+Z`** undoes the last edit. Repeat to undo more. Works in both Schematic and PCB editor.

### Discard everything since the last commit
In your terminal:
```
git restore .
```
This reverts all files in the project to their last-committed state. Your KiCad windows still show the old (now-reverted) data — close and reopen KiCad to load the restored files.

### Roll back to a specific commit
```
git log --oneline                # find the commit hash
git reset --hard <hash>          # DANGEROUS - destroys later commits
```
Use only if you're sure.

### KiCad locks file (.lck)
If KiCad crashed and won't reopen the project: in `PublicSecurity96/PublicSecurity96/`, delete any file named `~PublicSecurity96.kicad_sch.lck` or `~PublicSecurity96.kicad_pcb.lck`. These are stale lock files.

---

## Glossary

| Term | Meaning |
|---|---|
| **Eeschema** | KiCad's schematic editor (the wiring diagram tool). |
| **pcbnew** | KiCad's PCB editor (the physical board layout tool). |
| **Symbol** | A schematic part. Each component has a symbol (logical) and a footprint (physical). |
| **Footprint** | The physical pads + outline used on the PCB for a component. |
| **Refdes** | Reference designator — the unique label like `R20`, `U1`, `C5`. |
| **Net** | An electrical connection. Every wire belongs to exactly one net (e.g. `+3V3`, `GND`, `USB_DP`). |
| **ERC** | Electrical Rules Check — schematic-level wiring validator. |
| **DRC** | Design Rules Check — PCB-level physical validator. |
| **PWR_FLAG** | Special symbol that says "this net gets power from outside; don't warn me about it." |
| **Filled zone / copper pour** | A solid copper area on a layer, tied to a net (usually GND). |
| **Stitching via** | A via placed for thermal/EMI, not for routing a signal. |
| **Ratsnest** | The thin colored lines showing unrouted connections in pcbnew. |
| **Gerber** | The artwork file format PCB fabricators use. |

---

## Reference docs (in this repo)
- `docs/MISSING_VS_SKYWAY.md` — what's wrong and why
- `docs/reference/rp2040_keyboard_design.md` — Kiser §1 power, §4 routing
- `docs/reference/rp2040_designguide_schematic.md` — calliah333 part values
- `docs/reference/kicad_toolchain.md` — library install order
- `FIX_PLAN.md` — original root-cause analysis
- `REWORK_INSTRUCTIONS.md` — earlier (terser) rework path
- `scripts/kicad_audit.sh` — headless ERC + DRC + BOM via `kicad-cli`
