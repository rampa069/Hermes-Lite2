# HL2 Gateware Parameters

## Top-Level (hermeslite_core.sv)

Set in each variant's `hermeslite.v` when instantiating `hermeslite_core`.

| Parameter | Default | hl2b5up_main | Type | Description |
|---|---|---|---|---|
| `BOARD` | 5 | 5 | int | Board revision identifier |
| `IP` | `{0,0,0,0}` | `{0,0,0,0}` | 32-bit | Static IP address (when not using DHCP) |
| `MAC` | `{00,1c,c0,a2,13,dd}` | same | 48-bit | MAC address |
| `NR` | 4 | 4 | int | Number of receivers (1-6) |
| `NT` | 1 | 1 | int | Number of transmitters (0 or 1). NT=0 disables TX entirely |
| `CLK_FREQ` | 76800000 | — | int | System clock frequency in Hz |
| `UART` | 0 | 1 | enum | 0=None, 1=JI1UDD HR50 amplifier control via UART |
| `ATU` | 0 | 1 | enum | 0=None, 1=External antenna tuner (mAT-125E etc.) |
| `FAN` | 0 | 1 | bool | Fan control FSM with temperature-based PWM |
| `PSSYNC` | 0 | 1 | bool | Power supply sync frequency output |
| `CW` | 0 | 1 | bool | CW keyer support (iambic, basic) |
| `LRDATA` | 0 | 0 | enum | Downstream audio: 0=not used, 1=TX predistortion (DACLUTI/Q), 2=TX envelope PWM |
| `ASMII` | 0 | 1 | bool | Use ASMII for EEPROM configuration |
| `HL2LINK` | 0 | 1 | bool | HL2Link protocol support |
| `FAST_LNA` | 0 | 1 | bool | Fast LNA setting, extended TX/RX gain values |
| `AK4951` | 0 | 0 | bool | AK4951 codec support (analog audio) |
| `VNA` | 1 | **0** | bool | VNA scanner (FPGA-based frequency sweep). 1=enabled, 0=disabled saves ~460 LEs |
| `EXTENDED_RESP` | 1 | 1 | bool | Extended response protocol (I2C/AD9866 read-back to PC) |
| `EXTENDED_DEBUG_RESP` | 0 | 1 | bool | Debug response commands (sample_rate, receivers, cw_hang_time, etc.) |
| `DSIQ_FIFO_DEPTH` | 16384 | — | int | Downstream IQ FIFO depth |
| `BYPASS_VERSA` | 0 | — | bool | Bypass Versa clock configuration |

## Radio Sub-Module (radio.sv)

Passed from hermeslite_core. Some are local to radio.sv.

| Parameter | Default | Description |
|---|---|---|
| `NR` | 3 | Receivers (from top) |
| `NT` | 1 | Transmitters (from top) |
| `LRDATA` | 0 | Downstream audio mode (from top) |
| `VNA` | 1 | VNA scanner enable (from top) |
| `CLK_FREQ` | 76800000 | Clock frequency (from top) |
| `HL2LINK` | 0 | HL2Link (from top) |
| `RECEIVER2` | 0 | Alternate receiver2 architecture (local) |
| `QS1R` | 0 | QS1R receiver support (local) |
| `DEBUGRX` | 0 | Debug receiver output (local) |

## Control Sub-Module (control.sv)

Passed from hermeslite_core.

| Parameter | Default | Description |
|---|---|---|
| `VERSION_MAJOR` | 0x00 | Firmware version byte |
| `UART` | 0 | UART type (from top) |
| `ATU` | 0 | ATU type (from top) |
| `FAN` | 0 | Fan support (from top) |
| `PSSYNC` | 0 | PS sync (from top) |
| `CW` | 0 | CW support (from top) |
| `FAST_LNA` | 0 | Fast LNA (from top) |
| `AK4951` | 0 | AK4951 codec (from top) |
| `EXTENDED_RESP` | 0 | Extended response (from top) |
| `BYPASS_VERSA` | 0 | Bypass versa (from top) |
