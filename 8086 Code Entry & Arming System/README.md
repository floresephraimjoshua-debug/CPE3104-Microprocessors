# Access Control System Simulator (8086 + 8255)

A microprocessor-based digital security lock and system arming simulation designed for the **Intel 8086 CPU**. This project utilizes the **8255 Programmable Peripheral Interface (PPI)** to handle inputs from a matrix keypad and display system menus, prompts, and status messages on a multi-line LCD screen. The entire hardware and firmware integration is fully simulated using **Proteus VSM**.

---

## 🛠️ Hardware & Components (Proteus)
The system architecture simulated in the `ROOT.DSN` file consists of:
* **Intel 8086** – The core 16-bit microprocessor processing the system firmware.
* **Intel 8255 PPI** – Configured via control word mapping (`0F6H`) to route input/output signals.
  * **Port A (`0F0H`)**: Dedicated data lines managing command and data transfers to the LCD display.
  * **Port B (`0F2H`)**: Handles control flags (`RS`, `EN`) for the LCD operations.
  * **Port C (`0F4H`)**: Interfaced with a matrix keypad to scan and read user keystrokes.
* **Alphanumeric LCD Screen** – Configured for 8-bit data mode to display system menus and notifications.
* **Matrix Keypad** – Used for menu selection and alphanumeric access code entries.

---

## ⚙️ System Features & Operations

### 🟦 The Main Menu
* Pressing the **`*` key** initializes and powers **ON** the LCD screen to reveal the main options menu.
* Pressing the **`#` key** turns **OFF** or clears the screen display at any point.

The terminal presents the user with two primary actions:
1. **`[1] Set Code`** – Allows the administrator to establish or rewrite an authorization password.
2. **`[2] Arm System`** – Locks down the perimeter and activates system tracking.

---

### 🛡️ Core Security Workflows

#### 🔑 1. Setting the Access Code
* The system demands a custom variable password depth between **4 and 8 digits**.
* As the user types, characters are masked on screen using standard secure `*` symbols.
* Pressing **`#`** finalizes the input and saves it to internal memory registers (`ACCESS_CODE`).
* *Error Handling:* If a user inputs fewer than 4 digits, a `"Code too short!"` warning trips, clearing the register and forcing a retry.

#### 🔒 2. Arming the System
* The system checks if a master code has been configured. If none exists, an error message (`"ERROR: No code set!"`) outputs to the screen.
* If a code exists, the terminal locks out into a `"WARNING: System Armed!"` state.

#### 🔓 3. Disarming the System
* While armed, the system actively monitors input. Pressing **`0`** triggers the disarm authentication terminal.
* The user must input the matching 4-to-8 digit security passkey.
* **Success:** A valid entry returns a `"SUCCESS: System Disarmed!"` notice and resets the terminal to the main menu.
* **Failure:** An incorrect entry returns an flashing `"INCORRECT CODE!"` rejection notice and keeps the system in its armed state.

---

## 📂 Project Structure
* `/FIRMWARE/8086/main.asm` — Master Assembly source code file containing memory segments, key-scanning routines, and LCD drivers.
* `ROOT.DSN` — Proteus VSN capture file containing wire mappings, clock distributions, and memory bus layouts.
* `ROOT.CDB` — Components database references needed for proper schematic asset rendering inside Proteus.
* `/FIRMWARE.XML` — Build schema metadata connecting the assembly binary target to the Proteus processor engine configuration.

---

## 🚀 How to Run the Simulation
1. Launch **Proteus ISIS / VSM** (version 8.x or later recommended).
2. Open the main schematic project file: `ROOT.DSN`.
3. The integrated assembly project bundle will automatically bind the `Debug.exe` / hex output to the 8086 component model.
4. Click the **Play / Run** button at the bottom-left corner of the Proteus workspace.
5. Interact with the digital lock using the on-screen Matrix Keypad.

