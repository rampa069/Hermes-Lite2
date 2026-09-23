# Hermes-Lite 2 Iambic CW Keyer

This variant is based on `hl2b5up_main` with the iambic CW keyer in the FPGA. It has 2 receivers instead of 4 to leave timing margin.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_main_iambic |
|---|---|---|
| `HL2_NR` | 4 | 2 |
| `HL2_CW` | 1 (straight key) | 2 (iambic keyer) |

With 4 receivers plus the keyer and DB1 sidetone the design used 96% of the LEs and failed setup timing on `clock_153p6MHz` (-0.082 ns). With 2 receivers and no DB1 sidetone it uses 78% of the LEs and meets timing on all corners.

## CW Keyer

The full iambic keyer from VK6PH (`rtl/iambic.v`) is enabled. The PTT/KEY phone connector is mapped as:

| Connector | FPGA Pin | Function |
|---|---|---|
| Phone tip | PIN_91 | Dot paddle |
| Phone ring | PIN_90 | Dash paddle |

The keyer operates entirely in the FPGA. SDR software only sends configuration parameters via OpenHPSDR command `0x0b`:

| cmd_data bits | Field | Range |
|---|---|---|
| [15:14] | keyer_mode | 00=straight/bug, 01=Mode A, 10=Mode B |
| [13:8] | keyer_speed | 1-60 WPM |
| [7] | letter_spacing | 0=off, 1=on |
| [6:0] | keyer_weight | 33-66 (nominal 50) |
| [22] | paddle_swap | 0=normal, 1=swap |

Additional commands: `0x0f` (CW PTT delay, sidetone volume/frequency), `0x10` (CW hang time), `0x11` (Mode B dot memory timing).

Users with a straight key can set `keyer_mode=00`; the dash paddle (ring) then acts as a straight key.

## Sidetone Output (disabled)

`HL2_SIDETONE_DB1` is not defined, so **DB1 pin 1** (FPGA PIN_72, `io_db1_1`) carries the TX envelope PWM output, as in `hl2b5up_main`. The `cw_sidetone` and `sigma_delta_dac` modules are still instantiated in `hermeslite_core.sv` for CW=2, but their output is unconnected and Quartus removes them.

To route the sidetone to DB1-1 again, add this to `hermeslite.qsf`:

```
set_global_assignment -name VERILOG_MACRO "HL2_SIDETONE_DB1=1"
```

Then connect an RC low-pass filter to DB1 (1 kΩ series, 10 nF to GND on pin 10, ~16 kHz cutoff) and add an audio amplifier if you want to drive a speaker. That adds logic, so check timing, especially with more receivers.

### DB1 Pin Reference (B5+)

| DB1 Pin | FPGA | Function in this variant |
|---|---|---|
| 1 | PIN_72 | TX envelope PWM |
| 2 | PIN_76 | UART RX |
| 3 | PIN_77 | UART TX |
| 4 | PIN_80 | Fan PWM |
| 5 | PIN_83 | ATU ACK (input) |
| 6 | PIN_85 | ATU REQ (output) |
| 8 | - | Vlvds |
| 10 | - | GND |

## RTL Support

These RTL changes support the iambic keyer and the optional sidetone output:

- `rtl/sigma_delta_dac.sv` - 1st-order sigma-delta modulator (16-bit input, 1-bit output at 76.8 MHz)
- `rtl/control.sv` - CW=2 without AK4951 now uses `cw_ptt` for transmitter keying; upstream status reports `cw_keydown` (keyer output) instead of raw paddle input
- `rtl/hermeslite_core.sv` - new `io_sidetone_out` port; instantiates `cw_sidetone` and `sigma_delta_dac` in the non-AK4951 branch when CW=2
- `rtl/hermeslite.v` - routes sidetone to `io_db1_1` only when `HL2_SIDETONE_DB1` is defined

### Signal path

```
Phone tip/ring → debounce → cw_openhpsdr (iambic keyer) → cw_keydown
                                                           ↓
                                                    radio.sv (CW TX)
```

## Building

```
cd variants/hl2b5up_main_iambic
make
```

Requires Quartus Prime Lite 23.1 or later.
