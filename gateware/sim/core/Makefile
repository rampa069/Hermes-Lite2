# Full-core simulation of a Hermes-Lite 2 variant with Verilator.
#
#   make                      build and run the default test (boot)
#   make test T=<name>        run one test
#   make regress              run all tests
#   make build                only build
#   make wave T=<name>        run with a VCD dump (tb_hl2.vcd in run/)
#
# The RTL files and macros come from the variant's Quartus project. RTL files
# that Verilator rejects are copied to build/compat with behavior-preserving
# rewrites (scripts/rtl_compat.py lists them when building); the RTL itself is
# not modified.

VARIANT  ?= hl2b5up_main_iambic
VDIR      = ../../variants/$(VARIANT)
BUILD     = build/$(VARIANT)
RUN       = run/$(VARIANT)
T        ?= boot
ARGS     ?=

TESTS     = boot discovery arp_icmp rx rx_rates tx cw_iambic cw_straight cwx responses tx_inhibit tx_glitch i2c_cmd ad9866_spi_busy ad9866_spi_init lna_gain watchdog dhcp eeprom_override reboot factory_boot factory_hold wideband fan

TB_SRCS   = tb/hl2_pkg.sv tb/phy_model.sv tb/i2c_slave_model.sv tb/ad9866_model.sv tb/tb_hl2.sv
MODELS    = models/altera_sim_models.v

VFLAGS    = --binary --timing -j 0 -O3 --x-initial 0 --x-assign 0 --output-split 20000 --output-split-cfuncs 2000 \
            --timescale 1ps/1fs --top-module tb_hl2 -Itb \
            -Wno-fatal -Wno-lint -Wno-style -Wno-TIMESCALEMOD -Wno-COMBDLY -Wno-MULTIDRIVEN

.PHONY: all build test regress wave clean

all: test

$(BUILD)/variant.f: $(VDIR)/hermeslite.qsf scripts/qsf2f.py
	@mkdir -p $(BUILD)
	python3 scripts/qsf2f.py $(VDIR) > $@

# RTL sources of the variant (known once variant.f exists)
RTL_SRCS  = $(shell grep -v '^+' $(BUILD)/variant.f 2>/dev/null)

$(BUILD)/variant_compat.f: $(BUILD)/variant.f scripts/rtl_compat.py $(RTL_SRCS)
	rm -rf $(BUILD)/compat
	python3 scripts/rtl_compat.py $< $@ $(BUILD)/compat

$(BUILD)/Vtb: $(BUILD)/variant_compat.f $(MODELS) $(TB_SRCS) tb/tests.svh
	verilator $(VFLAGS) -Mdir $(BUILD)/obj -o ../Vtb $(MODELS) -f $(BUILD)/variant_compat.f $(TB_SRCS) \
	  > $(BUILD)/verilator.log 2>&1 || (grep -B2 -A6 "%Error" $(BUILD)/verilator.log | head -60; exit 1)

build: $(BUILD)/Vtb

$(RUN)/.roms: $(wildcard ../../rtl/*/*.mif ../../rtl/*/*/*.mif)
	@mkdir -p $(RUN)
	python3 scripts/mif2hex.py $(RUN) $(shell find ../../rtl -name "*.mif")
	cp ../../rtl/nco/*.txt $(RUN)/
	touch $@

test: $(BUILD)/Vtb $(RUN)/.roms
	cd $(RUN) && ../../$(BUILD)/Vtb +TEST=$(T) $(ARGS) | tee $(T).log

wave: ARGS += +vcd
wave: test

JOBS     ?= 8

regress: $(BUILD)/Vtb $(RUN)/.roms
	@cd $(RUN) && printf "%s\n" $(TESTS) | xargs -P $(JOBS) -I{} sh -c '../../$(BUILD)/Vtb +TEST={} $(ARGS) > {}.log 2>&1'
	@cd $(RUN) && pass=0; fail=0; \
	for t in $(TESTS); do \
	  if grep -q "==== $$t PASSED" $$t.log; then pass=$$((pass+1)); echo "PASS $$t"; \
	  else fail=$$((fail+1)); echo "FAIL $$t"; grep "FAIL:" $$t.log | sed 's/^ *[0-9]* *//' | head -20; fi; \
	done; echo "$$pass passed, $$fail failed"; test $$fail -eq 0

clean:
	rm -rf build run
