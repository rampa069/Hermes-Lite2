# Saturn vs Hermes-Lite2 HDL Module Comparison

**Saturn:** Xilinx Artix-7 XC7A200T, PCIe XDMA, Thetis SDR
**Hermes-Lite2:** Intel Cyclone IV, Ethernet, OpenHPSDR Protocol 1

---

## Directly Reusable Saturn Modules (pure RTL, no Xilinx dependencies)

| Module | Use for HL2 refactoring |
|--------|-------------------------|
| `lfsr.v` | Dithering for CORDIC/FIR truncation (spur reduction) |
| `pwm_dac.v` | Generic 8-bit PWM DAC |
| `clockdivider.v` | Generic clock divider with terminal count |
| `cvt_offsetbinary.v` | 2's complement to offset binary for DAC |
| `activitywatchdog.v` | TX safety watchdog (cancels TX on FIFO inactivity) |
| `I2S_rcv/xmit/clk_lrclk_gen` | Full I2S audio, vendor-neutral |
| `Attenuator.v` | Serial attenuator driver (if HW requires it) |

## Reusable with Adaptation

| Module | What to adapt |
|--------|---------------|
| `cw_key_ramp.v` | Excellent concept (CW envelope with BRAM waveshape). Adapt BRAM interface to Cyclone IV M9K. HL2 currently uses hard keying |
| `axi_stream_interleaver/deinterleaver` | Interleaving logic is portable. Rename AXI-Stream signals to simple valid/ready |
| `cordic.v` (Saturn) | Same VE3NEA algorithm, wider path (18-in/24-out). Strip AXI-Stream wrapper |

## NOT Reusable (PCIe/Xilinx architecture specific)

- `stream_reader_writer.v` — AXI4 to AXI-Stream bridge for XDMA
- `wideband_collect.v` — Wideband capture with AXI4-Lite
- `DDCMux.v` — 10-channel DDC mux, tightly coupled to Xilinx DMA
- All AXI-Lite registers (`axil_*`, `axi_cfg_register`)

---

## Key Discrepancies

### 1. CW Keyer
- **Saturn:** 10-state FSM, CWX+IO8 inputs, clken-based, internal delay computation
- **HL2:** 16-state FSM, PTT delay (0-255 ms), hang time, Mode B memory inhibit, external delays
- **Decision:** Keep HL2 version (strict superset of Saturn)

### 2. CORDIC
- **Saturn:** AXI-Stream wrapped, 18-in/24-out, 21 stages, async reset
- **HL2:** 3 variants — `cordic.v` (12/18, basic), `cpl_cordic.v` (16/23, complex input), `recv2_cordic.v` (16/22, reset)
- All share the same VE3NEV algorithm and arctan lookup table
- **Decision:** Keep HL2 variants (tuned for specific use cases)

### 3. CIC Filters
- **Saturn:** No CIC modules in source (uses Xilinx CIC Compiler IP)
- **HL2:** Full CIC chain in pure RTL — `cic.v`, `cic_comb.v`, `cic_integrator.v`, `varcic.v`, `recv2_cic.v`
- **Decision:** Keep HL2. Use `recv2_cic.v` as the cleanest template (`$clog2`, auto-computed widths)

### 4. FIR Filters
- **Saturn:** No FIR modules in source (uses Xilinx FIR Compiler IP)
- **HL2:** Polyphase FIR in RTL — `firfilt.v` (976-tap decimate-by-8), `FirInterp8_1024.v`, `FirInterp5_1025_EER.v`
- HL2 FIR uses Quartus ROM/RAM wrappers (Intel-specific)
- **Decision:** Keep HL2. Algorithm is portable, only ROM/RAM wrappers are vendor-specific

### 5. Dithering
- **Saturn:** Uses LFSR (`lfsr.v`, 22-bit, 8-bit output) for TX dithering
- **HL2:** No dithering present
- **Opportunity:** Add LFSR dithering to HL2 CORDIC/FIR truncation

### 6. CW Envelope
- **Saturn:** Sophisticated shaped envelope via `cw_key_ramp.v` (BRAM wavetable, ramp-up/down, dwell, hang)
- **HL2:** Hard keying (on/off only)
- **Opportunity:** Add shaped CW envelope inspired by Saturn's approach

### 7. TX Watchdog
- **Saturn:** `activitywatchdog.v` monitors FIFO activity, cancels TX after timeout
- **HL2:** No TX watchdog
- **Opportunity:** Add TX safety watchdog

---

## Refactoring Improvement Opportunities

1. **Add dithering** using Saturn's `lfsr.v` at CORDIC/FIR truncation points
2. **Add shaped CW envelope** inspired by `cw_key_ramp.v` (BRAM wavetable approach)
3. **Add TX watchdog** using `activitywatchdog.v` (cancel TX on FIFO starvation)
4. **Use `recv2_cic.v`** as the template for all new CIC implementations (cleanest code with `$clog2`)
5. **Consider `pwm_dac.v`** for any analog control voltage needs
6. **Consider I2S modules** if audio codec support is expanded beyond AK4951
7. **Share FIR coefficient ROMs across receivers** — Currently each of the 4 receivers instantiates its own `firromH` (256x18, 4608 bits) for each of 4 sub-filter banks (AE/BF/CG/DH), totaling 16 ROM instances (~73K bits). Since all receivers use identical coefficients (`coefL4AE/BF/CG/DH.mif`), these could be shared via a single set of ROMs with multi-port access or time-multiplexed reads. This would save ~8-12 M9K blocks (25-38% of total BRAM). Current BRAM usage: 31/66 M9Ks (47%), with FIR consuming ~87% of all block memory bits (147K RAM + 74K ROM of 254K total)

---

## Vendor Dependency Summary

| Category | Vendor-neutral | Intel-specific | Xilinx-specific |
|----------|---------------|----------------|-----------------|
| CORDIC | All variants | — | — |
| CIC | All modules | — | — |
| FIR | Algorithm only | ROM/RAM wrappers | — |
| CW Keyer | `iambic.v`, `cw_basic.sv`, `cw_openhpsdr.sv` | `cw_sidetone.v` (multipliers) | — |
| Protocol | `dsopenhpsdr1.sv`, `usopenhpsdr1.sv` | — | — |
| FIFOs | — | `fifos.sv` (dcfifo) | — |
| AXI infrastructure | — | — | `stream_reader_writer`, `axil_*`, `DDCMux` |
| Utilities | `lfsr`, `pwm_dac`, `clockdivider`, `activitywatchdog`, `cvt_offsetbinary` | — | — |
