# Radioberry (Cyclone 10 LP 16K) SPI

Standard Radioberry variant with 10CL016 FPGA (16K LEs). SPI interface to Raspberry Pi.

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
- SPI interface to Raspberry Pi
- CW straight key support
- Device: 10CL016YE144C8G (Cyclone 10 LP)

## Building

```
cd variants/radioberry_cl016
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
