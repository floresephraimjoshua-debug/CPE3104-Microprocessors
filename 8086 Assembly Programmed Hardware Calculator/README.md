# 4-Bit Arithmetic Logic Unit (ALU) Simulator

A microprocessor-based simulation of a **4-bit Arithmetic Logic Unit (ALU)** designed for the **Intel 8086 CPU**. This project utilizes the **8255 Programmable Peripheral Interface (PPI)** to emulate hardware data buses and control lines. It inputs dual 4-bit operands, processes them based on an external opcode/control signal, handles exception flags (negative and overflow), and outputs the result in Binary Coded Decimal (BCD) format. The entire system is simulated using **Proteus VSM**.

---

## 📐 System Architecture & I/O Mapping

The system utilizes the 8255 PPI to route data and control signals into the 8086 execution core. The ports are mapped as follows:

* **Control Registry (`096H`)**: Configures the 8255 PPI with Control Word `89H` (Port A/B as output, Port C as input).
* **Port C Data Bus (`094H`)**: Acts as a split 8-bit input bus hosting two independent 4-bit operands:
  * **Lower Nibble (Bits 0-3)**: Operand 1 (OP₁)
  * **Upper Nibble (Bits 4-7)**: Operand 2 (OP₂)
* **Port B Control Lines (`092H`)**: Acts as the ALU Opcode Select lines to determine the arithmetic operation.
* **Port A Output Bus (`090H`)**: Outputs the processed result directly to the display subsystem (typically a 2-digit 7-segment display).

---

## ⚙️ ALU Operations & Opcodes

The control unit continuously pools Port B to decode the active operation command:

| Opcode (Port B) | Operation | Execution Logic | Exception / Error Mask |
|:---|:---|:---|:---|
| **`0x01`** | **Addition (SUM)** | OP₁ + OP₂ | Automatically converted to 2-digit BCD |
| **`0x02`** | **Subtraction (DIFF)** | OP₂ - OP₁ | Outputs **`0xAA`** if result is negative |
| **`0x04`** | **Multiplication (PROD)** | OP₂ × OP₁ | Outputs **`0xBB`** if product exceeds 99 (`0x63`) |
| **`0x08`** | **Division (QUOT)** | OP₂ ÷ OP₁ | Returns quotient integer (truncates remainder) |

---

## 🛠️ Core Functional Subsystems

### 1. Bus Splitting & Operand Extraction
The software splits the single 8-bit input bus from Port C into two isolated registers. It uses bitwise logical shifts (`SHL` / `SHR`) to mask out the upper and lower nibbles, cleanly separating Operand 1 and Operand 2 before routing them to the arithmetic execution unit.

### 2. Status Flags & Exception Handling
* **Sign Flag Check (`NOTPOSITIVE`)**: During subtraction, if the result trips the internal processor sign flag (`JS`), the ALU halts regular output and forces an error pattern of `0xAA` onto the output bus.
* **Overflow Flag Check (`GREATER`)**: During multiplication, the ALU validates the product against a ceiling of 99 (`0x63`). If the value exceeds 2 BCD digits, it flags an overflow by sending `0xBB` to Port A.

### 3. Binary-to-BCD Conversion Subroutine (`TWODIG`)
For any valid arithmetic result that spans two digits (greater than 9), the ALU automatically enters a conversion loop. It divides the raw hex/binary result by `0x0A` (10) to separate the tens and units places. It then shifts and packages them back into standard Packed BCD format so a multi-digit hardware display can read it.

---

## 📂 Project Directory Structure

* `main.asm` — Master 8086 Assembly source code file containing the polling loops, shift registers, and mathematical logic blocks.
* `ROOT.DSN` — Proteus VSM schematic capture detailing the bus interconnections between the 8086, 8255, input switches, and 7-segment displays.
* `ROOT.CDB` — Component database definitions mapping the electronic models for Proteus simulation tracking.
* `FIRMWARE.XML` — Compilation metadata mapping the MASM32 build configurations directly to the Proteus project engine.

---

## 🚀 How to Run the Simulation

1. Launch **Proteus ISIS / VSM** (version 8.x or later).
2. Open the schematic project file: `ROOT.DSN`.
3. Right-click the **8086 CPU component**, select *Properties*, and ensure the **Internal Memory Size** is explicitly set to **`0x10000`** as required by the firmware memory segments.
4. Click the **Play / Run** button at the bottom-left workspace toolbar.
5. Set your inputs via the Port C switches, toggle an operation bit on Port B, and monitor the resulting output matrix on Port A.

