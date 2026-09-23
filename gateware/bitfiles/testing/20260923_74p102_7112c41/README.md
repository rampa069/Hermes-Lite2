Hermes-Lite 2.x Gateware
========================

## 20260923_74p102_7112c41 Testing Release

This is a testing release of gateware 74.102. Changes since 74.2:

### Fixes

* AD9866 control: TX gain, RX gain and register write commands are queued as pending SPI writes, so commands that arrive during the AD9866 init sequence or during another SPI transfer are no longer lost.
* AD9866 TX: no TX transaction completion (txsync) on the first word after TX is enabled, which still held the RX gain word.
* TX inhibit: the external TX inhibit input (CN8) and the overheat protection now also disable the AD9866 transmitter, not only the PA, T/R relay and bias. Before, only ATU tune did.
* CW keying: only an external key without PTT is delayed and extended by the TX buffer latency. CWX keys come out of the TX FIFO already delayed and now key immediately.
* Protocol 1: the default TX buffer latency (20 ms) and PTT hang time (12 ms) now match radio.sv. The bandscope counter saturates at 0 instead of wrapping to 127.

### New

* Raised cosine (sin²) CW envelope from a lookup table (`CW_ENV_ROM`) instead of the linear ramp, to reduce key clicks. Rise time is about 4 ms and peak power is unchanged.
* New variant hl2b5up_main_iambic: iambic CW keyer in the FPGA (VK6PH keyer, Mode A/B, 1-60 WPM), with 2 receivers.
* Yaesu band-voltage variants for the HamGeek PA-100 amplifier (hl2b5up_ak4951v3_yaesu, hl2b5up_ak4951v4_yaesu). These are not included in this release.

### Build

* All variants were built with Quartus Prime Lite 21.1.1.
* Timing is met on all corners for every variant in this release except hl2b2_main (see below). Some variants use a fixed fitter seed (`SEED` in the .qsf) for this.
* hl2b2_main: output `rffe_ad9866_tx[4]` (PIN_7) fails setup by 1.6 ns at the slow 85C corner. This is the same with every fitter seed and with the code before this release's RTL changes. It is specific to that pin of the Beta 2 board.

This test release contains only the RBF files for main variant hl2b5up_main and the other usual variants.

See the [gateware](https://github.com/softerhardware/Hermes-Lite2/wiki/Updating-Gateware) wiki page for more details on how to update the gateware. Most people will use the file root and suffix in bold below, hl2b5up_main.rbf, for programming over ethernet.

### Variants

* **hl2b5up_main - Main gateware for Hermes-Lite 2.0 build5 and later** Includes all programming file types. This is what most people will use. Use the hl2b5up_main.rbf file for network update with Quisk, SparkSDR or hermeslite.py.
* variants/hl2b5up_main_iambic - Main gateware with the iambic CW keyer in the FPGA for Hermes-Lite 2.0 build5 and later. Paddles on the PTT/KEY phone connector: tip = dot, ring = dash. Only 2 receivers.
* variants/hl2b3to4_main - Main gateware for Hermes-Lite 2.0 beta3 or beta4. Includes all programming file types.
* variants/hl2b2_main - Main gateware for Hermes-Lite 2.0 beta2. Includes all programming file types.
* variants/hl2b5up_cicrx - 10RX only gateware for Hermes-Lite 2.0 build5 and later. This only supports 192kHz receivers. This uses only CIC filters and consequently only about 70kHz of the spectrum is usable. This is for multiband skimming.
* variants/hl2b3to4_cicrx - 10RX only gateware for Hermes-Lite 2.0 beta3 or beta4. This only supports 192kHz receivers. This uses only CIC filters and consequently only about 70kHz of the spectrum is usable. This is for multiband skimming.
* variants/hl2b5up_ak4951v3 - AK4951V3 companion board gateware for Hermes-Lite 2. build5 and later. ATU is not supported.
* variants/hl2b5up_ak4951v4 - AK4951V4 companion board gateware for Hermes-Lite 2. build5 and later. ATU is supported. Do not use AK4951V4 gateware with AK4951V3 companion board.


### File Types

* **.rbf - Raw binary format for programming over ethernet using openhpsdr protocol 1**
* .jic - Nonvolatile EEPROM programming with Quartus
* .sof - Volatile FPGA-only programming with Quartus
* jic.jam - Nonvolatile EEPROM programming with JAM/STAPL player as used in the Raspberry Pi setup image
* sof.jam - Volatile FPGA-only programming with JAM/STAPL player as used in the Raspberry Pi setup image
* .svf - Volatile FPGA-only programming with urjtag or openocd

If your HL2 does not yet have gateware which supports network gateware updates and only a .rbf file is provided for your desired variant, first update to the main gateware and then update to your variant.
