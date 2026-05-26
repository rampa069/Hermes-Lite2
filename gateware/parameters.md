# HL2 Gateware Parameters

## QSF Verilog Macros (per variant)

Set in each variant's `hermeslite.qsf` via `set_global_assignment -name VERILOG_MACRO`. These are the primary configuration knobs.

### Parameter macros (mapped to Verilog parameters via `hermeslite.v`)

| Macro | Values | Parameter | Description |
|---|---|---|---|
| `HL2_NR` | 2, 4, 5, 6, 10 | `NR` | Number of receivers |
| `HL2_NT` | 0, 1 | `NT` | Number of transmitters (0 = receive-only) |
| `HL2_CW` | 0, 1, 2 | `CW` | 0=none, 1=basic (straight key), 2=OpenHPSDR iambic keyer |
| `HL2_ATU` | 0, 1 | `ATU` | External antenna tuner support |
| `HL2_UART` | 0, 1 | `UART` | UART debug port (JI1UDD HR50 amplifier control) |
| `HL2_FAN` | 0, 1 | `FAN` | Fan control with temperature-based PWM |
| `HL2_HL2LINK` | 0, 1 | `HL2LINK` | HL2Link protocol (multi-HL2 coordination) |
| `HL2_AK4951` | 0, 1 | `AK4951` | AK4951 audio codec I2S support |
| `HL2_EXTENDED_DEBUG_RESP` | 0, 1 | `EXTENDED_DEBUG_RESP` | Debug response commands (sample_rate, receivers, cw_hang_time, etc.) |
| `HL2_BYPASS_VERSA` | 0, 1 | `BYPASS_VERSA` | Bypass Versa clock I2C configuration |

### Preprocessor macros (conditional compilation, NOT Verilog parameters)

| Macro | Used In | Description |
|---|---|---|
| `BETA2` | `hermeslite.v` | Board revision 2 I/O mapping |
| `BETA3` | `hermeslite.v` | Board revision 3-4 I/O mapping |
| `BETA5` | `hermeslite.v` | Board revision 5+ I/O mapping |
| `AK4951` | `hermeslite.v` | AK4951-specific I/O pin directions (separate from `HL2_AK4951` parameter) |
| `USE_ALTSYNCRAM` | IP/PLL files | RAM primitive selection |
| `CW_ENV_ROM` | `radio.sv` | Use ROM-based CW envelope shaping instead of linear ramp |
| `HL2_SIDETONE_DB1` | `hermeslite.v` | Route sidetone output to DB1 pin 1 (replaces TX envelope PWM) |
| `HL2_BANDV_YAESU` | `hermeslite.v`, `control.sv` | Force Yaesu band voltage output always-on; redirect fan PWM to DB1_3 |
| `HL2_ATU_AK4951` | `hermeslite.v` | Inverted ATU req/ack wiring for AK4951 v4 companion board |
| `HL2_DEBUG_4000` | `hermeslite.v` | Route debug[3:0] to IO pins for HPSDR-4000 |

## Top-Level (`hermeslite_core.sv`)

Set in `hermeslite.v` when instantiating `hermeslite_core`.

| Parameter | Default | hl2b5up_main | Type | Description |
|---|---|---|---|---|
| `BOARD` | 5 | 5 | int | Board revision: 2=Beta2, 3=Beta3-4, 5=Beta5+ |
| `IP` | `{0,0,0,0}` | `{0,0,0,0}` | 32-bit | Static IP address (when not using DHCP) |
| `MAC` | `{00,1c,c0,a2,13,dd}` | same | 48-bit | MAC address (5th byte varies by board: B2=`12`, B3=`23`, B5=`13`) |
| `NR` | 4 | 4 | int | Number of receivers (1-10) |
| `NT` | 1 | 1 | int | Number of transmitters (0 or 1). NT=0 disables TX entirely |
| `CLK_FREQ` | 76800000 | 76800000 | int | System clock frequency in Hz |
| `UART` | 0 | 1 | enum | 0=None, 1=JI1UDD HR50 amplifier control via UART |
| `ATU` | 0 | 1 | enum | 0=None, 1=External antenna tuner (mAT-125E etc.) |
| `FAN` | 0 | 1 | bool | Fan control FSM with temperature-based PWM |
| `PSSYNC` | 0 | 1 | bool | Power supply sync frequency output |
| `CW` | 0 | 1 | enum | 0=none, 1=basic (tip=dot, ring=PTT), 2=OpenHPSDR iambic keyer |
| `LRDATA` | 0 | 0 | enum | Downstream audio: 0=not used, 1=TX predistortion (DACLUTI/Q), 2=TX envelope PWM |
| `ASMII` | 0 | 1 | bool | Use ASMII for EEPROM configuration / remote firmware update |
| `HL2LINK` | 0 | 1 | bool | HL2Link protocol support |
| `FAST_LNA` | 0 | 1 | bool | Fast LNA setting, extended TX/RX gain values |
| `AK4951` | 0 | 0 | bool | AK4951 codec support (analog audio) |
| `VNA` | 1 | 1 | bool | VNA scanner (FPGA-based frequency sweep). 0=disabled saves ~460 LEs |
| `EXTENDED_RESP` | 1 | 1 | bool | Extended response protocol (I2C/AD9866 read-back to PC) |
| `EXTENDED_DEBUG_RESP` | 0 | 1 | bool | Debug response commands (sample_rate, receivers, cw_hang_time, etc.) |
| `DSIQ_FIFO_DEPTH` | 16384 | 16384 | int | Downstream IQ FIFO depth |
| `BYPASS_VERSA` | 0 | 0 | bool | Bypass Versa clock configuration |

### Hardcoded in `hermeslite.v` (not configurable per variant)

| Parameter | Value | Note |
|---|---|---|
| `PSSYNC` | 1 | Always enabled |
| `ASMII` | 1 | Always enabled |
| `FAST_LNA` | 1 | Always enabled |
| `EXTENDED_RESP` | 1 | Always enabled |

### Computed internally (`localparam`)

| Name | Value | Description |
|---|---|---|
| `VERSION_MAJOR` | `54` (B2), `74` (B3+) | Major firmware version byte |
| `VERSION_MINOR` | `102` | Minor firmware version byte |
| `TUSERWIDTH` | `16` (AK4951), `2` (no AK4951) | User data width for upstream IQ FIFO |

## Radio Sub-Module (`radio.sv`)

Passed from `hermeslite_core`. Some are local to `radio.sv`.

| Parameter | Default | Description |
|---|---|---|
| `NR` | 3 | Receivers (from top) |
| `NT` | 1 | Transmitters (from top) |
| `LRDATA` | 0 | Downstream audio mode (from top) |
| `VNA` | 0 | VNA scanner enable (from top) |
| `CLK_FREQ` | 76800000 | Clock frequency (from top) |
| `HL2LINK` | 0 | HL2Link (from top) |
| `RECEIVER2` | 0 | Alternate receiver2 architecture (local) |
| `QS1R` | 0 | QS1R receiver support (local) |
| `DEBUGRX` | 0 | Debug receiver output (local) |

### Preprocessor macro in `radio.sv`

| Macro | Effect |
|---|---|
| `CW_ENV_ROM` | Instantiates `cw_env_rom` for ROM-based CW envelope shaping instead of linear ramp from `tx_cwlevel` |

## Control Sub-Module (`control.sv`)

Passed from `hermeslite_core`.

| Parameter | Default | Description |
|---|---|---|
| `VERSION_MAJOR` | `0x00` | Major firmware version (overridden by `hermeslite_core`) |
| `UART` | 0 | UART type (from top) |
| `ATU` | 0 | ATU type (from top) |
| `FAN` | 0 | Fan support (from top) |
| `PSSYNC` | 0 | PS sync (from top) |
| `CW` | 0 | CW mode: 0=none, 1=basic, 2=OpenHPSDR/iambic |
| `FAST_LNA` | 0 | Fast LNA (from top) |
| `AK4951` | 0 | AK4951 codec (from top) |
| `EXTENDED_RESP` | 0 | Extended response (from top) |
| `BYPASS_VERSA` | 0 | Bypass versa (from top) |

### Preprocessor macro in `control.sv`

| Macro | Effect |
|---|---|
| `HL2_BANDV_YAESU` | Forces `band_volts_enabled` to always be 1, bypassing software command control |
