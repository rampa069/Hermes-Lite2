# Icarus Verilog testbench for the hl2b5up_main_iambic variant (CW keyer + sidetone)
#
#   make          build and run
#   make verbose  run printing every check
#   make wave     run with VCD dump (large) and open GTKWave
#   make clean

RTL = ../../rtl

TOP  = tb_hl2b5up_main_iambic
SRCS = altera_models.v \
       $(TOP).sv \
       $(RTL)/debounce.sv \
       $(RTL)/sync.v \
       $(RTL)/cw_openhpsdr.sv \
       $(RTL)/iambic.v \
       $(RTL)/localaudio/cw_sidetone.v \
       $(RTL)/sigma_delta_dac.sv

IVERILOG = iverilog
VVP      = vvp
IVFLAGS  = -g2012 -Wall -Wno-timescale -Wno-implicit-dimensions -s $(TOP)

.PHONY: all run verbose wave clean

all: run

sin1k9r.hex: $(RTL)/localaudio/sin1k9r.mif
	awk -F'[:;]' '/^[ \t]*[0-9]+[ \t]*:/ { v = $$2 + 0; if (v < 0) v += 512; printf "@%x %03x\n", $$1, v }' $< > $@

$(TOP).vvp: $(SRCS)
	$(IVERILOG) $(IVFLAGS) -o $@ $(SRCS)

run: $(TOP).vvp sin1k9r.hex
	$(VVP) -n $(TOP).vvp

verbose: $(TOP).vvp sin1k9r.hex
	$(VVP) -n $(TOP).vvp +verbose

wave: $(TOP).vvp sin1k9r.hex
	$(VVP) -n $(TOP).vvp +vcd
	gtkwave $(TOP).vcd &

clean:
	rm -f $(TOP).vvp $(TOP).vcd sin1k9r.hex
