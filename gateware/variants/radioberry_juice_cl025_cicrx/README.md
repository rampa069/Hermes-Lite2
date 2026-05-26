# Radioberry Juice (Cyclone 10 LP 25K) CIC Receive-Only

Maximum-receiver Radioberry Juice variant with 10CL025 FPGA. Uses CIC-only receivers for 10 receive channels.

## Differences from radioberry_juice_cl025

| Parameter | radioberry_juice_cl025 | radioberry_juice_cl025_cicrx |
|---|---|---|
| `NR` | 6 | 10 |
| `NT` | 1 | 0 |
| Receiver | `receiver_nco.v` | `receiver_ciconly.v` |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 10 (receivers) |
| `NT` | 0 (no transmitter) |
| `CW` | 1 |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |
| `FAN` | 1 |
| `FPGA_TYPE` | 2 (25K LE) |

## Notes

- Receive-only, no transmitter
- Uses `receiver_ciconly.v` (CIC decimation only, no NCO/FIR)
- 10 receivers -- maximum receiver count across all variants
- CW keyer input still active
- FTDI interface, I2C bus
- Device: 10CL025YE144C8G

## Building

```
cd variants/radioberry_juice_cl025_cicrx
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
