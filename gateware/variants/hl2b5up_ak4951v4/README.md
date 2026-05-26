# Hermes-Lite 2 (Beta 5+) AK4951 v4 Audio Codec

Variant with AK4951 audio codec support (version 4 codec board). Adds ATU support with combined ATU+AK4951 mode.

## Differences from hl2b5up_ak4951v3

| Parameter | hl2b5up_ak4951v3 | hl2b5up_ak4951v4 |
|---|---|---|
| `HL2_ATU` | 0 | 1 |
| `HL2_ATU_AK4951` | not defined | 1 |
| `HL2_FAN` | 1 | 0 |

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_ak4951v4 |
|---|---|---|
| `HL2_AK4951` | 0 | 1 |
| `AK4951` | not defined | 1 |
| `HL2_CW` | 1 | 2 (iambic) |
| `HL2_FAN` | 1 | 0 |
| `HL2_HL2LINK` | 1 | 0 |
| `HL2_ATU_AK4951` | not defined | 1 |

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 4 (receivers) |
| `HL2_NT` | 1 (transmitter) |
| `HL2_CW` | 2 (iambic keyer) |
| `HL2_ATU` | 1 |
| `HL2_UART` | 1 |
| `HL2_FAN` | 0 |
| `HL2_HL2LINK` | 0 |
| `HL2_AK4951` | 1 |
| `HL2_EXTENDED_DEBUG_RESP` | 0 |
| `HL2_BYPASS_VERSA` | 0 |
| `HL2_ATU_AK4951` | 1 |
| `CW_ENV_ROM` | 1 |

## Features

- AK4951 v4 audio codec with I2S interface
- ATU enabled with combined AK4951+ATU mode (HL2_ATU_AK4951=1)
- Iambic CW keyer (CW=2)
- UART debug port
- No fan control
- Uses `timing_ak4951.sdc`

## Building

```
cd variants/hl2b5up_ak4951v4
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`, `build/hermeslite.jic`.
