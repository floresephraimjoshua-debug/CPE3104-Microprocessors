# 8086-Based Automated Marker Refilling Station

An automated, microprocessor-controlled system designed to autonomously detect, test, and replenish the ink levels of up to four whiteboard markers simultaneously. Built using standard **Intel 8086 assembly language**, the project focuses on reducing manual workloads, preventing ink spills, and providing consistent, controlled fluid distribution for educational and corporate environments.

---

## 🛠️ Hardware Specifications

The hardware architecture expands the 8086 I/O capability using dedicated peripheral chips mapped to specific address ranges:

*   **Microprocessor (MPU):** Intel 8086 CPU (16-bit architecture) running assembly control logic.
*   **Input/Output Control:** Two **8255 Programmable Peripheral Interfaces (PPI)**.
    *   `8255 PPI-1` (Addresses `F0H–F6H`): Interfaces with the LCD and ADC.
    *   `8255 PPI-2` (Addresses `C0H–C6H`): Interfaces with the pumps, limit switches, and LED indicators.
*   **Interrupt Management:** **8259 Programmable Interrupt Controller (PIC)** mapped to the `IR0` interrupt line for system power toggle and emergency safe-shutdown loops.
*   **Ink Level Sensing:** **ADC0808 Analog-to-Digital Converter** combined with a conductive fluid reservoir sensor to prevent dry-pumping.
*   **User Interface:** **LM044L (4×40) Character LCD Display** providing live status updates.
*   **Actuators & Sensors:** 4 independent 5V DC Pumps driven by transistor switches, paired with 4 slot limit switches for marker detection.

---

## 📟 System Signal & Port Mapping

| Peripheral Component | PPI Chip | PPI Port | Port Address | Signal Type | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LCD Data Bus** | 8255A (U5) | Port A (`PA0–PA7`) | `F0H` | Digital Output | Sends character data (`D0–D7`) to the LCD screen. |
| **ADC / LCD Control** | 8255A (U5) | Port B (`PB0–PB7`) | `F2H` | Digital Output | Controls `RS`/`E` for LCD, and `ALE`/`START`/`OE` for ADC. |
| **ADC Digital Output** | 8255A (U5) | Port C (`PC0–PC7`) | `F4H` | Digital Input | Reads the reversed 8-bit digital voltage from the ADC0808. |
| **Pumps & Slot LEDs** | 8255B (U9) | Port A (`PA0–PA3`) | `C0H` | Digital Output | Actuates `PUMP1` to `PUMP4` and respective status LEDs. |
| **Marker Slot Sensors** | 8255B (U9) | Port C (`PC0–PC3`) | `C4H` | Digital Input | Detects physical placement of markers (`MARKER1–4`). |
| **Start Button** | 8255B (U9) | Port C (`PC4`) | `C4H` | Digital Input | Initiates the refilling sequence. |

---

## ⚙️ Core System States

The software algorithm cycles through three distinct operational phases controlled by registers, software-timed loops, and status flags:

1. **IDLE STATE:** 
   * Activated via the `8259 PIC` external interrupt button. 
   * Initializes all peripherals, clears the display, and prints `"AUTOMATIC MARKER REFILLER"`.
2. **CHECK STATE:** 
   * Upon pressing the START button, the system pulses the `ADC0808` to read the fluid level reservoir.
   * If the analog value falls below the safety threshold (`< 1V` / `33H`), operations halt and the display prompts `"NOT ENOUGH INK!"`.
   * If ink is sufficient, it moves into active slot scanning.
3. **REFILL STATE:** 
   * Scans inputs from `PORT2C`. Only occupied slots set their relative internal tracking flags (`MRK1_FLAG` to `MRK4_FLAG`).
   * Generates a bitmask byte to activate only the occupied DC pumps simultaneously.
   * Runs a software delay timer for exactly **5.0 nominal seconds**, deactivates the pumps, enforces a **2-second drip delay** to catch residual ink, and cleanly returns to the IDLE state.

---

## 📂 Project Structure

```text
├── FIRMWARE/
│   ├── 8086/
│   │   ├── Debug/
│   │   │   └── Debug.exe       # Compiled executable environment
│   │   └── main.asm            # Primary Intel 8086 Assembly Source Code
│   └── 8086.xml                # Firmware peripheral mapping parameters
├── SCRIPTS/
│   └── PWRRAILS.DAT            # Simulation power rail configurations
├── ROOT.DSN                    # Proteus Schematic Layout File
├── ROOT.CDB                    # Component Database File
└── PROJECT.XML                 # Proteus Project Metadata
```

---

## 🚀 How to Run the Simulation

1. Open the project schematic (`ROOT.DSN`) using **Proteus Design Suite v8.0 or higher**.
2. Ensure the `main.asm` file is properly linked or compiled into the 8086 microprocessor object properties.
3. Click the **Play / Run** button at the bottom left of the Proteus interface.
4. Interact with the circuit:
   * Press the **POWER** button to trigger `ISR1` and wake up the LCD screen.
   * Toggle the `DIPSW_4` switches (`SW1–SW4`) to simulate inserting whiteboard markers into specific slots.
   * Press the **START** button to initiate the 5-second automatic pump dispensing sequence.

