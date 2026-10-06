# AXI4-Lite Slave RTL

A synthesizable **AXI4-Lite Slave RTL design** implemented in Verilog with a self-checking verification environment.

The project demonstrates memory-mapped register access, independent AXI write channels, byte-level write strobes, interrupt handling, error responses, and protocol-oriented verification using **AMD Vivado XSim**.

---

## 📌 Project Overview

AXI4-Lite is a lightweight memory-mapped interface commonly used for connecting control/status peripherals to processors and larger AXI-based systems.

In this project, an AXI4-Lite slave peripheral was designed from RTL level with:

- Independent write address and write data channels
- Read address and read data channels
- Memory-mapped control/status registers
- Byte write-strobe support
- Interrupt generation and clearing
- Invalid-address detection
- AXI `SLVERR` responses
- Self-checking verification testbench

The design was simulated and verified using **Vivado 2020.2 XSim**.

---

## 🏗️ Architecture

```text
                 AXI4-Lite Master
                       │
        ┌──────────────┼──────────────┐
        │              │              │
     AW Channel     W Channel     AR Channel
        │              │              │
        ▼
