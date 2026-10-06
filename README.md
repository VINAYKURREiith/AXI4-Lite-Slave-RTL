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
        ▼              ▼              ▼
   ┌────────────────────────────────────────┐
   │            AXI4-Lite Slave             │
   │                                        │
   │   ┌──────────────┐                     │
   │   │ Write Control│                     │
   │   └──────┬───────┘                     │
   │          │                             │
   │   ┌──────▼───────┐                     │
   │   │ Register Bank│◄──── Read Logic      │
   │   └──────┬───────┘                     │
   │          │                             │
   │   ┌──────▼───────┐                     │
   │   │ IRQ Logic    │──────► IRQ          │
   │   └──────────────┘                     │
   │                                        │
   │   B Channel ───────────────► Master    │
   │   R Channel ───────────────► Master    │
   └────────────────────────────────────────┘
```

---

## ⚙️ Design Specifications

| Parameter | Value |
|---|---|
| HDL | Verilog |
| Data Width | 32-bit |
| Address Width | 8-bit |
| Interface | AXI4-Lite |
| Clock | Single synchronous clock |
| Reset | Active-low asynchronous reset |
| Simulator | Vivado XSim |
| Vivado Version | 2020.2 |

---

## 🗂️ AXI4-Lite Channels

### Write Address Channel

```text
AWADDR
AWVALID
AWREADY
```

The slave independently captures the write address when:

```text
AWVALID && AWREADY
```

### Write Data Channel

```text
WDATA
WSTRB
WVALID
WREADY
```

The write data and byte strobes are independently captured.

### Write Response Channel

```text
BRESP
BVALID
BREADY
```

The slave generates:

```text
OKAY   = 2'b00
SLVERR = 2'b10
```

### Read Address Channel

```text
ARADDR
ARVALID
ARREADY
```

### Read Data Channel

```text
RDATA
RRESP
RVALID
RREADY
```

---

# 🗃️ Register Map

| Address | Register | Access | Description |
|---:|---|:---:|---|
| `0x00` | CONTROL | R/W | Peripheral control |
| `0x04` | STATUS | R | Peripheral status |
| `0x08` | DATA_IN | R/W | Input data register |
| `0x0C` | DATA_OUT | R/W | Output data register |
| `0x10` | IRQ_ENABLE | R/W | Interrupt enable |
| `0x14` | IRQ_STATUS | R/W | Interrupt status / W1C |
| `0x18` | SCRATCH | R/W | General-purpose scratch register |
| `0x1C` | VERSION | R | Version information |

---

## 🔹 CONTROL Register — `0x00`

Used to control the peripheral.

The current implementation supports register read/write access with byte strobes.

---

## 🔹 STATUS Register — `0x04`

Provides status information derived from the peripheral state, including interrupt status and input-data state.

---

## 🔹 DATA_IN Register — `0x08`

Writing to `DATA_IN` stores input data and generates an interrupt event.

```text
AXI Write DATA_IN
       │
       ▼
DATA_IN_REG
       │
       ▼
IRQ_STATUS[0] = 1
       │
       ▼
IRQ_ENABLE[0] = 1
       │
       ▼
IRQ = 1
```

---

## 🔹 DATA_OUT Register — `0x0C`

Provides a memory-mapped output data register.

---

## 🔹 IRQ_ENABLE Register — `0x10`

Bit 0 controls whether the interrupt output is enabled.

```text
IRQ = IRQ_ENABLE[0] && IRQ_STATUS[0]
```

---

## 🔹 IRQ_STATUS Register — `0x14`

Interrupt status register.

The implementation uses **Write-One-to-Clear (W1C)** behavior.

Writing:

```text
DATA[0] = 1
```

clears:

```text
IRQ_STATUS[0]
```

---

## 🔹 SCRATCH Register — `0x18`

A general-purpose read/write register used for basic AXI transaction verification.

Example:

```text
Write: 12345678
Read : 12345678
```

---

## 🔹 VERSION Register — `0x1C`

Returns:

```text
0x00010000
```

---

# ✍️ Byte Strobe Support

The design supports AXI write strobes through `WSTRB`.

For a 32-bit data bus:

```text
WSTRB[3:0]
```

controls the four individual bytes.

Example:

```text
Initial:
AAAA_BBBB

Write:
CCCC_DDDD

WSTRB:
0011
```

Result:

```text
AAAA_DDDD
```

This verifies byte-level register modification.

---

# 🚨 Error Handling

Invalid register addresses generate an AXI `SLVERR` response.

Example:

```text
Address = 0x40
```

Since `0x40` is outside the implemented register map:

```text
BRESP = 2'b10
```

Result:

```text
SLVERR
```

---

# 🧪 Verification

A self-checking Verilog testbench was developed to verify both normal operation and AXI protocol corner cases.

## Verification Tests

### Test 1 — Scratch Register

```text
Write → 0x12345678
Read  → 0x12345678
```

**PASS**

### Test 2 — DATA_OUT

```text
Write → 0xDEADBEEF
Read  → 0xDEADBEEF
```

**PASS**

### Test 3 — CONTROL Register

```text
Write → 0x00000001
Read  → 0x00000001
```

**PASS**

### Test 4 — VERSION Register

```text
Read → 0x00010000
```

**PASS**

### Test 5 — Byte Strobe

Verified partial 32-bit register updates using `WSTRB`.

**PASS**

### Test 6 — Interrupt Generation

Verified:

```text
IRQ_ENABLE[0] = 1
```

followed by a `DATA_IN` write generates:

```text
IRQ = 1
```

**PASS**

### Test 7 — Interrupt Clear

Verified W1C behavior of `IRQ_STATUS`.

**PASS**

### Test 8 — AW Before W

Verified that the slave correctly handles the write address arriving before write data.

**PASS**

### Test 9 — W Before AW

Verified that the slave correctly handles write data arriving before the write address.

**PASS**

### Test 10 — Delayed BREADY

Verified that `BVALID` remains asserted until the master accepts the write response.

**PASS**

### Test 11 — Delayed RREADY

Verified that `RVALID` remains asserted until the master accepts the read response.

**PASS**

### Test 12 — Invalid Address

Verified that an unsupported address produces:

```text
BRESP = SLVERR
```

**PASS**

---

# ✅ Final Verification Result

```text
==============================================
          VERIFICATION SUMMARY
==============================================
TOTAL PASSED = 14
TOTAL FAILED = 0

==============================================
       ALL TESTS PASSED SUCCESSFULLY
==============================================
```

The simulation completed successfully without verification failures.

---

# 📊 Verification Coverage

The testbench verifies:

- AXI write transactions
- AXI read transactions
- Independent AW/W channel operation
- Write response generation
- Read response generation
- Byte strobes
- Register read/write behavior
- Interrupt generation
- Interrupt clearing
- Response back-pressure
- Invalid-address handling
- `SLVERR` response

---

# 📁 Repository Structure

```text
AXI4-Lite-Slave-RTL/
│
├── RTL/
│   └── axi4lite_slave.v
│
├── testvbench/
│   └── tb_axi4lite_slave.v
│
└── README.md
```

---

# 🛠️ Tools Used

- **Verilog HDL**
- **AMD Vivado 2020.2**
- **Vivado XSim**
- RTL simulation
- Waveform analysis

---

# 🎯 Key Learning Outcomes

This project provided practical experience with:

- AXI4-Lite protocol architecture
- Memory-mapped peripheral design
- RTL register implementation
- Ready/valid handshake protocols
- Independent AXI write channels
- Byte-enable logic
- Interrupt architecture
- Error-response generation
- Self-checking testbench development
- RTL simulation and waveform debugging

---

# 🚀 Future Improvements

Possible extensions include:

- UVM-based verification environment
- SystemVerilog Assertions (SVA)
- Functional coverage
- AXI protocol assertions
- Formal verification
- More extensive randomized testing
- Integration with an AXI master/processor
- FPGA hardware validation
- Parameterized register-map generation

---

## 👨‍💻 Author

**Vinay Kurre**

B.Tech Electrical Engineering  
IIT Hyderabad

GitHub: [VINAYKURREiith](https://github.com/VINAYKURREiith)

---

## 📜 License

This project is intended for educational and portfolio purposes.
