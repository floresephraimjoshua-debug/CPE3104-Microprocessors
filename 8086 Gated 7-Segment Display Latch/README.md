# 8086 Gated 7-Segment Display Latch

A microprocessor-based simulation of a gated, input-triggered digital latch interface designed for the **Intel 8086 CPU**. This project utilizes parallel I/O addressing to monitor a dedicated hardware strobe line, decode an upper-nibble 4-bit binary input value on command, and drive synchronized dual outputs containing raw 7-segment display patterns and binary bus signals. The entire environment is simulated using **Proteus VSM**.

---

## 📐 System Architecture & I/O Mapping

The firmware interfaces directly with localized hardware ports to manage edge-triggered state tracking and display updates:

* **Port C Input Bus (`0F4H`)**: Multi-functional input port split into a control strobe line and a data bus:
  * **Bit 0 (LSB)**: Hardware Latch Enable line. The system remains locked in a polling state until this line switches to high (`1`).
  * **Bits 4-7 (Upper Nibble)**: Data Input Bus hosting the target 4-bit binary token to display (0000b to 1001b).
* **Port B Segment Bus (`0F2H`)**: Outputs hardcoded 7-bit character masks mapped directly to standard 7-segment LED pins (a, b, c, d, e, f, g).
* **Port A Binary Bus (`0F0H`)**: Mirror bus that outputs the raw, un-decoded 4-bit binary representation of the captured integer.

---

## ⚙️ Truth Table & Strobe Mappings

The system ignores input values until a strobe pulse transitions on Bit 0. Once validated, values map as follows:

| Strobe (Port C Bit 0) | Data Input (Port C Bits 4-7) | Decoded Integer | Port B Segment Mask | Port A Binary Output |
|:---:|:---:|:---:|:---|:---:|
| **`0`** | `XXXXb` | *No Update* | *Holds Previous State* | *Holds Previous State* |
| **`1`** | `0000b` | **0** | `00111111B` | `0000b` |
| **`1`** | `0001b` | **1** | `00000110B` | `0001b` |
| **`1`** | `0010b` | **2** | `01011011B` | `0010b` |
| **`1`** | `0011b` | **3** | `01001111B` | `0011b` |
| **`1`** | `0100b` | **4** | `01100110B` | `0100b` |
| **`1`** | `0101b` | **5** | `01101101B` | `0101b` |
| **`1`** | `0110b` | **6** | `01111101B` | `0110b` |
| **`1`** | `0111b` | **7** | `00000111B` | `0111b` |
| **`1`** | `1000b` | **8** | `01111111B` | `1000b` |
| **`1`** | `1001b` | **9** | `01101111B` | `1001b` |

---

## 🛠️ Core Functional Subsystems

### 1. Gated Hardware Strobe Loop (`HERE`)
The core firmware establishes an execution block using a bitwise `TEST AL, 01H` instruction. If Bit 0 of Port C is zero, the Zero Flag is set, and the `JZ HERE` loop keeps the system locked. This mimics a hardware edge-trigger or load-enable line, ensuring the display never alters during mid-selection switch updates.

### 2. Nibble Isolation & Shifting
When execution breaks past the strobe line, the 8-bit input register is re-read. The software sets a shift register count (`MOV CL, 4`) and utilizes a logical right shift (`SHR AL, CL`). This operation discards the lower control flags and shifts the data inputs into the lower position, translating upper-nibble switch positions directly into raw hexadecimal values.

### 3. Synchronous Dual-Bus Delivery
Upon extracting a valid numeric value, the system updates Port A immediately with the raw hex representation before passing the token through a comparison tree. Once matched with its decoded 7-segment equivalent, Port B is updated, changing the visual output instantly.

---

## 📂 Project Directory Structure

* `main.asm` — Master 8086 Assembly source containing initialization blocks, segment tables, and instruction arrays.
* `ROOT.DSN` — Proteus VSM schematic detailing the electrical routing between the 8086 bus interface, strobe switches, and the single 7-segment display hardware.
* `ROOT.CDB` — Asset definitions keeping track of Proteus modeling primitives.
* `FIRMWARE.XML` — Compiler directives routing the MASM32 toolkit output directly into the simulation workspace.

---

## 🚀 How to Run the Simulation

1. Launch **Proteus ISIS / VSM** (version 8.x or later).
2. Open the schematic project file: `ROOT.DSN`.
3. Right-click the **8086 CPU component**, select *Properties*, and ensure the **Internal Memory Size** is explicitly configured to **`0x10000`** to support memory layout segment alignment rules.
4. Click the **Play / Run** button at the bottom-left workspace toolbar.
5. **To use:** Toggle your desired numeric value using the upper bits (Bits 4-7) of Port C. Notice that the display does not change. Flip Bit 0 of Port C to high (`1`) to strobe the circuit and latch the new number onto the display.

