# Hermes-Lite 2 (Beta 5+) Main

This is the primary/reference variant for Hermes-Lite 2 Beta 5 and later hardware. Full-featured build with 4 receivers, transmitter, ATU, CW, UART, and HL2LINK.

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
| `HL2_BYPASS_VERSA` | 0 |
| `CW_ENV_ROM` | 1 |

## Features

- 4 NCO-based receivers with FIR filtering
- 1 transmitter with CW envelope ROM
- ATU (Automatic Tuner Unit) support
- UART debug port
- Fan control
- HL2LINK (Ethernet debug link)
- Extended debug response packets

## Building

```
cd variants/hl2b5up_main
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`, `build/hermeslite.jic`.
