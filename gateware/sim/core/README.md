# Hermes-Lite 2 full-core simulation

Board-level simulation of a Hermes-Lite 2 gateware variant with Verilator. The
`hermeslite` top is built from the same sources and `VERILOG_MACRO`s as the
variant's Quartus project; the Altera IP is replaced by behavioral models and
the board around the FPGA is modeled. A host model talks OpenHPSDR protocol 1
over UDP, like a PC program.

```
make                      # build and run the default test (boot)
make test T=rx            # run one test, log in run/<variant>/<test>.log
make regress              # all tests in parallel (JOBS=8), PASS/FAIL summary
make regress TESTS="rx tx"
make test T=tx ARGS=+verbose        # print every check
make wave T=boot          # VCD dump (large)
make VARIANT=hl2b5up_main test T=rx # another variant
```

Requirements: Verilator 5 (built and tested with 5.048), Python 3. No Quartus.

## Layout

| Path | Contents |
|---|---|
| `models/altera_sim_models.v` | altpll, altsyncram, dcfifo(_mixed_widths), scfifo, lpm_mult/compare/counter, a_graycounter, altshift_taps, altddio_in/out, altclkctrl, altsquare, altsqrt; stubs of the Cyclone IV ASMI and remote update blocks |
| `scripts/qsf2f.py` | source list and macros from the variant `.qsf` (follows `source` and `.qip`) |
| `scripts/rtl_compat.py` | simulation copies of RTL files that Verilator rejects (see below) |
| `scripts/mif2hex.py` | `.mif` ROM contents to `$readmemh` files |
| `tb/tb_hl2.sv` | board, host model (discovery, EP2 command scheduler and TX I/Q, EP6/EP4 parsing, ARP/ICMP/DHCP), signal analysis helpers |
| `tb/tests.svh` | the tests |
| `tb/phy_model.sv` | KSZ9031 PHY: RGMII at 1 Gb/s (FCS added/checked) and MDIO |
| `tb/ad9866_model.sv` | AD9866: ADC tone generator, DAC capture and envelope log, fast LNA gain on the TX pins, SPI registers |
| `tb/i2c_slave_model.sv` | Versa clock, MCP4662 EEPROM, MAX11613 ADC, MCP23008 filter board |

## Things to know

- The simulation build never modifies the RTL: `rtl_compat.py` writes rewritten copies to
  `build/<variant>/compat` and prints each rewrite when building. All of them
  keep the behavior; they are constructs Quartus accepts but the LRM does not:
  output ports without a data type assigned from `always` blocks, generate
  labels equal to a parameter name, `parameter X;` without default, parameters
  used before being declared, `'{default:'0}` initializers, literals like
  `80'h_0806`.
- Verilator is 2-state: registers start at 0, as the FPGA powers up.
- Fast boot: the 1 s network "settle" wait is cut short (`cfg_fast_boot`) once
  the EEPROM has been read. The watchdog test fast-forwards the watchdog
  counter.
- The remote update block is a stub; by default the testbench models the
  application image (`cfg_factory_image = 0`).
- I/Q convention (protocol 1): a signal above the tuned frequency comes out at
  a negative frequency when the samples are read as I + jQ; TX uses the same
  convention (`rx_sign`, `tx_sign` in `tests.svh`).
- Verilator 5.048 mishandles `push_back` on arrays of queues; the testbench
  uses queues of structs instead.

## Tests

| Test | What it checks |
|---|---|
| boot | reset sequence timing, MDIO PHY setup, Versa init, EEPROM reads, AD9866 SPI init, static IP |
| discovery | discovery reply contents, broadcast/unicast, port 1025, running flag |
| arp_icmp | ARP reply, ping with 32 and 1000 bytes |
| rx | 4 receivers at 192 ksps: tone frequency, level, image rejection, EP6 stream |
| rx_rates | 48/96/192/384 ksps |
| tx | TX I/Q to DAC: sideband, carrier/image suppression, level, PTT timing, PA/TR outputs |
| cw_iambic | paddles, iambic keyer, CW envelope on air, EP6 key/PTT bits, sidetone on DB1-1 |
| cw_straight | keyer mode 00 with the ring as straight key |
| cwx | CW keyed through the EP2 I samples: element lengths and gaps, second element from the CW hang |
| responses | EP6 C0-C4 slots, slow ADC values, ADC overload, TX inhibit bit |
| tx_inhibit | CN8 input |
| tx_glitch | DAC output at the start of a transmission |
| i2c_cmd | I2C through commands 0x3c/0x3d, command responses, filter board writes |
| ad9866_spi_busy | two AD9866 SPI commands in one EP2 packet |
| ad9866_spi_init | TX gain command arriving during the AD9866 SPI init sequence |
| lna_gain | fast LNA gain in RX/TX (FAST_LNA) |
| watchdog | bandscope/watchdog counter at start, tick cadence, stop without EP2, watchdog disable |
| dhcp | address from a DHCP server |
| eeprom_override | both paddles pressed at power up ignore the EEPROM IP config |
| reboot | command 0x3a |
| factory_boot, factory_hold | factory image jumps to the application image unless both paddles are pressed |
| wideband | EP4 raw ADC snapshots and cadence |
| fan | fan states from the temperature, overheat TX block |
