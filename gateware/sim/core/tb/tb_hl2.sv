// Board level testbench for the Hermes-Lite 2 gateware (hermeslite top).
//
// The hermeslite top is built exactly as the variant's Quartus project (same
// sources and VERILOG_MACROs) with behavioral models of the Altera IP. Around
// it are models of the board: Ethernet PHY (RGMII + MDIO), AD9866, Versa clock,
// MCP4662 EEPROM, MAX11613 ADC, filter board I/O expander, CW paddles and the
// other I/O. A host model talks OpenHPSDR protocol 1 over UDP.
//
// The test to run is selected with +TEST=<name>; see tests.svh.

`timescale 1ps/1fs

`define CORE dut.hermeslite_core_i

module tb_hl2;

import hl2_pkg::*;

//------------------------------------------------------------------------------
// Board

logic phy_clk125 = 1'b0;
always #4000 phy_clk125 = ~phy_clk125;       // 8000 ps, as ethpll expects

logic phy_rst_n = 1'b0;

tri1 clk_sda1, clk_scl1, io_adc_scl, io_adc_sda, io_scl2, io_sda2, phy_mdio;

wire       phy_rx_clk, phy_rx_dv;
wire [3:0] phy_rx;
wire [3:0] phy_tx;
wire       phy_tx_en, phy_tx_clk, phy_mdc;

wire       ad_clk, ad_rxsync, ad_txsync, ad_txquiet_n, ad_pga5, ad_mode, ad_rst_n;
wire       ad_sclk, ad_sen_n, ad_sdio;
wire [5:0] ad_rx, ad_tx;

wire       rffe_rfsw_sel, pa_inttr, pa_exttr;
wire       led_run, led_tx, led_adc75, led_adc100;
wire       pwr_clk3p3, pwr_clk1p2, pwr_envpa, pwr_envop, pwr_envbias;
wire       io_db1_1, io_db1_3, io_db1_4, io_db1_6;
wire [1:0] io_link_tx;

logic      io_phone_tip  = 1'b1;   // dot paddle, active low
logic      io_phone_ring = 1'b1;   // dash paddle, active low
logic      io_cn8  = 1'b1;         // TX inhibit input, active low
logic      io_cn9  = 1'b1;         // id_hermeslite
logic      io_cn10 = 1'b1;         // alternate MAC select, active low
logic      io_db1_2 = 1'b1;        // UART RX
logic      io_db1_5 = 1'b0;        // ATU ACK
logic [1:0] io_link_rx = 2'b00;

hermeslite dut (
  .pwr_clk3p3(pwr_clk3p3), .pwr_clk1p2(pwr_clk1p2), .pwr_envpa(pwr_envpa),
  .pwr_envop(pwr_envop), .pwr_envbias(pwr_envbias),
  .phy_clk125(phy_clk125),
  .phy_tx(phy_tx), .phy_tx_en(phy_tx_en), .phy_tx_clk(phy_tx_clk),
  .phy_rx(phy_rx), .phy_rx_dv(phy_rx_dv), .phy_rx_clk(phy_rx_clk),
  .phy_rst_n(phy_rst_n),
  .phy_mdio(phy_mdio), .phy_mdc(phy_mdc),
  .io_db1_1(io_db1_1),
  .clk_sda1(clk_sda1), .clk_scl1(clk_scl1),
  .rffe_ad9866_rst_n(ad_rst_n), .rffe_ad9866_tx(ad_tx),
  .rffe_ad9866_rx(ad_rx), .rffe_ad9866_rxsync(ad_rxsync), .rffe_ad9866_rxclk(ad_clk),
  .rffe_ad9866_txquiet_n(ad_txquiet_n), .rffe_ad9866_txsync(ad_txsync),
  .rffe_ad9866_sdio(ad_sdio), .rffe_ad9866_sclk(ad_sclk), .rffe_ad9866_sen_n(ad_sen_n),
  .rffe_ad9866_clk76p8(ad_clk),
  .rffe_rfsw_sel(rffe_rfsw_sel), .rffe_ad9866_mode(ad_mode), .rffe_ad9866_pga5(ad_pga5),
  .io_led_d2(led_run), .io_led_d3(led_tx), .io_led_d4(led_adc75), .io_led_d5(led_adc100),
  .io_link_rx(io_link_rx), .io_link_tx(io_link_tx),
  .io_cn8(io_cn8), .io_cn9(io_cn9), .io_cn10(io_cn10),
  .io_adc_scl(io_adc_scl), .io_adc_sda(io_adc_sda),
  .io_scl2(io_scl2), .io_sda2(io_sda2),
  .io_db1_2(io_db1_2), .io_db1_3(io_db1_3), .io_db1_4(io_db1_4),
  .io_db1_5(io_db1_5), .io_db1_6(io_db1_6),
  .io_phone_tip(io_phone_tip), .io_phone_ring(io_phone_ring),
  .io_tp2(1'b0), .io_tp7(1'b0), .io_tp8(1'b0), .io_tp9(1'b0),
  .pa_inttr(pa_inttr), .pa_exttr(pa_exttr)
);

phy_model #(.PHYAD(7)) phy (
  .rx_clk(phy_rx_clk), .rxd(phy_rx), .rx_ctl(phy_rx_dv),
  .tx_clk(phy_tx_clk), .txd(phy_tx), .tx_ctl(phy_tx_en),
  .mdio(phy_mdio), .mdc(phy_mdc)
);

ad9866_model ad9866 (
  .clk(ad_clk), .rx(ad_rx), .rxsync(ad_rxsync),
  .tx(ad_tx), .txsync(ad_txsync), .txquiet_n(ad_txquiet_n), .pga5(ad_pga5),
  .mode(ad_mode), .rst_n(ad_rst_n),
  .sclk(ad_sclk), .sen_n(ad_sen_n), .sdio(ad_sdio)
);

i2c_slave_model #(.ADDR(7'h6a), .KIND("REG8"))     versa  (.scl(clk_scl1),   .sda(clk_sda1));
i2c_slave_model #(.ADDR(7'h2c), .KIND("MCP4662"))  eeprom (.scl(io_scl2),    .sda(io_sda2));
i2c_slave_model #(.ADDR(7'h20), .KIND("REG8"))     filter (.scl(io_scl2),    .sda(io_sda2));
i2c_slave_model #(.ADDR(7'h34), .KIND("MAX11613")) adc    (.scl(io_adc_scl), .sda(io_adc_sda));

//------------------------------------------------------------------------------
// Checking and reporting

int errors = 0;
int checks = 0;
bit verbose = 0;

task automatic check(input bit cond, input string msg);
  checks++;
  if (!cond) begin
    errors++;
    $display("%t   FAIL: %s", $realtime, msg);
  end else if (verbose) begin
    $display("%t   ok:   %s", $realtime, msg);
  end
endtask

task automatic check_near(input real act, input real exp, input real tol, input string what);
  checks++;
  if (act > exp + tol || act < exp - tol) begin
    errors++;
    $display("%t   FAIL: %s = %0.4g, expected %0.4g +/- %0.3g", $realtime, what, act, exp, tol);
  end else if (verbose) begin
    $display("%t   ok:   %s = %0.4g (expected %0.4g)", $realtime, what, act, exp);
  end
endtask

task automatic info(input string msg);
  $display("%t   %s", $realtime, msg);
endtask

function automatic real now_ms();
  return $realtime / 1.0e9;
endfunction

task automatic wait_ms(input real t);
  #(t * 1.0e9);
endtask

task automatic wait_us(input real t);
  #(t * 1.0e6);
endtask

//------------------------------------------------------------------------------
// Board configuration before power up (set by tests in their setup phase)

logic [7:0]  cfg_eeprom_config = 8'h80;   // static IP, no DHCP
logic [31:0] cfg_static_ip     = {8'd192, 8'd168, 8'd33, 8'd50};
logic [15:0] cfg_alt_mac       = 16'h0000;
bit          cfg_fast_boot     = 1'b1;

task automatic load_eeprom();
  eeprom.mem9[6]  = {1'b0, cfg_eeprom_config};
  eeprom.mem9[8]  = {1'b0, cfg_static_ip[31:24]};
  eeprom.mem9[9]  = {1'b0, cfg_static_ip[23:16]};
  eeprom.mem9[10] = {1'b0, cfg_static_ip[15:8]};
  eeprom.mem9[11] = {1'b0, cfg_static_ip[7:0]};
  eeprom.mem9[12] = {1'b0, cfg_alt_mac[15:8]};
  eeprom.mem9[13] = {1'b0, cfg_alt_mac[7:0]};
endtask

// Slow ADC channels: ain0 rev power, ain1 temperature, ain2 bias, ain3 fwd power
task automatic set_slow_adc(input logic [11:0] rev, input logic [11:0] temp,
                            input logic [11:0] bias, input logic [11:0] fwd);
  adc.adc[0] = rev;
  adc.adc[1] = temp;
  adc.adc[2] = bias;
  adc.adc[3] = fwd;
endtask

// Fast boot: shorten the 1 s "network settle" wait after the PHY link comes
// up. On the board the EEPROM (static IP config) has long been read by then, so
// the wait is only cut short once the I2C init sequence is back in IDLE.
initial begin
  forever begin
    wait (`CORE.network_inst.state == 4'd5);
    if (cfg_fast_boot) begin
      wait (`CORE.control_i.i2c_i.state == 8'h00 || `CORE.network_inst.state != 4'd5);
      if (`CORE.network_inst.state == 4'd5 && `CORE.network_inst.dhcp_timer > 22'd100)
        `CORE.network_inst.dhcp_timer = 22'd50;
    end
    wait (`CORE.network_inst.state != 4'd5);
  end
end

// Configuration image. The remote update block is a stub that reads as zero,
// which the remote_update state machine takes as "running the factory image"
// and reconfigures into the application image at power up. By default the
// testbench models the application image: when remote_update checks the
// configuration mode it is sent to DONE (as when data_out[0] reads 1).
bit cfg_factory_image = 1'b0;
initial begin
  forever begin
    wait (`CORE.INCLUDEASMII.remote_update_i.state == 4'b0011);   // READ_MODE3
    if (!cfg_factory_image) `CORE.INCLUDEASMII.remote_update_i.state = 4'b1110;   // DONE
    wait (`CORE.INCLUDEASMII.remote_update_i.state != 4'b0011);
  end
end

//------------------------------------------------------------------------------
// Host: frame dispatcher

logic [47:0] hl2_mac = 48'h0;
logic [31:0] hl2_ip  = 32'h0;
logic [15:0] hl2_port = 16'd1024;

bytes_t disc_replies[$];           // discovery payloads (60 bytes)
frame_info_t disc_info[$];
bytes_t arp_replies[$];
bytes_t icmp_replies[$];
bytes_t other_frames[$];
int unsigned bad_ip_csum = 0, bad_udp_csum = 0;

// EP6 state
typedef struct {
  logic [7:0]  c0;
  logic [31:0] data;
  real         t_ms;
} resp_t;
resp_t       ep6_resp[$];
int unsigned ep6_packets = 0;
int unsigned ep6_seq_errors = 0;
int unsigned ep6_sync_errors = 0;
logic [31:0] ep6_last_seq = 32'hffffffff;
int          host_nrx = 1;         // receivers the host asked for (cmd 0x00)
bit          iq_capture = 1'b0;
int          iq_capture_max = 8192;
// Captured I/Q: one entry per sample time with all receivers (a queue of
// structs; Verilator 5.048 mishandles push_back on arrays of queues)
typedef struct { real i [10]; real q [10]; logic [15:0] mic; } iq_t;
iq_t         iq_buf[$];
logic [47:0] ep6_dst_mac;
logic [31:0] ep6_dst_ip;
logic [15:0] ep6_dst_port;
real         ep6_last_t = 0.0;
real         ep6_times[$];         // arrival times (ms) of the last 64 EP6 packets

// EP4 (wide band)
int unsigned ep4_packets = 0;
logic signed [15:0] ep4_samples[$];

task automatic clear_iq();
  iq_buf.delete();
endtask

task automatic parse_ep6(input bytes_t f, input frame_info_t fi);
  int p = fi.payload_off;
  logic [31:0] seq;
  int spr;
  seq = get32(f, p + 4);
  if (ep6_last_seq != 32'hffffffff && seq != ep6_last_seq + 1) ep6_seq_errors++;
  ep6_last_seq = seq;
  ep6_packets++;
  ep6_dst_mac = fi.dst_mac;
  ep6_dst_ip = fi.dst_ip;
  ep6_dst_port = fi.dst_port;
  ep6_last_t = now_ms();
  ep6_times.push_back(ep6_last_t);
  if (ep6_times.size() > 64) void'(ep6_times.pop_front());
  spr = 504 / (6 * host_nrx + 2);
  for (int fr = 0; fr < 2; fr++) begin
    int o = p + 8 + 512 * fr;
    if (f[o] != 8'h7f || f[o+1] != 8'h7f || f[o+2] != 8'h7f) begin
      ep6_sync_errors++;
      continue;
    end
    ep6_resp.push_back('{f[o+3], get32(f, o + 4), now_ms()});
    if (ep6_resp.size() > 4096) void'(ep6_resp.pop_front());
    o += 8;
    for (int s = 0; s < spr; s++) begin
      iq_t x;
      for (int r = 0; r < host_nrx; r++) begin
        logic signed [23:0] vi, vq;
        vi = {f[o], f[o+1], f[o+2]};
        vq = {f[o+3], f[o+4], f[o+5]};
        o += 6;
        x.i[r] = real'(vi);
        x.q[r] = real'(vq);
      end
      x.mic = {f[o], f[o+1]};
      o += 2;
      if (iq_capture && iq_buf.size() < iq_capture_max) iq_buf.push_back(x);
    end
  end
endtask

task automatic parse_ep4(input bytes_t f, input frame_info_t fi);
  int p = fi.payload_off + 8;
  ep4_packets++;
  for (int i = 0; i < 1024; i += 2)
    if (ep4_samples.size() < 65536) ep4_samples.push_back({f[p+i+1], f[p+i]});
endtask

task automatic dispatch_frame(input bytes_t f);
  frame_info_t fi;
  fi = parse_frame(f);
  if (fi.ethertype == 16'h0806) begin
    arp_replies.push_back(f);
  end else if (fi.ethertype == 16'h0800) begin
    if (!fi.ip_csum_ok) bad_ip_csum++;
    if (fi.proto == 8'd1) begin
      icmp_replies.push_back(f);
    end else if (fi.proto == 8'd17) begin
      int p;
      p = fi.payload_off;
      if (!fi.udp_csum_ok) bad_udp_csum++;
      if (fi.payload_len >= 3 && f[p] == 8'hef && f[p+1] == 8'hfe &&
          (f[p+2] == 8'h02 || f[p+2] == 8'h03)) begin
        bytes_t d;
        for (int i = 0; i < fi.payload_len; i++) d.push_back(f[p+i]);
        disc_replies.push_back(d);
        disc_info.push_back(fi);
        if (debugnet) $display("%t DBG discovery reply #%0d byte2=%02h %0d->%0d", $realtime,
                               disc_replies.size(), d[2], fi.src_port, fi.dst_port);
      end else if (fi.payload_len == 1032 && f[p] == 8'hef && f[p+1] == 8'hfe &&
                   f[p+2] == 8'h01 && f[p+3] == 8'h06) begin
        parse_ep6(f, fi);
      end else if (fi.payload_len == 1032 && f[p] == 8'hef && f[p+1] == 8'hfe &&
                   f[p+2] == 8'h01 && f[p+3] == 8'h04) begin
        parse_ep4(f, fi);
      end else if (fi.dst_port == 16'd67) begin
        dhcp_server_rx(f, fi);
      end else begin
        other_frames.push_back(f);
      end
    end else begin
      other_frames.push_back(f);
    end
  end else begin
    other_frames.push_back(f);
  end
endtask

initial begin
  forever begin
    while (phy.rx_frames.size() == 0) #20000;
    dispatch_frame(phy.rx_frames.pop_front());
  end
end

//------------------------------------------------------------------------------
// Host: sending

task automatic send_udp(input bytes_t payload, input logic [15:0] dport = 16'd1024,
                        input bit bcast = 1'b0, input logic [15:0] sport = HOST_PORT);
  if (bcast) phy.send_frame(udp_frame(BCAST_MAC, 32'hffffffff, dport, payload, sport));
  else       phy.send_frame(udp_frame(hl2_mac, hl2_ip, dport, payload, sport));
endtask

// Wait until the PHY transmit queue is empty (frame fully sent)
task automatic wait_tx_done();
  while (!phy.tx_idle()) #8000;
endtask

task automatic discover(output bit ok, input real timeout_ms = 2.0, input bit bcast = 1'b1);
  real t0;
  int n0;
  n0 = disc_replies.size();
  send_udp(hpsdr_discovery(), 16'd1024, bcast);
  t0 = now_ms();
  while (disc_replies.size() == n0 && now_ms() - t0 < timeout_ms) #100000;
  ok = (disc_replies.size() > n0);
  if (ok) begin
    hl2_mac = disc_info[$].src_mac;
    hl2_ip  = disc_info[$].src_ip;
  end
endtask

//------------------------------------------------------------------------------
// Host: EP2 stream and command scheduler
//
// Like the PC programs, every EP2 packet carries two commands. Commands queued
// with send_cmd() go first; otherwise the registers set with set_reg() are
// sent round robin.

logic [31:0] reg_val [0:63];
bit          reg_set [0:63];
int          rr_idx = 0;
hpsdr_cmd_t  cmd_queue[$];
logic [31:0] ep2_seq = 0;
bit          ep2_run = 1'b0;         // EP2 stream on
bit          host_ptt = 1'b0;        // MOX bit in C0
real         ep2_period_ms = 126.0 / 48.0;   // 126 TX samples per packet at 48 kHz
int unsigned ep2_sent = 0;

// TX I/Q source: tone at tx_bb_freq with amplitude tx_bb_amp (fraction of FS)
real         tx_bb_freq = 1000.0;
real         tx_bb_amp  = 0.0;
real         tx_bb_phase = 0.0;
bit          tx_cwx = 1'b0;          // CWX: key via bit 0 of the I samples
bit          tx_cwx_key = 1'b0;

initial begin
  foreach (reg_val[i]) begin reg_val[i] = 32'h0; reg_set[i] = 1'b0; end
end

task automatic set_reg(input logic [5:0] addr, input logic [31:0] data);
  reg_val[addr] = data;
  reg_set[addr] = 1'b1;
endtask

task automatic send_cmd(input logic [5:0] addr, input logic [31:0] data, input bit resp = 1'b0);
  cmd_queue.push_back('{{resp, addr}, data});
endtask

function automatic hpsdr_cmd_t next_cmd();
  hpsdr_cmd_t c;
  if (cmd_queue.size() != 0) return cmd_queue.pop_front();
  for (int k = 0; k < 64; k++) begin
    int a;
    a = (rr_idx + k) % 64;
    if (reg_set[a]) begin
      rr_idx = (a + 1) % 64;
      c.addr = {1'b0, 6'(a)};
      c.data = reg_val[a];
      return c;
    end
  end
  c.addr = 7'h00;
  c.data = reg_val[0];
  return c;
endfunction

function automatic tx_sample_t next_tx_sample();
  tx_sample_t s;
  real v;
  s.l = 16'sd0;
  s.r = 16'sd0;
  s.i = 16'($rtoi(tx_bb_amp * 32767.0 * $cos(tx_bb_phase)));
  s.q = 16'($rtoi(tx_bb_amp * 32767.0 * $sin(tx_bb_phase)));
  tx_bb_phase += 2.0 * 3.14159265358979 * tx_bb_freq / 48000.0;
  if (tx_bb_phase > 2.0 * 3.14159265358979) tx_bb_phase -= 2.0 * 3.14159265358979;
  if (tx_cwx) begin
    s.i = {15'h0, tx_cwx_key};
    s.q = 16'sd0;
  end
  return s;
endfunction

task automatic send_ep2();
  tx_sample_t s[$];
  hpsdr_cmd_t c0, c1;
  for (int i = 0; i < 126; i++) s.push_back(next_tx_sample());
  c0 = next_cmd();
  c1 = next_cmd();
  send_udp(hpsdr_ep2(ep2_seq, c0, c1, host_ptt, s));
  ep2_seq++;
  ep2_sent++;
endtask

bit ep2_tick = 1'b0;          // toggles before each periodic EP2 packet is built

initial begin
  forever begin
    wait (ep2_run);
    ep2_tick = 1'b1;
    #1;
    ep2_tick = 1'b0;
    send_ep2();
    wait_ms(ep2_period_ms);
  end
end

// Push the queued commands out as fast as possible (two per EP2 packet)
task automatic flush_cmds();
  while (cmd_queue.size() != 0) begin
    send_ep2();
    wait_tx_done();
    wait_us(20);
  end
endtask

task automatic hpsdr_start(input bit wide = 1'b0);
  send_udp(hpsdr_startstop(1'b1, wide));
  wait_tx_done();
endtask

task automatic hpsdr_stop();
  send_udp(hpsdr_startstop(1'b0));
  wait_tx_done();
endtask

// Command 0x00: sample rate (0..3 = 48/96/192/384k) and number of receivers
task automatic set_config(input int rate, input int nrx, input logic [31:0] extra = 32'h0);
  logic [31:0] d;
  d = extra;
  d[25:24] = rate[1:0];
  d[6:3]   = 4'(nrx - 1);
  host_nrx = nrx;
  set_reg(6'h00, d);
  send_cmd(6'h00, d);
endtask

//------------------------------------------------------------------------------
// DHCP server (used by the DHCP test)

bit          dhcp_server_on = 1'b0;
logic [31:0] dhcp_offer_ip  = {8'd192, 8'd168, 8'd33, 8'd77};
logic [31:0] dhcp_lease     = 32'd3600;
int unsigned dhcp_discovers = 0, dhcp_requests = 0;
logic [31:0] dhcp_requested_ip = 32'h0;

function automatic int dhcp_find_option(input bytes_t f, input int opts, input int len,
                                        input logic [7:0] code);
  int i = opts;
  while (i < opts + len && f[i] != 8'hff) begin
    if (f[i] == 8'h00) begin i++; continue; end
    if (f[i] == code) return i;
    i += 2 + f[i+1];
  end
  return -1;
endfunction

task automatic dhcp_server_rx(input bytes_t f, input frame_info_t fi);
  int p, o, mt;
  logic [31:0] xid;
  logic [47:0] chaddr;
  bytes_t r;
  if (!dhcp_server_on) return;
  p = fi.payload_off;
  if (f[p] != 8'h01) return;                         // BOOTREQUEST
  xid = get32(f, p + 4);
  chaddr = get48(f, p + 28);
  if (get32(f, p + 236) != 32'h63825363) return;     // magic cookie
  o = dhcp_find_option(f, p + 240, fi.payload_len - 240, 8'd53);
  if (o < 0) return;
  mt = f[o + 2];
  if (mt == 1) dhcp_discovers++;
  else if (mt == 3) begin
    int ro;
    dhcp_requests++;
    ro = dhcp_find_option(f, p + 240, fi.payload_len - 240, 8'd50);
    dhcp_requested_ip = (ro >= 0) ? get32(f, ro + 2) : get32(f, p + 12);
  end else return;
  // Build OFFER (for DISCOVER) or ACK (for REQUEST)
  r.push_back(8'h02); r.push_back(8'h01); r.push_back(8'h06); r.push_back(8'h00);
  put32(r, xid);
  put16(r, 16'h0); put16(r, 16'h8000);
  put32(r, 32'h0);
  put32(r, dhcp_offer_ip);
  put32(r, HOST_IP);
  put32(r, 32'h0);
  put48(r, chaddr);
  for (int i = 0; i < 10 + 64 + 128; i++) r.push_back(8'h00);
  put32(r, 32'h63825363);
  r.push_back(8'd53); r.push_back(8'd1); r.push_back((mt == 1) ? 8'd2 : 8'd5);
  r.push_back(8'd54); r.push_back(8'd4); put32(r, HOST_IP);
  r.push_back(8'd51); r.push_back(8'd4); put32(r, dhcp_lease);
  r.push_back(8'd1);  r.push_back(8'd4); put32(r, 32'hffffff00);
  r.push_back(8'hff);
  while (r.size() < 300) r.push_back(8'h00);
  phy.send_frame(udp_frame(BCAST_MAC, 32'hffffffff, 16'd68, r, 16'd67));
endtask

//------------------------------------------------------------------------------
// Signal analysis helpers

// Complex tone frequency from the mean phase step: fs/(2 pi) * arg(sum z[n+1] z*[n])
function automatic real iq_freq(input int r, input real fs, input int skip = 0);
  real re = 0.0, im = 0.0;
  for (int n = skip; n + 1 < iq_buf.size(); n++) begin
    re += iq_buf[n+1].i[r] * iq_buf[n].i[r] + iq_buf[n+1].q[r] * iq_buf[n].q[r];
    im += iq_buf[n+1].q[r] * iq_buf[n].i[r] - iq_buf[n+1].i[r] * iq_buf[n].q[r];
  end
  return fs / (2.0 * 3.14159265358979) * $atan2(im, re);
endfunction

function automatic real iq_rms(input int r, input int skip = 0);
  real s = 0.0;
  int  n = 0;
  for (int k = skip; k < iq_buf.size(); k++) begin
    s += iq_buf[k].i[r] * iq_buf[k].i[r] + iq_buf[k].q[r] * iq_buf[k].q[r];
    n++;
  end
  return (n > 0) ? $sqrt(s / n) : 0.0;
endfunction

// Sample rate from the arrival times of the last n EP6 packets
function automatic real ep6_sample_rate(input int n);
  int k = ep6_times.size();
  if (k < n || n < 2) return 0.0;
  return (n - 1) * 2.0 * (504 / (6 * host_nrx + 2)) / ((ep6_times[k-1] - ep6_times[k-n]) / 1000.0);
endfunction

// 4-term Blackman-Harris window (-92 dB sidelobes), n = 0..len-1
function automatic real bh_window(input int n, input int len);
  real x = 2.0 * 3.14159265358979 * n / (len - 1);
  return 0.35875 - 0.48829 * $cos(x) + 0.14128 * $cos(2.0 * x) - 0.01168 * $cos(3.0 * x);
endfunction

// Windowed DFT at frequency f of receiver r: squared amplitude of a complex
// tone at f (window coherent gain removed)
function automatic real iq_dft_pow(input int r, input real fs, input real f, input int skip = 0);
  real re = 0.0, im = 0.0, w, win, wsum = 0.0;
  int  len = iq_buf.size() - skip;
  for (int k = 0; k < len; k++) begin
    w = -2.0 * 3.14159265358979 * f * k / fs;
    win = bh_window(k, len);
    re += win * (iq_buf[k+skip].i[r] * $cos(w) - iq_buf[k+skip].q[r] * $sin(w));
    im += win * (iq_buf[k+skip].i[r] * $sin(w) + iq_buf[k+skip].q[r] * $cos(w));
    wsum += win;
  end
  return (len > 0) ? (re * re + im * im) / (wsum * wsum) : 0.0;
endfunction

// Real signal: windowed power of a tone at frequency f relative to the total
// power (0..1)
function automatic real real_tone_fraction(input logic signed [11:0] x[$], input real fs,
                                           input real f, input int skip = 0);
  real re = 0.0, im = 0.0, tot = 0.0, w, win, wsum = 0.0;
  int  len = x.size() - skip;
  for (int k = 0; k < len; k++) begin
    w = 2.0 * 3.14159265358979 * f * k / fs;
    win = bh_window(k, len);
    re += win * x[k+skip] * $cos(w);
    im += win * x[k+skip] * $sin(w);
    wsum += win;
    tot += real'(x[k+skip]) * real'(x[k+skip]);
  end
  if (tot == 0.0) return 0.0;
  // amplitude A = 2|X|/wsum; tone power A^2/2 against the mean square
  return (2.0 * (re * re + im * im) / (wsum * wsum)) / (tot / len);
endfunction

function automatic real real_rms(input logic signed [11:0] x[$], input int skip = 0);
  real s = 0.0;
  int  n = 0;
  for (int k = skip; k < x.size(); k++) begin s += real'(x[k]) * real'(x[k]); n++; end
  return (n > 0) ? $sqrt(s / n) : 0.0;
endfunction

//------------------------------------------------------------------------------
// Power up and bring up

task automatic power_up();
  load_eeprom();
  phy_rst_n = 1'b0;
  wait_us(100);                   // phy_rst_n RC (~50 ms on the board), shortened
  phy_rst_n = 1'b1;
endtask

// Wait until the network stack has an IP address
task automatic wait_network(output bit ok, input real timeout_ms = 40.0);
  real t0 = now_ms();
  while (!((`CORE.network_state_dhcp == 1'b0) || (`CORE.network_state_fixedip == 1'b0)) &&
         now_ms() - t0 < timeout_ms)
    wait_us(20);
  ok = (`CORE.network_state_dhcp == 1'b0) || (`CORE.network_state_fixedip == 1'b0);
endtask

// Wait for the end of the reset sequence (ad9866_rst released at ~26 ms) and
// of the AD9866 SPI init sequence that follows it
task automatic wait_radio_ready(input real timeout_ms = 40.0);
  real t0 = now_ms();
  while (`CORE.ad9866_rst && now_ms() - t0 < timeout_ms) wait_us(50);
  while (`CORE.control_i.ad9866ctrl_i.dut1_pc[5:1] <= 5'h13 && now_ms() - t0 < timeout_ms) wait_us(10);
  wait_us(20);
endtask

// Standard bring up: power, network, discovery
task automatic bring_up(output bit ok);
  bit net_ok, disc_ok;
  power_up();
  wait_network(net_ok);
  check(net_ok, "network stack has an IP address");
  wait_radio_ready();
  discover(disc_ok);
  check(disc_ok, "discovery reply received");
  ok = net_ok && disc_ok;
endtask

//------------------------------------------------------------------------------
// Debug monitors (+debugnet)

bit debugnet = 0;
initial debugnet = $test$plusargs("debugnet");

always @(posedge `CORE.network_inst.rgmii_rx_active)
  if (debugnet) $display("%t DBG rgmii_rx_active rise", $realtime);
always @(posedge `CORE.network_inst.mac_rx_active)
  if (debugnet) $display("%t DBG mac_rx_active rise broadcast=%b is_arp=%b", $realtime,
                         `CORE.network_inst.broadcast, `CORE.network_inst.rx_is_arp);
always @(posedge `CORE.network_inst.ip_rx_active)
  if (debugnet) $display("%t DBG ip_rx_active rise to_ip=%h", $realtime, `CORE.network_inst.to_ip);
always @(posedge `CORE.network_inst.udp_rx_active)
  if (debugnet) $display("%t DBG udp_rx_active rise to_port=%0d", $realtime, `CORE.network_inst.to_port);
always @(`CORE.discover_cnt)
  if (debugnet) $display("%t DBG discover_cnt toggled", $realtime);
always @(posedge `CORE.network_inst.rgmii_tx_active)
  if (debugnet) $display("%t DBG rgmii_tx_active rise proto=%0d", $realtime, `CORE.network_inst.tx_protocol);
always @(`CORE.usopenhpsdr1_i.state)
  if (debugnet) $display("%t DBG usopenhpsdr1 state %0d", $realtime, `CORE.usopenhpsdr1_i.state);
always @(posedge `CORE.clock_ethtxint)
  if (debugnet && `CORE.usopenhpsdr1_i.state == 4'h6 && `CORE.usopenhpsdr1_i.dbyte_no >= 6'h37)
    $display("%t DBG disc dbyte_no=%h data=%h run=%b next=%h", $realtime, `CORE.usopenhpsdr1_i.dbyte_no,
             `CORE.usopenhpsdr1_i.discover_data, `CORE.usopenhpsdr1_i.run, `CORE.usopenhpsdr1_i.discover_data_next);
always @(phy_tx_en)
  if (debugnet) $display("%t DBG phy_tx_en=%b phy_tx_clk=%b", $realtime, phy_tx_en, phy_tx_clk);

// AD9866 SPI / command monitor (+debugspi)
bit debugspi = 0;
initial debugspi = $test$plusargs("debugspi");
always @(posedge `CORE.control_i.clk)
  if (debugspi && `CORE.control_i.cmd_rqst && `CORE.control_i.cmd_addr == 6'h09)
    $display("%t DBG control cmd 0x09 data=%h sen_n=%b", $realtime, `CORE.control_i.cmd_data, ad_sen_n);
always @(negedge ad_sen_n)
  if (debugspi) $display("%t DBG SPI start", $realtime);

// TX FIR input monitor (+debugtx): 48 kHz samples entering the interpolator
bit debugtx = 0;
initial debugtx = $test$plusargs("debugtx");
int dbg_tx_n = 0;
always @(posedge `CORE.clk_ad9866)
  if (debugtx && `CORE.radio_i.genblk16.tx_state == 3'b011 && `CORE.radio_i.genblk16.fir_tready && dbg_tx_n < 200) begin
    dbg_tx_n++;
    $display("%t DBG txfir #%0d tvalid=%b tdata=%h tuser=%b i=%0d q=%0d dsiq_status=%h", $realtime, dbg_tx_n,
             `CORE.dsiq_tvalid, `CORE.radio_i.tx_tdata, `CORE.radio_i.tx_tuser,
             $signed(`CORE.radio_i.tx_tdata[31:16]), $signed(`CORE.radio_i.tx_tdata[15:0]),
             `CORE.dsiq_status);
  end

// Bandscope / watchdog monitor (+debugbs), printed every ms
bit debugbs = 0;
initial debugbs = $test$plusargs("debugbs");
int unsigned dbg_wdt_toggles = 0;
always @(`CORE.watchdog_up) if (debugbs) dbg_wdt_toggles++;
initial begin
  wait (debugbs);
  forever begin
    wait_us(1000);
    $display("%t DBG bs: bs_tvalid=%b bs_cnt=%0d set_bs_cnt=%0d wide=%b wdt_toggles=%0d wdt_cnt=%0d run=%b push=%b wrfull=%b rdfull=%b",
             $realtime, `CORE.bs_tvalid, `CORE.usopenhpsdr1_i.bs_cnt, `CORE.usopenhpsdr1_i.set_bs_cnt,
             `CORE.wide_spectrum_sync, dbg_wdt_toggles, `CORE.dsopenhpsdr1_i.watchdog_cnt, `CORE.run,
             `CORE.usbs_fifo_i.bs_ad9866_push, `CORE.usbs_fifo_i.bs_ad9866_full, `CORE.usbs_fifo_i.bs_full);
  end
end

// RX path activity counters (+debugrx): printed every 0.5 ms
bit debugrx = 0;
initial debugrx = $test$plusargs("debugrx");
int unsigned dbg_rx_tvalid = 0, dbg_rx_tready = 0, dbg_adc_nz = 0;
always @(posedge `CORE.clk_ad9866) begin
  if (`CORE.rx_tvalid) dbg_rx_tvalid++;
  if (`CORE.rx_tvalid & `CORE.rx_tready) dbg_rx_tready++;
  if (`CORE.rx_data != 0) dbg_adc_nz++;
end
initial begin
  wait (debugrx);
  forever begin
    wait_us(500);
    $display("%t DBG rx: adc_nz=%0d rx_tvalid=%0d accepted=%0d run=%b usiq_tlength=%0d us_tvalid=%0d ep6=%0d rst_all=%b ad9866_rst=%b rx_rate=%0d last_chan=%0d",
             $realtime, dbg_adc_nz, dbg_rx_tvalid, dbg_rx_tready, `CORE.run, `CORE.usiq_tlength, `CORE.usiq_tvalid,
             ep6_packets, `CORE.rst_all, `CORE.ad9866_rst, `CORE.radio_i.rx_rate, `CORE.radio_i.last_chan);
    dbg_adc_nz = 0; dbg_rx_tvalid = 0; dbg_rx_tready = 0;
  end
end

//------------------------------------------------------------------------------
// Tests

string test_name = "";
bit    test_go = 1'b0;
bit    test_found = 1'b0;
bit    test_done = 1'b0;

`include "tests.svh"

initial begin
  string test;
  real   tmax;
  verbose = $test$plusargs("verbose");
  if (!$value$plusargs("TEST=%s", test)) test = "boot";
  if (!$value$plusargs("TMAX_MS=%f", tmax)) tmax = 2000.0;
  if ($test$plusargs("vcd")) begin
    $dumpfile("tb_hl2.vcd");
    $dumpvars(0, tb_hl2);
  end
  fork
    begin
      #(tmax * 1.0e9);
      $display("%t   FAIL: watchdog, test did not finish in %0.1f ms", $realtime, tmax);
      errors++;
      finish_test(test);
    end
  join_none
  $display("==== TEST %s", test);
  test_name = test;
  test_go = 1'b1;
  #1;
  if (!test_found) begin
    $display("unknown test %s", test);
    errors++;
  end else begin
    wait (test_done);
  end
  finish_test(test);
end

task automatic finish_test(input string test);
  if (debugnet) foreach (other_frames[k]) begin
    string h = "";
    foreach (other_frames[k][i]) h = {h, $sformatf("%02h ", other_frames[k][i])};
    $display("DBG other frame %0d (%0d bytes): %s", k, other_frames[k].size(), h);
  end
  info($sformatf("PHY: %0d frames sent to the FPGA, %0d received (%0d errors); %0d ARP, %0d ICMP, %0d discovery, %0d EP6, %0d EP4, %0d other",
       phy.frames_sent, phy.frames_received, phy.fcs_errors, arp_replies.size(), icmp_replies.size(),
       disc_replies.size(), ep6_packets, ep4_packets, other_frames.size()));
  check(phy.fcs_errors == 0, $sformatf("no FCS/framing errors in frames from the FPGA (%0d)", phy.fcs_errors));
  check(bad_ip_csum == 0, $sformatf("IP header checksums correct (%0d bad)", bad_ip_csum));
  $display("==== %s %s: %0d checks, %0d errors, %0.3f ms simulated",
           test, (errors == 0) ? "PASSED" : "FAILED", checks, errors, now_ms());
  $finish;
endtask

endmodule
