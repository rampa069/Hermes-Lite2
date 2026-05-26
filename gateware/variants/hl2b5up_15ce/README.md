# Hermes-Lite 2 (Beta 5+) EP4CE15

Variant for the smaller EP4CE15 FPGA (15K LEs instead of the standard EP4CE22 with 22K LEs). Reduced receiver count to fit the smaller device.

## Differences from hl2b5up_main

| Parameter | hl2b5up_main | hl2b5up_15ce |
|---|---|---|
| FPGA device | EP4CE22E22C8 | EP4CE15E22C8 |
| `HL2_NR` | 4 | 2 |
| `HL2_EXTENDED_DEBUG_RESP` | 1 | 0 |
| `CW_ENV_ROM` | defined | not defined |
| Location TCL | `location.tcl` | `location_ep4ce15.tcl` |

## Parameters

| Parameter | Value |
|---|---|
| `HL2_NR` | 2 (receivers) |
| `HL2_NT` | 1 (transmitter) |
| `HL2_CW` | 1 (straight key) |
| `HL2_ATU` | 1 |
| `HL2_UART` | 1 |
| `HL2_FAN` | 1 |
| `HL2_HL2LINK` | 1 |
| `HL2_AK4951` | 0 |
| `HL2_EXTENDED_DEBUG_RESP` | 0 |
| `HL2_BYPASS_VERSA` | 0 |

## Notes

- Targets the EP4CE15E22C8 (15K LE) instead of EP4CE22E22C8 (22K LE)
- Reduced to 2 receivers to fit the smaller FPGA
- Uses `location_ep4ce15.tcl` for pin assignments on the smaller device
- Otherwise full-featured (TX, UART, ATU, fan, CW, HL2LINK)

## Building

```
cd variants/hl2b5up_15ce
make
```

Requires Quartus Prime Lite 23.1 or later. Output: `build/hermeslite.rbf`, `build/hermeslite.jic`.
