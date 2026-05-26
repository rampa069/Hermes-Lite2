# Hermes-Lite 2 (Beta 2) Main

Variant for the Beta 2 hardware revision. Uses NCO-based receivers.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b2_main |
|---|---|---|
| Board macro | `BETA5` | `BETA2` |
| `HL2_ATU` | 1 | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 1 | 0 |
| `CW_ENV_ROM` | defined | not defined |
| Board files | `boards/hl2b5up/` | `boards/hl2b2/` |

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
cd variants/hl2b2_main
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`, `build/hermeslite.jic`.
