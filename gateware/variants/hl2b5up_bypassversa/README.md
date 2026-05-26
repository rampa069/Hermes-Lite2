# Hermes-Lite 2 (Beta 5+) Bypass Versa

Same as `hl2b5up_main` but bypasses the Versa configurable I/O clocking scheme. Uses an alternative clock routing approach.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_bypassversa |
|---|---|---|
| `HL2_BYPASS_VERSA` | 0 | 1 |

All other parameters are identical.

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 4 (receivers) |
| `HL2_NT` | 1 (transmitter) |
| `HL2_CW` | 1 (straight key) |
| `HL2_ATU` | 1 |
| `HL2_UART` | 1 |
| `HL2_FAN` | 1 |
| `HL2_HL2LINK` | 1 |
| `HL2_AK4951` | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 1 |
| `HL2_BYPASS_VERSA` | 1 |
| `CW_ENV_ROM` | 1 |

## Notes

- `HL2_BYPASS_VERSA=1` bypasses the standard Versa clocking scheme
- Use this variant if you experience clock issues with the standard Versa configuration
- Otherwise identical to hl2b5up_main

## Building

```
cd variants/hl2b5up_bypassversa
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`, `build/hermeslite.jic`.
