# 8086 Presettable 7-Segment Counter

A microprocessor-based simulation of an interactive, presettable digital counting interface designed for the **Intel 8086 CPU**. This project utilizes parallel I/O addressing to read physical configuration switches, accept a manual user-defined starting number, and execute a sequential upward count to its maximum single-digit capacity (9). The system drives both raw 7-segment display matrices and a synchronized 4-bit binary bus, fully simulated using **Proteus VSM**.

---

## 📐 System Architecture & I/O Mapping

The firmware directly interfaces with localized hardware ports to handle input preset state scanning and real-time display updates:

* **Port C Input Bus (`0F4H`)**: Multi-functional input bus hosting both system execution commands and manual numerical values.
  * `00000000b`: System Kill Switch (clears and disables all displays).
  * `00000001b`: Automated Count Command (triggers the sequential counter from the preset starting point).
  * `XXXX0001b`: Preset Load Mode (manually selects a fixed starting value from 1 to 9).
* **Port B Segment Bus (`0F2H`)**: Outputs hardcoded 8-bit alphanumeric character masks mapped directly to standard 7-segment LED pins (a, b, c, d, e, f, g).
* **Port A BCD Bus (`0F0H`)**: Outputs a 4-bit Binary Coded Decimal representation of the active integer (0000b → 1001b).

---

## ⚙️ Operational Workflow & State Decodes

The counter operates across distinct execution phases depending on how the Port C input switches are configured:

### 1. Manual Preset Mode
By applying specific binary masks to the upper bits of Port C while keeping the lower command bits high, the user manually sets a starting digit. The system decodes the input and jumps to the corresponding digit sector, freezing that specific integer on the screen:
* **Presetting '3' (`00110001b`)**: Jumps directly to the `THREE` sector, routing `01001111B` to Port B and `0011b` to Port A.

### 2. Sequential Up-Counting
When the automated count switch is initiated, the system relies on a structural fall-through code architecture. Because there are no jump barriers isolating the numeric blocks, execution cascades downward from the loaded starting point:
* **Example Case:** If the counter is manually preset to `5`, activating the sequence causes it to output `5`, then naturally fall straight through to execute `SIX`, `SEVEN`, `EIGHT`, and `NINE` sequentially without stopping.

### 3. Display Hard Ceiling (Single-Digit Max)
Because the hardware relies on a single 7-segment display element, the counter enforces a hard ceiling at **9**. Once the execution fall-through hits the `NINE` subroutine, it runs its final delay block and terminates by looping back to the main `START` block to await its next hardware command.

---

## 📂 Project Directory Structure

* `main.asm` — Master 8086 Assembly source containing initialization blocks, segment tables, and instruction arrays.
* `ROOT.DSN` — Proteus VSM schematic detailing the electrical routing between the 8086 bus interface, input switches, and the single 7-segment display hardware.
* `ROOT.CDB` — Asset definitions keeping track of Proteus modeling primitives.
* `FIRMWARE.XML` — Compiler directives routing the MASM32 toolkit output directly into the simulation workspace.

---

## 🚀 How to Run the Simulation

1. Launch **Proteus ISIS / VSM** (version 8.x or later).
2. Open the schematic project file: `ROOT.DSN`.
3. Right-click the **8086 CPU component**, select *Properties*, and ensure the **Internal Memory Size** is explicitly configured to **`0x10000`** to support the data and segment alignment rules.
4. Click the **Play / Run** button at the bottom-left workspace toolbar.
5. **To use:** Input your desired starting number via the upper bits of Port C, then trigger the lower command bit to watch the single-digit display count upward from your preset number straight to 9.

