# Hermes-Lite 2 (Beta 5+) AK4951 v3 Audio Codec

Variant with AK4951 audio codec support (version 3 codec board). Provides local audio I/O with I2S interface to the AK4951 codec and iambic CW keyer.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_ak4951v3 |
|---|---|---|
| `HL2_AK4951` | 0 | 1 |
| `AK4951` | not defined | 1 |
| `HL2_CW` | 1 (straight key) | 2 (iambic keyer) |
| `HL2_ATU` | 1 | 0 |
| `HL2_HL2LINK` | 1 | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 1 | 0 |
| SDC | `timing.sdc` | `timing_ak4951.sdc` |

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 4 (receivers) |
| `HL2_NT` | 1 (transmitter) |
| `HL2_CW` | 2 (iambic keyer) |
| `HL2_ATU` | 0 |
| `HL2_UART` | 1 |
| `HL2_FAN` | 1 |
| `HL2_HL2LINK` | 0 |
| `HL2_AK4951` | 1 |
| `HL2_EXTENDED_DEBUG_RESP` | 0 |
| `HL2_BYPASS_VERSA` | 0 |
| `CW_ENV_ROM` | 1 |

## Features

- AK4951 audio codec with I2S interface for local audio I/O
- Iambic CW keyer (CW=2)
- Sidetone through the AK4951 codec (no external DAC needed)
- UART debug port
- Fan control
- Uses `timing_ak4951.sdc` for AK4951-specific timing constraints

## Building

```
cd variants/hl2b5up_ak4951v3
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`, `build/hermeslite.jic`.
