# CPE3104 - Microprocessors

A compilation of advanced, hardware-integrated laboratory projects completed for the **CPE3104 (Microprocessors)** course. 

The core objective of this curriculum is to master **low-level hardware interfacing**, real-time asynchronous interrupt handling, and external peripheral control through direct register manipulation.

---

## 🛠️ The Technical Stack

* **Programming Language:** 100% Native **8086 Assembly Language** (Intel x86 Architecture).
* **Compiler & Toolchain:** **MASM32** (Microsoft Macro Assembler) for generating raw execution binaries.
* **Simulation Environment:** **Proteus VSM** (Virtual System Modeling) for real-time mixed-signal circuit simulation and interactive debugging.

---

## 🔌 Embedded Hardware Interfaced

The course projects focus on configuring, mapping, and driving industrial-grade silicon chips and active peripherals:

* **Core Processors:** Intel **8086 Microprocessor** acting as the central execution engine.
* **Peripheral Controllers:** 
  * Intel **8255 PPI** (Programmable Peripheral Interface) for parallel I/O bus management.
  * Intel **8259 PIC** (Programmable Interrupt Controller) for handling real-time asynchronous background hardware events.
* **Input Devices:** Matrix Keypads, multi-bit DIP Switches, and tactile strobe lines.
* **Output & Visual Indicators:** Multi-line Alphanumeric LCDs, 5x7 LED Dot-Matrix display panels, and common cathode/anode 7-Segment displays.
* **Actuators & System Elements:** DC Motors, acoustic Speakers (`LS1`), and physical relay circuitry.

---

## 🎯 Core Technical Objectives Achieved

1. **Memory Space Mapping:** Designing system-level address-decoding logic using latches (`74LS373`), transceivers (`74LS245`), and line decoders (`74LS138`).
2. **Interrupt Vector Table (IVT) Manipulation:** Direct routing of hardware lines to manual background Interrupt Service Routines (ISRs).
3. **Bus Splitting & Bit Manipulation:** Extracting, shifting, and masking individual data bus nibbles to decode variable system inputs.
4. **Data Conversion Pipelines:** Transforming raw binary/hex processor values into standard Packed BCD structures for display rendering.
