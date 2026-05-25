# Hermes-Lite 2 Iambic CW Keyer with Sidetone

This variant is based on `hl2b5up_main` with iambic CW keyer and local sidetone output.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_main_iambic |
|---|---|---|
| `HL2_CW` | 1 (straight key) | 2 (iambic keyer) |
| `HL2_SIDETONE_DB1` | not defined | 1 |
| Sidetone files | not included | cw_sidetone.v + sigma_delta_dac.sv |

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

## Sidetone Output (DB1-1)

A 1-bit sigma-delta DAC outputs sidetone audio on **DB1 pin 1** (FPGA PIN_72, `io_db1_1`). This replaces the TX envelope PWM output used in other variants.

The sidetone is active when CW TX is keyed and the sidetone volume (command `0x0f`, bits [23:16]) is non-zero.

### External Filter

Connect to DB1 as follows:

```
DB1 pin 1 (sidetone) ---[ 1kΩ ]---+---> audio out
                                   |
                                [ 10nF ]
                                   |
DB1 pin 10 (GND) -----------------+---> GND
```

- Cutoff frequency: ~16 kHz (well above audio range)
- The 3.3V FPGA output provides enough level for headphones or a small amplifier
- For speaker use, add an LM386 or similar audio amplifier after the RC filter

### DB1 Pin Reference (B5+)

| DB1 Pin | FPGA | Function in this variant |
|---|---|---|
| 1 | PIN_72 | **Sidetone audio output** |
| 2 | PIN_76 | UART RX |
| 3 | PIN_77 | UART TX |
| 4 | PIN_80 | Fan PWM |
| 5 | PIN_83 | ATU ACK (input) |
| 6 | PIN_85 | ATU REQ (output) |
| 8 | - | Vlvds |
| 10 | - | GND |

## RTL Changes

### New files

- `rtl/sigma_delta_dac.sv` - 1st-order sigma-delta modulator (16-bit input, 1-bit output at 76.8 MHz)

### Modified files

- `rtl/control.sv` - CW=2 without AK4951 now uses `cw_ptt` for transmitter keying; upstream status reports `cw_keydown` (keyer output) instead of raw paddle input
- `rtl/hermeslite_core.sv` - new `io_sidetone_out` port; instantiates `cw_sidetone` and `sigma_delta_dac` in the non-AK4951 branch when CW=2
- `rtl/hermeslite.v` - routes sidetone to `io_db1_1` when `HL2_SIDETONE_DB1` is defined

### Signal path

```
Phone tip/ring → debounce → cw_openhpsdr (iambic keyer) → cw_keydown
                                                           ↓
                                                    radio.sv (CW TX)
                                                           ↓
              cw_sidetone.v → sigma_delta_dac.sv → DB1-1 (sidetone out)
```

## Building

```
cd variants/hl2b5up_main_iambic
make
```

Requires Quartus Prime Lite 23.1 or later.
