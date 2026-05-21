

set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/hermeslite_core.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/fifos.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ad9866.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ad9866pll.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ad9866ctrl.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ethpll.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/radio.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/varcic.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/cic.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/cic_comb.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/cic_integrator.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/cordic.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/cpl_cordic.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/receiver.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/firfilt.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/CicInterpM5.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/firram36I_1024.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/FirInterp8_1024.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/firram36.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/vna_scanner.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/firrom/firromH.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/firrom/firromI_1024.v

set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/FirInterp5_1025_EER.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/counter.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/firrom/firrom1_1025.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/firram36I_205.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/square.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/sqroot.sv

set_global_assignment -name VERILOG_FILE ../../rtl/primitives/intel/multipliers.v
set_global_assignment -name VERILOG_FILE ../../rtl/nco/coarserom.v
set_global_assignment -name VERILOG_FILE ../../rtl/nco/finerom.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/nco/sincos.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/nco/nco2.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/nco/mix2.sv

set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/receiver2/recv2_cic.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/receiver2/recv2_cordic.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/receiver2/receiver2.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/receiver2/recv2_firromH.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/receiver2/recv2_firram48.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/receiver2/recv2_firx2r2.v

set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/firfilt.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/CicInterpM5.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/firram36I_1024.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/FirInterp8_1024.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/firram36.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/vna_scanner.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/firrom/firromH.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/firrom/firromI_1024.v

set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_cic_comb.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_cic_integrator.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_cordic.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_fir.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_fir_coeffs.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_fir_coeffs_rom.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_fir_mac.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_fir_shiftreg.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_memcic.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_memcic_ram.sv
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_receiver.v
set_global_assignment -name VERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_varcic.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/radio_openhpsdr1/qs1r/qs1r_mult_24Sx24S.sv

set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/udp_send.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/udp_recv.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/rgmii_send.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/rgmii_recv.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ethernet/phy_cfg.sv
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/network.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ethernet/mdio.sv
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/mac_send.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/mac_recv.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/ip_send.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/ip_recv.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/icmp.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/dhcp.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/crc32.v
set_global_assignment -name VERILOG_FILE ../../rtl/ethernet/arp.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ethernet/ddio_out.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ethernet/ddio_in.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/ethernet/icmp_fifo.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/dsopenhpsdr1.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/usopenhpsdr1.sv

set_global_assignment -name VERILOG_FILE ../../rtl/cdc_sync.v
set_global_assignment -name VERILOG_FILE ../../rtl/sync.v

set_global_assignment -name VERILOG_FILE ../../rtl/lfsr.v
set_global_assignment -name VERILOG_FILE ../../rtl/tx_watchdog.v

set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/led_flash.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/control.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/cw_basic.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/cw_openhpsdr.sv
set_global_assignment -name VERILOG_FILE ../../rtl/iambic.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/debounce.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/i2c_master.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/i2c_bus2.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/i2c.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/slow_adc.sv
set_global_assignment -name VERILOG_FILE ../../rtl/extamp.v
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/exttuner.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/hl2link.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/hl2link_app.sv

set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/asmi_asmi_parallel_0.sv
set_global_assignment -name VERILOG_FILE ../../rtl/asmi_interface.v

set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/altera_remote_update_core.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/remote_update.sv

