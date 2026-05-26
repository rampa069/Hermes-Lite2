# Radioberry (Cyclone 10 LP 25K) HPSDR-4000

Receive-only Radioberry variant with 10CL025 FPGA using the HPSDR-4000 receiver protocol.

## Differences from radioberry_cl025

| Parameter | radioberry_cl025 | radioberry_cl025_4000 |
|---|---|---|
| `NR` | 4 | 8 |
| `NT` | 1 | 0 |
| `CW` | 1 | 0 |
| `FPGA_TYPE` | 2 | not set |
| Receiver | `receiver_nco.v` | `receiver_4000.v` |
| Power envelope | yes | no |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 8 (receivers) |
| `NT` | 0 (no transmitter) |
| `CW` | 0 |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |

## Notes

- Receive-only, no transmitter or CW
- Uses `receiver_4000.v` for HPSDR-4000 protocol compatibility
- 8 receivers on the larger 25K LE FPGA (vs 6 on the 16K LE variant)
- No power envelope pins
- Device: 10CL025YE144C8G

## Building

```
cd variants/radioberry_cl025_4000
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
