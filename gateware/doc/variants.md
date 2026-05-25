# Hermes-Lite 2 Gateware Variants

All HL2 variants share a single RTL top-level wrapper (`rtl/hermeslite.v`).
Each variant is configured exclusively through its QSF file via `VERILOG_MACRO` definitions.

## HL2 Variants

| Variant | Board | FPGA | NR | NT | UART | ATU | FAN | CW | HL2LINK | AK4951 | EXT_DBG_RESP | BYPASS_VERSA | Receiver | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| hl2b2_main | BETA2 | EP4CE22E22C8 | 4 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | receiver_nco | Original Beta 2 hardware |
| hl2b3to4_main | BETA3 | EP4CE22E22C8 | 4 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | receiver_nco | Beta 3-4 standard |
| hl2b3to4_cicrx | BETA3 | EP4CE22E22C8 | 10 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | receiver_ciconly | RX-only 10ch CIC |
| hl2b5up_main | BETA5 | EP4CE22E22C8 | 4 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 1 | 0 | receiver_nco | Standard production build |
| hl2b5up_6rx | BETA5 | EP4CE22E22C8 | 6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | receiver_nco | RX-only 6ch, fixed SEED |
| hl2b5up_cicrx | BETA5 | EP4CE22E22C8 | 10 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | receiver_ciconly | RX-only 10ch CIC |
| hl2b5up_15ce | BETA5 | EP4CE15E22C8 | 2 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | receiver_nco | Smaller FPGA (15K LE) |
| hl2b5up_4000 | BETA5 | EP4CE22E22C8 | 5 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | receiver_4000 | RX 4000, debug on IO |
| hl2b5up_ak4951v3 | BETA5 | EP4CE22E22C8 | 4 | 1 | 1 | 0 | 1 | 2 | 0 | 1 | 0 | 0 | receiver_nco | AK4951 audio codec V3 |
| hl2b5up_ak4951v4 | BETA5 | EP4CE22E22C8 | 4 | 1 | 1 | 1 | 0 | 2 | 0 | 1 | 0 | 0 | receiver_nco | AK4951 V4 + ATU |
| hl2b5up_bypassversa | BETA5 | EP4CE22E22C8 | 4 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 1 | 1 | receiver_nco | Bypass Versa clocking |
| hl2b5up_ak4951v3_yaesu | BETA5 | EP4CE22E22C8 | 4 | 1 | 0 | 0 | 1 | 2 | 0 | 1 | 0 | 0 | receiver_nco | AK4951 V3 + Yaesu band voltage on DB9 |
| hl2b5up_ak4951v4_yaesu | BETA5 | EP4CE22E22C8 | 4 | 1 | 0 | 1 | 1 | 2 | 0 | 1 | 0 | 0 | receiver_nco | AK4951 V4 + ATU + Yaesu band voltage on DB9 |

## Radioberry Variants

Radioberry variants use separate RTL cores and are not part of the unified wrapper.

| Variant | Core | FPGA | Interface | NR | NT | CW | FPGA_TYPE | Notes |
|---|---|---|---|---|---|---|---|---|
| radioberry_cl016 | radioberry_core | 10CL016YE144C8G | SPI | 4 | 1 | 1 | 1 | Standard SPI 16K |
| radioberry_cl025 | radioberry_core | 10CL025YE144C8G | SPI | 4 | 1 | 1 | 2 | Standard SPI 25K |
| radioberry_cl016_4000 | radioberry_core | 10CL016YE144C8G | SPI | 6 | 0 | 0 | 1 | RX-only 4000, 16K |
| radioberry_cl025_4000 | radioberry_core | 10CL025YE144C8G | SPI | 8 | 0 | 0 | 2 | RX-only 4000, 25K |
| radioberry_juice_cl016 | radioberry_juice_core | 10CL016YE144C8G | FTDI | 3 | 1 | 1 | 1 | Juice/FTDI 16K |
| radioberry_juice_cl025 | radioberry_juice_core | 10CL025YE144C8G | FTDI | 6 | 1 | 1 | 2 | Juice/FTDI 25K |
| radioberry_juice_cl016_cicrx | radioberry_juice_core | 10CL016YE144C8G | FTDI | 8 | 0 | 1 | 1 | RX-only CIC 16K |
| radioberry_juice_cl025_cicrx | radioberry_juice_core | 10CL025YE144C8G | FTDI | 10 | 0 | 1 | 2 | RX-only CIC 25K |
| radioberry_pio_cl016 | radioberry_core | 10CL016YE144C8G | PIO | 4 | 1 | 1 | 1 | Parallel IO 16K |
| radioberry_pio_cl025 | radioberry_core | 10CL025YE144C8G | PIO | 6 | 1 | 1 | 2 | Parallel IO 25K |

## Parameter Reference

### Core Parameters (hermeslite_core)

| Parameter | Type | Default | Description |
|---|---|---|---|
| BOARD | int | 5 | Board revision (2=BETA2, 3=BETA3, 5=BETA5) |
| IP | 32-bit | 0.0.0.0 | Default IP address |
| MAC | 48-bit | 00:1c:c0:a2:XX:dd | Default MAC (XX varies by board) |
| NR | int | 4 | Number of receivers (2-10) |
| NT | int | 1 | Number of transmitters (0-1) |
| UART | int | 0 | UART type (0=none, 1=JI1UDD HR50) |
| ATU | int | 0 | ATU type (0=none, 1=JI1UDD ATU) |
| FAN | int | 0 | Fan support (0=none, 1=enabled) |
| PSSYNC | int | 0 | Power supply sync frequency |
| CW | int | 0 | CW support (0=none, 1=basic, 2=OpenHPSDR) |
| ASMII | int | 0 | Use ASMII for EEPROM |
| HL2LINK | int | 0 | HL2 Link support |
| FAST_LNA | int | 0 | Fast LNA setting support (always 1, hardcoded) |
| AK4951 | int | 0 | AK4951 audio codec |
| EXTENDED_RESP | int | 1 | Extended protocol response (always 1, hardcoded) |
| EXTENDED_DEBUG_RESP | int | 0 | Extended debug response |
| VNA | int | 1 | VNA scanner support (default 1, never overridden) |
| CLK_FREQ | int | 76800000 | Clock frequency in Hz (default, never overridden) |
| LRDATA | int | 0 | Downstream audio channel (0=not used, 1=predistortion, 2=TX envelope PWM) |
| DSIQ_FIFO_DEPTH | int | 16384 | DS IQ FIFO depth (default, never overridden) |
| BYPASS_VERSA | int | 0 | Bypass Versa clocking |

### QSF Feature Macros

| Macro | Affects | Description |
|---|---|---|
| BETA2 / BETA3 / BETA5 | Port list, pin mapping | Board revision selector |
| USE_ALTSYNCRAM | FIR filter RAM | Use altsyncram primitives |
| AK4951 | I2S wiring, i2c RTL | AK4951 codec I2S routing via link/DB1 pins |
| HL2_DEBUG_4000 | Debug outputs | Route debug[3:0] to io_db1_1/3/4/6 |
| HL2_ATU_AK4951 | ATU wiring | Inverted ATU req/ack for AK4951 V4 companion |
| CW_ENV_ROM | CW envelope | Raised cosine CW shaping ROM (omit for linear ramp) |

## Building

```bash
make              # Build all variants
make hl2          # Build only HL2 variants
make radioberry   # Build only Radioberry variants
make clean        # Clean build artifacts
make realclean    # Clean everything including db/
```
