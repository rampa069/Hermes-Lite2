# Radioberry Juice (Cyclone 10 LP 16K) CIC Receive-Only

Receive-only Radioberry Juice variant with 10CL016 FPGA. Uses CIC-only receivers to maximize receiver count.

## Differences from radioberry_juice_cl016

| Parameter | radioberry_juice_cl016 | radioberry_juice_cl016_cicrx |
|---|---|---|
| `NR` | 3 | 8 |
| `NT` | 1 | 0 |
| Receiver | `receiver_nco.v` | `receiver_ciconly.v` |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 8 (receivers) |
| `NT` | 0 (no transmitter) |
| `CW` | 1 |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |
| `FAN` | 1 |
| `FPGA_TYPE` | 1 (16K LE) |

## Notes

- Receive-only, no transmitter
- Uses `receiver_ciconly.v` (CIC decimation only, no NCO/FIR)
- 8 receivers maximized from the 16K LE FPGA
- CW keyer input still active
- FTDI interface, I2C bus
- Device: 10CL016YE144C8G

## Building

```
cd variants/radioberry_juice_cl016_cicrx
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
