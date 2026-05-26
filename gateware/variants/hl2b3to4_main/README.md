# Hermes-Lite 2 (Beta 3-4) Main

Variant for Beta 3 and Beta 4 hardware revisions. Uses NCO-based receivers.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b3to4_main |
|---|---|---|
| Board macro | `BETA5` | `BETA3` |
| `HL2_ATU` | 1 | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 1 | 0 |
| `CW_ENV_ROM` | defined | not defined |
| Board files | `boards/hl2b5up/` | `boards/hl2b3to4/` |

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 4 (receivers) |
| `HL2_NT` | 1 (transmitter) |
| `HL2_CW` | 1 (straight key) |
| `HL2_ATU` | 0 |
| `HL2_UART` | 1 |
| `HL2_FAN` | 1 |
| `HL2_HL2LINK` | 1 |
| `HL2_AK4951` | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 0 |
| `HL2_BYPASS_VERSA` | 0 |

## Building

```
cd variants/hl2b3to4_main
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`, `build/hermeslite.jic`.
