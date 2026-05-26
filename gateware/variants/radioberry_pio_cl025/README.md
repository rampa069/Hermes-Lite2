# Radioberry PIO (Cyclone 10 LP 25K)

Radioberry PIO variant with larger 10CL025 FPGA. Parallel I/O interface to Raspberry Pi.

## Differences from radioberry_pio_cl016

| Parameter | radioberry_pio_cl016 | radioberry_pio_cl025 |
|---|---|---|
| FPGA device | 10CL016YE144C8G | 10CL025YE144C8G |
| `NR` | 4 | 6 |
| `FPGA_TYPE` | 1 | 2 |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 6 (receivers) |
| `NT` | 1 (transmitter) |
| `CW` | 1 (straight key) |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |
| `FPGA_TYPE` | 2 (25K LE) |

## Features

- 6 NCO-based receivers (more than CL016 version's 4)
- 1 transmitter with power envelope control
- Parallel I/O interface to Raspberry Pi
- CW straight key support
- Device: 10CL025YE144C8G (Cyclone 10 LP)

## Building

```
cd variants/radioberry_pio_cl025
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
