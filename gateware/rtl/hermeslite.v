
//  Hermes Lite
//
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

// (C) Steve Haynal KF7O 2014-2019
// This RTL originated from www.openhpsdr.org and has been modified to support
// the Hermes-Lite hardware described at http://github.com/softerhardware/Hermes-Lite2.
//
// Unified top-level wrapper for all HL2 variants.
// Board revision (one must be defined via QSF VERILOG_MACRO):
//   BETA2  - Board revision 2
//   BETA3  - Board revision 3-4
//   BETA5  - Board revision 5+
//
// Parameter macros (all defined in QSF):
//   HL2_NR, HL2_NT, HL2_UART, HL2_ATU, HL2_FAN, HL2_CW,
//   HL2_HL2LINK, HL2_AK4951, HL2_EXTENDED_DEBUG_RESP, HL2_BYPASS_VERSA
//
// Feature macros (defined in QSF when applicable):
//   AK4951=1          - AK4951 audio codec I2S wiring
//   HL2_DEBUG_4000=1  - Debug output on IO pins (4000 receiver)
//   HL2_ATU_AK4951=1  - Inverted ATU wiring (AK4951 V4 companion)

module hermeslite (
  // Power
  output       pwr_clk3p3,
  output       pwr_clk1p2,
  output       pwr_envpa,
`ifdef BETA2
  output       pwr_clkvpa,
`else
  output       pwr_envop,
  output       pwr_envbias,
`endif
  // Ethernet PHY
  input        phy_clk125,
  output [3:0] phy_tx,
  output       phy_tx_en,
  output       phy_tx_clk,
  input  [3:0] phy_rx,
  input        phy_rx_dv,
  input        phy_rx_clk,
  input        phy_rst_n,
  inout        phy_mdio,
  output       phy_mdc,
  // Clock
`ifdef BETA5
  output       io_db1_1,
`else
  output       io_cl1,
`endif
  inout        clk_sda1,
  inout        clk_scl1,
  // RF Frontend
  output       rffe_ad9866_rst_n,
  output [5:0] rffe_ad9866_tx,
  input  [5:0] rffe_ad9866_rx,
  input        rffe_ad9866_rxsync,
  input        rffe_ad9866_rxclk,
  output       rffe_ad9866_txquiet_n,
  output       rffe_ad9866_txsync,
  output       rffe_ad9866_sdio,
  output       rffe_ad9866_sclk,
  output       rffe_ad9866_sen_n,
  input        rffe_ad9866_clk76p8,
  output       rffe_rfsw_sel,
`ifdef BETA2
  output [5:0] rffe_ad9866_pga,
`else
  output       rffe_ad9866_mode,
  output       rffe_ad9866_pga5,
`endif
  // LEDs
  output       io_led_d2,
  output       io_led_d3,
  output       io_led_d4,
  output       io_led_d5,
  // Link
  input  [1:0] io_link_rx,
  output [1:0] io_link_tx,
  // Control inputs
  input        io_cn8,
  input        io_cn9,
  input        io_cn10,
  // I2C
  inout        io_adc_scl,
  inout        io_adc_sda,
  inout        io_scl2,
  inout        io_sda2,
  // Board-specific IO
`ifdef BETA2
  output       io_db24_1,
  input        io_db22_2,
  input        io_db22_3,
  output       io_cn4_6,
  output       io_cn4_7,
  input        io_phone_tip,
  input        io_phone_ring,
  input        io_tp2,
  output       pa_tr,
  output       pa_en
`elsif BETA3
  output       io_db24_1,
  input        io_db22_2,
  input        io_db22_3,
  output       io_cn4_6,
  output       io_cn4_7,
  input        io_phone_tip,
  input        io_phone_ring,
  input        io_tp2,
  input        io_tp7,
  input        io_tp8,
  input        io_tp9,
  output       pa_inttr,
  output       pa_exttr
`else
  `ifdef AK4951
  output       io_db1_2,
  `else
  input        io_db1_2,
  `endif
  output       io_db1_3,
  `ifdef AK4951
  input        io_db1_4,
  `else
  output       io_db1_4,
  `endif
  input        io_db1_5,
  output       io_db1_6,
  input        io_phone_tip,
  input        io_phone_ring,
  input        io_tp2,
  input        io_tp7,
  input        io_tp8,
  input        io_tp9,
  output       pa_inttr,
  output       pa_exttr
`endif
);

`ifdef BETA2
assign pwr_clkvpa = 1'b0;
assign rffe_ad9866_pga[4:0] = 5'h00;
`endif

`ifdef HL2_ATU_AK4951
wire io_atu_req;
assign io_db1_1 = ~io_atu_req;
`endif

`ifdef HL2_DEBUG_4000
wire [3:0] debug;
`endif

wire sidetone_wire;

`ifdef BETA2
  `define HL2_BOARD 2
  `define HL2_MAC5 8'h12
`elsif BETA3
  `define HL2_BOARD 3
  `define HL2_MAC5 8'h23
`else
  `define HL2_BOARD 5
  `define HL2_MAC5 8'h13
`endif

  hermeslite_core #(
    .BOARD        (`HL2_BOARD),
    .IP           ({8'd0,8'd0,8'd0,8'd0}),
    .MAC          ({8'h00,8'h1c,8'hc0,8'ha2,`HL2_MAC5,8'hdd}),
    .NR           (`HL2_NR),
    .NT           (`HL2_NT),
    .UART         (`HL2_UART),
    .ATU          (`HL2_ATU),
    .FAN          (`HL2_FAN),
    .PSSYNC       (1),
    .CW           (`HL2_CW),
    .ASMII        (1),
    .HL2LINK      (`HL2_HL2LINK),
    .AK4951       (`HL2_AK4951),
    .FAST_LNA     (1),
    .EXTENDED_RESP(1),
    .EXTENDED_DEBUG_RESP(`HL2_EXTENDED_DEBUG_RESP),
    .BYPASS_VERSA (`HL2_BYPASS_VERSA)
  ) hermeslite_core_i (
    .pwr_clk3p3                (pwr_clk3p3),
    .pwr_clk1p2                (pwr_clk1p2),
    .pwr_envpa                 (pwr_envpa),
`ifdef BETA2
    .pwr_envop                 (),
    .pwr_envbias               (pa_en),
`else
    .pwr_envop                 (pwr_envop),
    .pwr_envbias               (pwr_envbias),
`endif
    .phy_clk125                (phy_clk125),
    .phy_tx                    (phy_tx),
    .phy_tx_en                 (phy_tx_en),
    .phy_tx_clk                (phy_tx_clk),
    .phy_rx                    (phy_rx),
    .phy_rx_dv                 (phy_rx_dv),
    .phy_rx_clk                (phy_rx_clk),
    .phy_rst_n                 (phy_rst_n),
    .phy_mdio                  (phy_mdio),
    .phy_mdc                   (phy_mdc),
    .clk_sda1                  (clk_sda1),
    .clk_scl1                  (clk_scl1),
    .rffe_ad9866_rst_n         (rffe_ad9866_rst_n),
    .rffe_ad9866_tx            (rffe_ad9866_tx),
    .rffe_ad9866_rx            (rffe_ad9866_rx),
    .rffe_ad9866_rxsync        (rffe_ad9866_rxsync),
    .rffe_ad9866_rxclk         (rffe_ad9866_rxclk),
    .rffe_ad9866_txquiet_n     (rffe_ad9866_txquiet_n),
    .rffe_ad9866_txsync        (rffe_ad9866_txsync),
    .rffe_ad9866_sdio          (rffe_ad9866_sdio),
    .rffe_ad9866_sclk          (rffe_ad9866_sclk),
    .rffe_ad9866_sen_n         (rffe_ad9866_sen_n),
    .rffe_ad9866_clk76p8       (rffe_ad9866_clk76p8),
    .rffe_rfsw_sel             (rffe_rfsw_sel),
`ifdef BETA2
    .rffe_ad9866_mode          (),
    .rffe_ad9866_pga5          (rffe_ad9866_pga[5]),
`else
    .rffe_ad9866_mode          (rffe_ad9866_mode),
    .rffe_ad9866_pga5          (rffe_ad9866_pga5),
`endif
    .io_led_run                (io_led_d2),
    .io_led_tx                 (io_led_d3),
    .io_led_adc75              (io_led_d4),
    .io_led_adc100             (io_led_d5),
`ifdef HL2_ATU_AK4951
    .io_tx_envelope_pwm_out    (),
`elsif HL2_DEBUG_4000
    .io_tx_envelope_pwm_out    (),
`elsif HL2_SIDETONE_DB1
    .io_tx_envelope_pwm_out    (),
`elsif BETA5
    .io_tx_envelope_pwm_out    (io_db1_1),
`else
    .io_tx_envelope_pwm_out    (io_cl1),
`endif
    .io_tx_envelope_pwm_out_inv(),
    .io_tx_inhibit             (io_cn8),
    .io_id_hermeslite          (io_cn9),
    .io_alternate_mac          (io_cn10),
    .io_adc_scl                (io_adc_scl),
    .io_adc_sda                (io_adc_sda),
    .io_scl2                   (io_scl2),
    .io_sda2                   (io_sda2),
`ifdef BETA5
  `ifdef HL2_DEBUG_4000
    .io_uart_txd               (),
    .io_uart_rxd               (io_db1_2),
  `elsif AK4951
    `ifdef HL2_BANDV_YAESU
    .io_uart_txd               (),
    `else
    .io_uart_txd               (io_db1_3),
    `endif
    .io_uart_rxd               (1'b0),
  `else
    .io_uart_txd               (io_db1_3),
    .io_uart_rxd               (io_db1_2),
  `endif
`else
    .io_uart_txd               (io_db24_1),
    .io_uart_rxd               (io_tp2),
`endif
    .io_cw_keydown             (),
    .io_phone_tip              (io_phone_tip),
    .io_phone_ring             (io_phone_ring),
`ifdef HL2_ATU_AK4951
    .io_atu_ack                (~io_link_rx[1]),
    .io_atu_req                (io_atu_req),
`elsif AK4951
    .io_atu_ack                (1'b0),
    .io_atu_req                (),
`elsif HL2_DEBUG_4000
    .io_atu_ack                (io_db1_5),
    .io_atu_req                (),
`elsif BETA5
    .io_atu_ack                (io_db1_5),
    .io_atu_req                (io_db1_6),
`else
    .io_atu_ack                (1'b0),
    .io_atu_req                (),
`endif
`ifdef BETA2
    .pa_inttr                  (pa_tr),
    .pa_exttr                  (),
`else
    .pa_inttr                  (pa_inttr),
    .pa_exttr                  (pa_exttr),
`endif
`ifdef BETA5
  `ifdef AK4951
    `ifdef HL2_BANDV_YAESU
    .fan_pwm                   (io_db1_3),
    `else
    .fan_pwm                   (),
    `endif
  `elsif HL2_DEBUG_4000
    .fan_pwm                   (),
  `else
    .fan_pwm                   (io_db1_4),
  `endif
`else
    .fan_pwm                   (io_cn4_6),
`endif
`ifdef AK4951
    .linkrx                    (),
    .linktx                    (),
`else
    .linkrx                    (io_link_rx),
    .linktx                    (io_link_tx),
`endif
`ifdef AK4951
    .pa_exttr_clone            (io_db1_5),
    .io_ptt_in                 (io_db1_4),
    .i2s_pdn                   (io_db1_6),
    .i2s_bck                   (io_link_tx[0]),
    .i2s_lrck                  (io_link_tx[1]),
    .i2s_miso                  (io_link_rx[0]),
    .i2s_mosi                  (io_db1_2),
`else
    .pa_exttr_clone            (),
    .io_ptt_in                 (1'b0),
    .i2s_pdn                   (),
    .i2s_bck                   (),
    .i2s_lrck                  (),
    .i2s_miso                  (1'b0),
    .i2s_mosi                  (),
`endif
`ifdef HL2_DEBUG_4000
    .debug_out                 (debug),
`else
    .debug_out                 (),
`endif
    .io_sidetone_out           (sidetone_wire)
  );

`ifdef HL2_SIDETONE_DB1
assign io_db1_1 = sidetone_wire;
`endif

`ifdef HL2_DEBUG_4000
assign io_db1_1 = debug[0];
assign io_db1_3 = debug[1];
assign io_db1_4 = debug[2];
assign io_db1_6 = debug[3];
`endif

`undef HL2_BOARD
`undef HL2_MAC5

endmodule
