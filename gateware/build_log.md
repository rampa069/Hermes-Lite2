# HL2 Gateware Build Log

## Resource Utilization

| | Original (`7472bd1`) | Fix warnings | Pre-VNA | VNA=0 | Fix warnings+timing |
|---|---|---|---|---|---|
| **LEs** | 20,904 (94%) | 18,398 (82%) | 18,398 (82%) | 17,938 (80%) | 17,938 (80%) |
| **Registers** | — | — | 14,104 (63%) | 13,868 (61%) | 13,868 (61%) |
| **Memory bits** | — | — | 253,968 / 608,256 (42%) | 253,968 / 608,256 (42%) | 253,968 (42%) |
| **Mult 9-bit** | — | — | 88 / 132 (67%) | 88 / 132 (67%) | 88 (67%) |
| **PLLs** | — | — | 2 / 4 (50%) | 2 / 4 (50%) | 2 (50%) |
| **Timing worst (85C)** | -0.257 ns | -0.257 ns | -0.257 ns | -0.257 ns | **0.142 ns** |
| **Timing 153.6MHz** | 0.106 ns | 0.106 ns | 0.106 ns | 0.111 ns | 0.142 ns |
| **Timing ethrxintfast** | 0.118-0.244 ns | — | 0.022 ns | 0.022 ns | — |

## Warnings Status

### Fixed (no longer appear)
- Implicit nets: `atu_txinhibit_ad9866sync` (typo in hermeslite_core.sv), `to_ip_is_me`, `tx_request/tx_active/tx_data/length` in network.v
- Truncation: network.v, dsopenhpsdr1.sv, usopenhpsdr1.sv, radio.sv (accumdelay), vna_scanner.sv, firfilt.v, FirInterp8_1024.v, control.sv (fan_cnt), i2c_master.sv, extamp.v
- `txsumq` assigned but never read (moved inside generate case LRDATA=1)
- `cmd_ack` no driver (added default value `= 1'b0`)
- Latches on `fan_output`/`temp_enabletx` in control.sv (added else branch)
- control.sv VOLT_* truncation 32->12 (added mask `& ((2**DAC_BITS)-1)`)

### New warnings from VNA=0
- **radio.sv:432** — `tx0_phase` assigned but never read (declared outside generate, only used inside VNA1)
- **radio.sv:437** — `cordic_data_I/Q` assigned but never read (same reason)

### Remaining (benign)
1. **radio.sv** — output ports no driver: `cw_on`, `cw_profile`, `tx_tready`, `tx_twait` (from LRDATA=0 case)
2. **radio.sv** — nets no driver: `tx_on`, `rx_data_i[4..9]`, `rx_data_q[4..9]`, `tx_cordic_i_out[13..2]`
3. **radio.sv:432,437** — `tx0_phase`, `cordic_data_I/Q` assigned but never read (VNA=0, signals only used inside generate)
4. **i2c_master.sv:285-286** — `scl_posedge`/`scl_negedge` assigned but never read
5. **slow_adc.sv:134** — incomplete case statement (no default)
6. **ad9866ctrl.sv:81** — `rx_gain_next` assigned but never read
7. **ad9866ctrl.sv:67** — `initarray` no driver (RAM inference side-effect)
8. **coarserom.v:14** — `rom` no driver (ROM inference side-effect)
9. **asmi_asmi_parallel_0.sv:132** — `illegal_write_prot_reg` assigned but never read (Altera IP)
10. **PLL clk[2]** port not connected; SDC constraints ignored for clk[2], clk[3], clock_245p76MHz, clock_48khz
11. **6 input pins** don't drive logic; output pins stuck at VCC/GND
12. **NUM_PARALLEL_PROCESSORS** not specified

## Changes Summary

### Build: Fix warnings
- `.v` -> `.sv` rename for SystemVerilog files (65 files), updated 7 `files.tcl` + 21 `.qsf`
- Fixed implicit nets, truncations, latches across 10+ files
- Result: 20,904 -> 18,398 LEs (-2,506, from 94% to 82%)

### Build: Pre-VNA
- Same as Fix warnings build (control.sv VOLT_* fix applied after this build)

### Build: VNA=0
- Added `parameter VNA = 1` to hermeslite_core.sv, passed to radio.sv
- `generate if(VNA)` wraps vna_scanner and associated mux logic
- `hermeslite.v`: `.VNA(0)` disables VNA scanner
- Result: 18,398 -> 17,938 LEs (-460), 14,104 -> 13,868 registers (-236)
- VNA scanner saved only 460 LEs (less than expected — most logic was already optimized)
