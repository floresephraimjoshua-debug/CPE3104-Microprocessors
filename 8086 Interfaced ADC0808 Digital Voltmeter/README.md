# 8086 Interfaced ADC0808 Digital Voltmeter

A microprocessor-based data acquisition simulation designed for the **Intel 8086 CPU**. This project establishes a synchronous signal strobe protocol to interface with an **ADC0808 Analog-to-Digital Converter** through an **8255 Programmable Peripheral Interface (PPI)**. The system samples raw 8-bit analog signals, processes them using fixed-point assembly mathematics, and outputs a packed decimal voltage reading (0.0V - 5.0V) formatted for dual hardware `7448` display decoders. The entire environment is simulated using **Proteus VSM**.

---

## 📐 System Architecture & I/O Mapping

The system configuration handles control strobing and digital value readbacks by mapping specific registers across the 8255 PPI:

* **Control Registry (`0F6H`)**: Initialized with Control Word `89H` (Configures Port A and Port B as outputs, Port C as input).
* **Port B Output Bus (`0F2H`)**: Controls the physical signaling pins of the ADC0808 chip:
  * **Bits 0-2**: Address Selection Lines (`ADD_A`, `ADD_B`, `ADD_C`) – hardcoded to `000b` to scan analog channel `IN0`.
  * **Bit 3**: `ALE` (Address Latch Enable) line.
  * **Bit 4**: `START` conversion trigger line.
  * **Bit 5**: `OE` (Output Enable) line.
* **Port C Input Bus (`0F4H`)**: Receives the raw converted 8-bit digital output (0 to 255) dropped from the ADC0808 data lines.
* **Port A Output Bus (`0F0H`)**: Outputs the formatted, packed BCD voltage representation straight into a dual `7448` BCD-to-7-Segment decoder block.

---

## ⚙️ Control Sequence & Signaling Protocol

The software coordinates precise timing windows to execute the analog acquisition loop:

1. **Channel Selection:** Port B clears the channel address pins to lock down analog line `IN0`.
2. **Address Latching:** Pin `ALE` is driven high (`08H`) and held through a `1ms` software-timed delay to anchor the multiplexer state.
3. **Conversion Initiation:** Pin `START` is driven high (`18H`) to cycle the analog sampling register window inside the ADC.
4. **End of Conversion Poll:** The code vectors through a `WAIT_EOC` timing loop to cleanly clear out conversion cycle windows.
5. **Data Readback:** Output Enable is pulled high (`20H`) to open the ADC tristate buffers, forcing the 8-bit digital reading straight onto the Port C input bus.

---

## 📊 Fixed-Point Division & Value Packaging

Because the Intel 8086 lacks native floating-point math support, the firmware scales the raw digital values using an integer tracking ratio algorithm (\(\frac{255 \text{ steps}}{5 \text{ Volts}} = 51 \text{ steps per Volt}\)):

### 1. Extracting Whole Volts
The 8-bit raw reading (stored in `AL`) is cleared into the `AX` register and divided by 51 (`DIV BL`). The resulting quotient represents the absolute **whole volts** place (ranging from `0` to `5`) and is temporarily isolated in `DL`.

### 2. Resolving Tenths Decimal Digit
The integer remainder of the initial division (stored in `AH`) is shifted to `AL`, multiplied by `10` via hardware registers (`MUL BH`), and divided by 51 a second time. This fixed-point trick extracts the **fractional tenths digit** (ranging from `0` to `9`), saving it in `DH`.

### 3. Packed BCD Generation
The two values are compressed into a single-byte payload. The tenths digit is shifted left by 4 bits (`SHL AH, CL`) into the upper nibble and combined with the whole volts value in the lower nibble via a bitwise `OR` logical mapping. 

\[\text{Output Byte} = (\text{Tenths Digit} \ll 4) \ \vert{} \ \text{Whole Volts}\]

This byte is pushed out to Port A, enabling the twin `7448` decoders to instantly display standard decimal notations like `4.7` or `1.2`.

---

## 📂 Project Directory Structure

* `main.asm` — Master 8086 Assembly source containing the control strobe logic, fixed-point math loops, and register shifting routines.
* `FLORES_SY_GOMEZ_ADC.pdsprj` — Proteus VSM workspace project tracing the wire configurations between the 8086 processor, 8255 PPI, ADC0808 converter, and the `7448` segment blocks.

---

## 🚀 How to Run the Simulation

1. Launch **Proteus ISIS / VSM** (version 8.x or later).
2. Open the workspace project file: `FLORES_SY_GOMEZ_ADC.pdsprj`.
3. Verify that the **8086 micro-model** internal memory properties match target specifications (`0x10000`).
4. Click the **Play / Run** button at the bottom-left workspace toolbar.
5. Manipulate the analog input source (potentiometer/DC voltage line) routed to channel `IN0` of the ADC. Monitor the dual 7-segment display module to see your analog voltage alterations decoded in real-time.

