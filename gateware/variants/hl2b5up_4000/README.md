# Hermes-Lite 2 (Beta 5+) HPSDR-4000 Protocol

Receive-only variant using the OpenHPSDR-4000 receiver protocol. 5 receivers with HPSDR-4000 format.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_4000 |
|---|---|---|
| `HL2_NR` | 4 | 5 |
| `HL2_NT` | 1 | 0 |
| `HL2_ATU` | 1 | 0 |
| `HL2_UART` | 1 | 0 |
| `HL2_FAN` | 1 | 0 |
| `HL2_CW` | 1 | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 1 | 0 |
| `HL2_DEBUG_4000` | not defined | 1 |
| Receiver | `receiver_nco.v` | `receiver_4000.v` |

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 5 (receivers) |
| `HL2_NT` | 0 (no transmitter) |
| `HL2_CW` | 0 |
| `HL2_ATU` | 0 |
| `HL2_UART` | 0 |
| `HL2_FAN` | 0 |
| `HL2_HL2LINK` | 1 |
| `HL2_AK4951` | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 0 |
| `HL2_BYPASS_VERSA` | 0 |
| `HL2_DEBUG_4000` | 1 |
| `CW_ENV_ROM` | 1 |

## Notes

- Uses `receiver_4000.v` for HPSDR-4000 protocol compatibility
- HL2LINK remains enabled (unlike other receive-only variants)
- No transmitter, UART, ATU, fan, or CW

## Building

```
cd variants/hl2b5up_4000
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`.
