# Radioberry Juice (Cyclone 10 LP 25K) FTDI

Radioberry Juice board variant with 10CL025 FPGA. Uses FTDI interface.

## Differences from radioberry_juice_cl016

| Parameter | radioberry_juice_cl016 | radioberry_juice_cl025 |
|---|---|---|
| FPGA device | 10CL016YE144C8G | 10CL025YE144C8G |
| `NR` | 3 | 6 |
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
| `FAN` | 1 |
| `FPGA_TYPE` | 2 (25K LE) |

## Features

- 6 NCO-based receivers (more than CL016 version's 3)
- 1 transmitter with power envelope control
- FTDI interface
- I2C bus
- Fan control
- CW straight key support
- Device: 10CL025YE144C8G (Cyclone 10 LP)

## Building

```
cd variants/radioberry_juice_cl025
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
