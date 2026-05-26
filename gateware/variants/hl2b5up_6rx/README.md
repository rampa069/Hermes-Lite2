# Hermes-Lite 2 (Beta 5+) 6-Receiver

Receive-only variant with 6 NCO-based receivers (full FIR filtering). Uses a specific fitter seed for timing closure.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_6rx |
|---|---|---|
| `HL2_NR` | 4 | 6 |
| `HL2_NT` | 1 | 0 |
| `HL2_ATU` | 1 | 0 |
| `HL2_UART` | 1 | 0 |
| `HL2_FAN` | 1 | 0 |
| `HL2_CW` | 1 | 0 |
| `HL2_HL2LINK` | 1 | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 1 | 0 |
| Fitter seed | default | 24398 |

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 6 (receivers) |
| `HL2_NT` | 0 (no transmitter) |
| `HL2_CW` | 0 |
| `HL2_ATU` | 0 |
| `HL2_UART` | 0 |
| `HL2_FAN` | 0 |
| `HL2_HL2LINK` | 0 |
| `HL2_AK4951` | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 0 |
| `HL2_BYPASS_VERSA` | 0 |
| `CW_ENV_ROM` | 1 |

## Notes

- Uses NCO-based receivers with full FIR filtering (not CIC-only)
- Specific fitter seed (24398) for timing closure with 6 receivers
- No transmitter, UART, ATU, fan, CW, or HL2LINK
- More receivers than the standard 4 but with full DSP processing

## Building

```
cd variants/hl2b5up_6rx
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`.
