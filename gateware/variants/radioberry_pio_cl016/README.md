# Radioberry PIO (Cyclone 10 LP 16K)

Radioberry variant using parallel I/O (PIO) interface to Raspberry Pi instead of SPI. 10CL016 FPGA.

## Differences from radioberry_cl016

| Parameter | radioberry_cl016 | radioberry_pio_cl016 |
|---|---|---|
| Interface | SPI | Parallel I/O |
| Core RTL | `radioberry_core` (standard) | `radioberry_core` (PIO-specific) |
| RX data bus | 8-bit | 4-bit |
| Board files | `boards/radioberry/` | `boards/radioberry-pio/` |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 4 (receivers) |
| `NT` | 1 (transmitter) |
| `CW` | 1 (straight key) |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |
| `FPGA_TYPE` | 1 (16K LE) |

## Features

- 4 NCO-based receivers with FIR filtering
- 1 transmitter with power envelope control
- Parallel I/O interface to Raspberry Pi (pi_tx_clk, pi_tx_data, pi_tx_ready, pi_rx_clk, pi_rx_samples, pi_rx_data[3:0])
- 4-bit RX data bus (narrower than 8-bit SPI)
- CW straight key support
- Device: 10CL016YE144C8G (Cyclone 10 LP)

## Building

```
cd variants/radioberry_pio_cl016
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
