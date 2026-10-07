# CPE3104 - Microprocessors

A compilation of advanced, hardware-integrated laboratory projects completed for the **CPE3104 (Microprocessors)** course. 

The core objective of this curriculum is to master low-level hardware interfacing, real-time asynchronous interrupt handling, and external peripheral control through direct register manipulation of the **Intel 8086** processor.

---

## 🛠️ The Technical Stack

* **Processor Core:** **Intel 8086 Microprocessor** (16-bit x86 architecture).
* **Programming Language:** 100% Native **8086 Assembly Language**.
* **Compiler & Toolchain:** **MASM32** (Microsoft Macro Assembler) for compiling raw machine-executable binaries.
* **Simulation Environment:** **Proteus VSM** (Virtual System Modeling) for real-time circuit simulation and interactive debugging.

---

## 🔌 Embedded Hardware Interfaced

The course projects focus on configuring, mapping, and driving peripheral silicon chips and active components directly from the **Intel 8086** bus:

* **Peripheral ICs:** 
  * **Intel 8255 PPI** (Programmable Peripheral Interface) for parallel I/O bus management.
  * **Intel 8259 PIC** (Programmable Interrupt Controller) for processing external asynchronous hardware interrupts.
* **Bus Infrastructure:** `74LS373` Address Latches, `74LS245` Bus Transceivers, and `74LS138` 3-to-8 Line Decoders for address resolution.
* **Input Peripherals:** 4x4 Matrix Keypads, DIP switch blocks, and tactile load-enable lines.
* **Display Elements:** Multi-line Alphanumeric LCD modules, 5x7 LED Dot-Matrix panels, and single-digit 7-Segment displays.
* **Actuators:** Active DC Motors and acoustic alerting Speakers.

---

## 🎯 Core Technical Objectives

1. **Bus Management:** Implementing address-demultiplexing logic to isolate data lines from the 16-bit processor bus.
2. **Interrupt Vector Table (IVT) Control:** Directly programming the 8086 IVT in memory to bind external lines to custom Interrupt Service Routines (ISRs).
3. **Data Bus Manipulation:** Isolating upper and lower data nibbles using logical bitwise shifts, masks, and rotations.
4. **Display Decoding Pipelines:** Converting raw hex data arrays into standard alphanumeric matrices and Packed BCD structures.
