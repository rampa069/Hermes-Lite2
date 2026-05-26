# Hermes-Lite 2 (Beta 3-4) CIC Receive-Only

Receive-only variant for Beta 3-4 hardware. Maximizes receiver count to 10 by using CIC-only receivers (no FIR filtering/NCO).

## Differences from hl2b3to4_main

| Parameter | hl2b3to4_main | hl2b3to4_cicrx |
|---|---|---|
| `HL2_NR` | 4 | 10 |
| `HL2_NT` | 1 | 0 |
| `HL2_UART` | 1 | 0 |
| `HL2_CW` | 1 | 0 |
| `HL2_HL2LINK` | 1 | 0 |
| Receiver | `receiver_nco.v` | `receiver_ciconly.v` |
| Location TCL | `location.tcl` | `location_10rx.tcl` |

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 10 (receivers) |
| `HL2_NT` | 0 (no transmitter) |
| `HL2_CW` | 0 |
| `HL2_ATU` | 0 |
| `HL2_UART` | 0 |
| `HL2_FAN` | 1 |
| `HL2_HL2LINK` | 0 |
| `HL2_AK4951` | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 0 |
| `HL2_BYPASS_VERSA` | 0 |

## Notes

- No transmitter, UART, CW, or HL2LINK
- Uses `receiver_ciconly.v` which provides CIC decimation only (no NCO/FIR)
- Uses `location_10rx.tcl` for 10-receiver pin assignments
- Pure receive-only SDR mode

## Building

```
cd variants/hl2b3to4_cicrx
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`.
