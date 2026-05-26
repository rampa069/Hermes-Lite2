# Radioberry (Cyclone 10 LP 25K) SPI

Standard Radioberry variant with 10CL025 FPGA (25K LEs). SPI interface to Raspberry Pi.

## Differences from radioberry_cl016

| Parameter | radioberry_cl016 | radioberry_cl025 |
|---|---|---|
| FPGA device | 10CL016YE144C8G | 10CL025YE144C8G |
| `FPGA_TYPE` | 1 | 2 |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 4 (receivers) |
| `NT` | 1 (transmitter) |
| `CW` | 1 (straight key) |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |
| `FPGA_TYPE` | 2 (25K LE) |

## Features

- 4 NCO-based receivers with FIR filtering
- 1 transmitter with power envelope control
- SPI interface to Raspberry Pi
- CW straight key support
- Device: 10CL025YE144C8G (Cyclone 10 LP)

## Building

```
cd variants/radioberry_cl025
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
