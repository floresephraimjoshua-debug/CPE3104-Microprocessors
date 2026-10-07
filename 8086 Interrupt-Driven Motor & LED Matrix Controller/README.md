# 8086 Interrupt-Driven Motor & LED Matrix Controller

A complex microprocessor-based simulation of an automated industrial control terminal designed for the **Intel 8086 CPU**. This project leverages an **8259 Programmable Interrupt Controller (PIC)** to manage real-time background hardware overrides alongside an **8255 Programmable Peripheral Interface (PPI)** that co-processes a DC motor drive and a scrolling 5×7 LED dot-matrix visual warning panel. The entire mixed-signal environment is fully simulated using **Proteus VSM**.

---

## 📐 Hardware Architecture & Bus Topologies

The system schema integrates advanced address latching, decoding logic, and co-processing chips mapped directly across the 8086 memory layout:

* **Bus Infrastructure**: Uses a `74LS373` transparent latch to demultiplex the address/data bus (`AD0-AD15`) and a `74LS245` transceiver to handle bi-directional data flow. Address resolution is managed via a `74LS138` 3-to-8 line decoder.
* **8255 PPI Addressing (`0F0H - 0F6H`)**:
  * **Port A (`0F0H`)**: Driving Row inputs of the 5×7 LED Matrix / Motor Control lines (`PA5`).
  * **Port B (`0F2H`)**: Active-low Column selection mask output bus.
  * **Port C (`0F4H`)**: Live system status flag monitor and indicator panel.
* **8259 PIC Interfacing (`0E0H - 0E2H`)**: Captures external control switches and maps asynchronous hardware commands to the 8086 interrupt lines.
* **Actuator Interfaces**: Features a single-digit active DC motor terminal, an acoustic speaker (`LS1`), and a multi-column LED display array.

---

## ⚙️ Interrupt Vector Table (IVT) Mapping

The system initializes the 8259 controller using specific Initialization Command Words (`ICW1`, `ICW2`, `ICW4`) and Operational Command Words (`OCW1`). The vector base address starts at `080H` (`200H` in memory absolute space):

| Interrupt Line | Routine Pointer | Memory Address (IVT) | Operational Behavior |
|:---:|:---|:---:|:---|
| **IR₀ (`080H`)** | `ON_OFF` | `0000:0200H` | Toggles system power flag (`ON_FLAG`) and flips status LED. |
| **IR₁ (`081H`)** | `PAUSE_PLAY` | `0000:0204H` | Latches execution state to freeze or resume matrix scrolling frames. |
| **IR₂ (`082H`)** | `MODES` | `0000:0208H` | Triggers mode shifts, forcing emergency routines if variable metrics fail. |

---

## 🛠️ System Operation & Firmware Execution Phases

### 1. Hard-Coded Power-Up Sequence
When the system transitions out of reset and receives an `ON_OFF` strobe, it initializes a high-current motor drive burst. It drives Pin 5 of Port A high (`OR AL, 00100000B`) for a precise 5-second software-timed loop before forcing the pin low and clearing out to enable standard processes.

### 2. 5×7 LED Matrix Multiplexed Scroller (`PRINT_CHAR`)
Visual data is segmented into 24 distinct frame arrays (`STRING_1` to `STRING_24`). The firmware prints columns dynamically by passing a bit-mask (`11111110B`) down Port B while retrieving immediate row bit vectors directly from the code segment register (`BYTE PTR CS:[SI]`). It uses bitwise logical rotations (`ROL`) and precision microsecond delay cascades to seamlessly scroll data without visual artifacting.

### 3. Asynchronous Emergency Override (`NMI_DISPLAY`)
If a mode drop is registered via the PIC input network, foreground text loops break instantly. The system enters an emergency routine that forces the motor safety cutoff, silences standard strings, and continuously flashes a custom `"X"` alert matrix pattern (`NMI_1`) onto the display element until manual intervention resets the interrupt state.

---

## 📂 Project Directory Structure

* `main.asm` — Master 8086 Assembly source containing multi-segment interrupt blocks, IVT configurations, and frame character tables.
* `ROOT.DSN` — Proteus VSM schematic capture tracking the electrical trace connections across the 8086, 8259 PIC, 8255 PPI, address latches, and actuators.
* `ROOT.CDB` — Asset definitions keeping track of Proteus modeling primitives.
* `FIRMWARE.XML` — Build automation schema translating compilation maps straight into the interactive workspace.

---

## 🚀 How to Run the Simulation

1. Launch **Proteus ISIS / VSM** (version 8.x or later).
2. Open the schematic project file: `ROOT.DSN`.
3. Verify that the **8086 micro-model** internal memory properties match target specifications (`0x10000`).
4. Click the **Play / Run** button at the bottom-left workspace toolbar.
5. Trigger the external input switch block (`SW1`) to generate hardware interrupt strobes. Watch the DC motor run its introductory cycle before text begins scanning smoothly across the LED matrix panel.

