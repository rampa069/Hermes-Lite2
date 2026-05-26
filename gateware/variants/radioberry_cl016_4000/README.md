# Radioberry (Cyclone 10 LP 16K) HPSDR-4000

Receive-only Radioberry variant with 10CL016 FPGA using the HPSDR-4000 receiver protocol.

## Differences from radioberry_cl016

| Parameter | radioberry_cl016 | radioberry_cl016_4000 |
|---|---|---|
| `NR` | 4 | 6 |
| `NT` | 1 | 0 |
| `CW` | 1 | 0 |
| `FPGA_TYPE` | 1 | not set |
| Receiver | `receiver_nco.v` | `receiver_4000.v` |
| Power envelope | yes | no |

## Parameters

| Parameter | Value |
|---|---|
| `NR` | 6 (receivers) |
| `NT` | 0 (no transmitter) |
| `CW` | 0 |
| `UART` | 0 |
| `ATU` | 0 |
| `VNA` | 0 |

## Notes

- Receive-only, no transmitter or CW
- Uses `receiver_4000.v` for HPSDR-4000 protocol compatibility
- No power envelope pins
- Device: 10CL016YE144C8G

## Building

```
cd variants/radioberry_cl016_4000
make
```

Requires Quartus Prime Lite. Output: `build/radioberry.rbf`.
