# Radioberry Juice (Cyclone 10 LP 16K) FTDI

Radioberry Juice board variant with 10CL016 FPGA. Uses FTDI interface instead of SPI.

## Differences from radioberry_cl016

| Parameter | radioberry_cl016 | radioberry_juice_cl016 |
|---|---|---|
| Core | `radioberry_core` | `radioberry_juice_core` |
| Interface | SPI | FTDI |
| `NR` | 4 | 3 |
| `FAN` | not set | 1 |
| Board files | `boards/radioberry/` | `boards/radioberry-juice/` |
| I2C | no | yes |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 3 (receivers) |
| `NT` | 1 (transmitter) |
| `CW` | 1 (straight key) |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |
| `FAN` | 1 |
| `FPGA_TYPE` | 1 (16K LE) |

## Features

- 3 NCO-based receivers (fewer than SPI due to FTDI interface overhead)
- 1 transmitter with power envelope control
- FTDI interface (ftd_clk_60, ftd_data, FIFO signals)
- I2C bus (io_scl, io_sda)
- Fan control
- CW straight key support
- Device: 10CL016YE144C8G (Cyclone 10 LP)

## Building

```
cd variants/radioberry_juice_cl016
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
