# HL2 Gateware Build Log

## Resource Utilization

| | Original (`7472bd1`) | Fix warnings | Pre-VNA | VNA=0 | Fix warnings+timing | +Dither+Watchdog (`a6dc715`) | +TX Restored |
|---|---|---|---|---|---|---|---|
| **LEs** | 20,904 (94%) | 18,398 (82%) | 18,398 (82%) | 17,938 (80%) | 17,938 (80%) | 18,312 (82%) | 20,657 (93%) |
| **Registers** | — | — | 14,104 (63%) | 13,868 (61%) | 13,868 (61%) | 13,903 (62%) | 16,035 (72%) |
| **M9Ks** | — | — | — | — | 31 (47%) | 31 (47%) | 52 (79%) |
| **Memory bits** | — | — | 253,968 (42%) | 253,968 (42%) | 253,968 (42%) | 272,400 (45%) | 424,464 (70%) |
| **Mult 9-bit** | — | — | 88 (67%) | 88 (67%) | 88 (67%) | 88 (67%) | 92 (70%) |
| **PLLs** | — | — | 2 (50%) | 2 (50%) | 2 (50%) | 2 (50%) | 2 (50%) |
| **Timing worst (85C)** | -0.257 ns | -0.257 ns | -0.257 ns | -0.257 ns | **0.142 ns** | **0.142 ns** | -0.371 ns |

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

### Build: +Dither+Watchdog (`a6dc715`)
- Added `rtl/lfsr.v` — 23-bit LFSR dither module (8-bit output)
- Integrated LFSR dithering into `firfilt.v` (RX FIR MAC 36→24), `FirInterp8_1024.v` (TX FIR MAC 36→24 and 24→20), `CicInterpM5.v` (TX CIC output truncation)
- Added `rtl/tx_watchdog.v` — 32-bit counter, 153.6M cycle timeout (~2s @ 76.8MHz), monitors TX FIFO read activity
- Integrated watchdog in `hermeslite_core.sv` — gates `tx_en`/`cw_on` in AD9866 domain, CDC sync to `clk_ctrl`, gates `int_tx_on` in `control.sv`
- Result: 17,938 -> 18,312 LEs (+374), 13,868 -> 13,903 registers (+35), M9Ks unchanged at 31, memory bits 253,968 -> 272,400 (+18,432 from FIR coefficient ROM data)
- Timing unchanged (worst slack 0.142 ns at 85C on clock_153p6MHz)

### Build: Shared FIR ROMs (attempted, reverted)
- Attempted to share FIR coefficient ROMs across receivers using dual-port M9K (`firromH_dual.v`)
- Modified `firfilt.v`, `receiver_nco.v`, `radio.sv` to add `SHARED_ROM` parameter and external coefficient ports
- Build succeeded but **M9Ks increased from 31 to 35** (+4) instead of expected decrease
- Root cause: dual-port ROM overhead in Cyclone IV M9K blocks negated savings for NR=3 (only 3 receivers)
- **Reverted** to `a6dc715` — not worth the complexity for NR=3

### Build: TX Path Restored
- **Critical bug found**: commit `bde4c57` (rename .v→.sv refactor) accidentally deleted the entire TX state machine (~262 lines) from `radio.sv`
  - `tx_on`, `cw_on` were stuck at 0 — no TX output reached the DAC
  - TX FSM with states `NOTX`→`PRETX`→`PTTTX`/`CWTX`→`CWHANG` was missing
  - CW carrier generation, PTT hang, CW level envelope all gone
  - SSB appeared to work only because PA was enabled via `ext_ptt` path, but DAC was silent
- Restored `radio.sv` from original `7472bd1` with VNA parameter generate block re-applied
- **Resource impact of TX path**: +2,345 LEs, +2,132 registers, +21 M9Ks, +152K memory bits, +4 multipliers
- **Timing regression**: -0.371 ns at 85C (vs 0.142 ns without TX) — TX CORDIC path creates critical path on `clock_153p6MHz`
- At 93% LE utilization, very little headroom remains for additional features
