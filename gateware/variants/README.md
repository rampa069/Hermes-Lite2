# Hermes-Lite 2 / Radioberry Gateware Variants

Each subdirectory contains a build variant with its own Quartus project files and Makefile.

## Hermes-Lite 2 Variants (Cyclone IV E)

| Variant | Device | RX | TX | CW | ATU | UART | Fan | AK4951 | HL2LINK | Receiver | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [hl2b2_main](hl2b2_main/) | EP4CE22 | 4 | 1 | 1 | 0 | 1 | 1 | 0 | 1 | NCO | Beta 2 hardware |
| [hl2b3to4_main](hl2b3to4_main/) | EP4CE22 | 4 | 1 | 1 | 0 | 1 | 1 | 0 | 1 | NCO | Beta 3-4 hardware |
| [hl2b3to4_cicrx](hl2b3to4_cicrx/) | EP4CE22 | 10 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | CIC-only | RX-only, Beta 3-4 |
| [hl2b5up_main](hl2b5up_main/) | EP4CE22 | 4 | 1 | 1 | 1 | 1 | 1 | 0 | 1 | NCO | **Reference build** |
| [hl2b5up_main_iambic](hl2b5up_main_iambic/) | EP4CE22 | 4 | 1 | 2 | 1 | 1 | 1 | 0 | 1 | NCO | Iambic keyer + sidetone |
| [hl2b5up_cicrx](hl2b5up_cicrx/) | EP4CE22 | 10 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | CIC-only | RX-only |
| [hl2b5up_6rx](hl2b5up_6rx/) | EP4CE22 | 6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | NCO | RX-only, 6 NCO receivers |
| [hl2b5up_4000](hl2b5up_4000/) | EP4CE22 | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 4000 | HPSDR-4000 protocol |
| [hl2b5up_15ce](hl2b5up_15ce/) | EP4CE15 | 2 | 1 | 1 | 1 | 1 | 1 | 0 | 1 | NCO | Smaller 15K LE FPGA |
| [hl2b5up_bypassversa](hl2b5up_bypassversa/) | EP4CE22 | 4 | 1 | 1 | 1 | 1 | 1 | 0 | 1 | NCO | Bypass Versa clocking |
| [hl2b5up_ak4951v3](hl2b5up_ak4951v3/) | EP4CE22 | 4 | 1 | 2 | 0 | 1 | 1 | 1 | 0 | NCO | AK4951 v3 codec |
| [hl2b5up_ak4951v3_yaesu](hl2b5up_ak4951v3_yaesu/) | EP4CE22 | 4 | 1 | 2 | 0 | 0 | 1 | 1 | 0 | NCO | AK4951 v3 + Yaesu bandV |
| [hl2b5up_ak4951v4](hl2b5up_ak4951v4/) | EP4CE22 | 4 | 1 | 2 | 1 | 1 | 0 | 1 | 0 | NCO | AK4951 v4 + ATU |
| [hl2b5up_ak4951v4_yaesu](hl2b5up_ak4951v4_yaesu/) | EP4CE22 | 4 | 1 | 2 | 1 | 0 | 1 | 1 | 0 | NCO | AK4951 v4 + Yaesu + ATU |

## Radioberry Variants (Cyclone 10 LP)

| Variant | Device | RX | TX | CW | Interface | Receiver | Notes |
|---|---|---|---|---|---|---|---|
| [radioberry_cl016](radioberry_cl016/) | 10CL016 | 4 | 1 | 1 | SPI | NCO | Standard, 16K LE |
| [radioberry_cl025](radioberry_cl025/) | 10CL025 | 4 | 1 | 1 | SPI | NCO | Standard, 25K LE |
| [radioberry_cl016_4000](radioberry_cl016_4000/) | 10CL016 | 6 | 0 | 0 | SPI | 4000 | RX-only, HPSDR-4000 |
| [radioberry_cl025_4000](radioberry_cl025_4000/) | 10CL025 | 8 | 0 | 0 | SPI | 4000 | RX-only, HPSDR-4000 |
| [radioberry_juice_cl016](radioberry_juice_cl016/) | 10CL016 | 3 | 1 | 1 | FTDI | NCO | Juice board |
| [radioberry_juice_cl025](radioberry_juice_cl025/) | 10CL025 | 6 | 1 | 1 | FTDI | NCO | Juice board |
| [radioberry_juice_cl016_cicrx](radioberry_juice_cl016_cicrx/) | 10CL016 | 8 | 0 | 1 | FTDI | CIC-only | RX-only |
| [radioberry_juice_cl025_cicrx](radioberry_juice_cl025_cicrx/) | 10CL025 | 10 | 0 | 1 | FTDI | CIC-only | Max receivers |
| [radioberry_pio_cl016](radioberry_pio_cl016/) | 10CL016 | 4 | 1 | 1 | PIO | NCO | Parallel I/O |
| [radioberry_pio_cl025](radioberry_pio_cl025/) | 10CL025 | 6 | 1 | 1 | PIO | NCO | Parallel I/O |

## Key Parameters

| Parameter | Meaning |
|---|---|
| `HL2_NR` / `NR` | Number of receivers |
| `HL2_NT` / `NT` | Number of transmitters (0 = receive-only) |
| `HL2_CW` / `CW` | 0=off, 1=straight key, 2=iambic keyer |
| `HL2_ATU` | Automatic Tuner Unit |
| `HL2_UART` | UART debug port |
| `HL2_FAN` | Fan control |
| `HL2_AK4951` | AK4951 audio codec |
| `HL2_HL2LINK` | Ethernet debug link |
| `HL2_BYPASS_VERSA` | Bypass Versa clocking |
| `HL2_BANDV_YAESU` | Yaesu band voltage output |
| `HL2_SIDETONE_DB1` | Sidetone output on DB1 |
| `CW_ENV_ROM` | CW envelope ROM table |
| `FPGA_TYPE` | 1=16K LE, 2=25K LE (Radioberry) |

## Receiver Types

| Type | Description |
|---|---|
| NCO | Full NCO + FIR filtering (standard) |
| CIC-only | CIC decimation only, no NCO/FIR (maximizes receiver count) |
| 4000 | OpenHPSDR-4000 protocol format |

## Building

Build a single variant:
```
cd variants/<variant_name>
make
```

Build all variants:
```
cd variants
make            # all
make hl2        # HL2 only
make radioberry # Radioberry only
```

Requires Quartus Prime Lite 23.1 or later.
