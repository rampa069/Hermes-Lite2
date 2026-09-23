// Tests for tb_hl2 (included inside the tb_hl2 module).
// Each test is a task; run_test() dispatches on the +TEST name.

//------------------------------------------------------------------------------
// boot: power up sequence, PHY/Versa/EEPROM/AD9866 configuration, static IP
task automatic test_boot();
  real t_up, t_rst_n, t_ad_rst;
  bit  ok;
  logic [15:0] w;

  cfg_eeprom_config = 8'h80;
  cfg_static_ip     = {8'd192, 8'd168, 8'd33, 8'd50};
  cfg_alt_mac       = 16'h1234;
  power_up();
  t_up = now_ms();

  // AD9866 reset release (~13 ms) and end of the FPGA reset sequence (~26 ms)
  wait (ad_rst_n === 1'b1);
  t_rst_n = now_ms() - t_up;
  wait (`CORE.ad9866_rst === 1'b0);
  t_ad_rst = now_ms() - t_up;
  check_near(t_rst_n, 65536.0 / 2 / 2.5e3, 0.2, "AD9866 RESET_n released after (ms)");
  check_near(t_ad_rst, 65535.0 / 2.5e3, 0.2, "FPGA radio reset released after (ms)");

  wait_network(ok);
  check(ok, "network has an IP address");
  check(`CORE.network_inst.state == 4'd9, $sformatf("network state RUNNING (%0d)", `CORE.network_inst.state));
  check(`CORE.network_inst.local_ip == cfg_static_ip,
        $sformatf("static IP from EEPROM: %s", ip2str(`CORE.network_inst.local_ip)));
  check(`CORE.network_inst.speed_1gb == 1'b1, "PHY link at 1 Gb/s");
  check(`CORE.eeprom_config == cfg_eeprom_config,
        $sformatf("eeprom_config read back %02h", `CORE.eeprom_config));
  check(`CORE.alt_mac == cfg_alt_mac, $sformatf("alt_mac read back %04h", `CORE.alt_mac));

  // PHY configuration over MDIO (KSZ9031 path: 1000BASE-T advert, restart AN)
  check(phy.mdio_write_addr.size() == 2,
        $sformatf("two MDIO writes for a KSZ9031 (%0d)", phy.mdio_write_addr.size()));
  if (phy.mdio_write_addr.size() == 2) begin
    check(phy.mdio_write_addr[0] == 5'h09 && phy.mdio_writes[0] == 16'h0200,
          $sformatf("MDIO write 0: reg %02h = %04h", phy.mdio_write_addr[0], phy.mdio_writes[0]));
    check(phy.mdio_write_addr[1] == 5'h00 && phy.mdio_writes[1] == 16'h1300,
          $sformatf("MDIO write 1: reg %02h = %04h", phy.mdio_write_addr[1], phy.mdio_writes[1]));
  end

  // Versa clock init sequence
  begin
    logic [15:0] exp_versa [7] = '{16'h1704, 16'h1840, 16'h1ee8, 16'h1f80, 16'h2d01, 16'h2e10, 16'h603b};
    check(versa.writes.size() == 7, $sformatf("7 Versa register writes (%0d)", versa.writes.size()));
    for (int i = 0; i < 7 && i < versa.writes.size(); i++) begin
      w = (versa.writes[i].size() == 2) ? {versa.writes[i][0], versa.writes[i][1]} : 16'hxxxx;
      check(w == exp_versa[i], $sformatf("Versa write %0d: %04h (expected %04h)", i, w, exp_versa[i]));
    end
  end

  // EEPROM: 7 reads (config, static IP, alt MAC)
  check(eeprom.reads == 7, $sformatf("7 EEPROM reads (%0d)", eeprom.reads));

  // AD9866 SPI init: registers flagged in ad9866ctrl initarray
  begin
    logic [4:0] a [9] = '{5'h06, 5'h07, 5'h0b, 5'h0c, 5'h0d, 5'h0e, 5'h10, 5'h11, 5'h12};
    logic [7:0] v [9] = '{8'h54, 8'h30, 8'h04, 8'h43, 8'h03, 8'h81, 8'h80, 8'h00, 8'h00};
    wait_ms(0.5);
    check(ad9866.spi_log.size() >= 9, $sformatf("AD9866 SPI init writes (%0d)", ad9866.spi_log.size()));
    for (int i = 0; i < 9; i++)
      check(ad9866.spi_regs[a[i]] == v[i],
            $sformatf("AD9866 reg %02h = %02h (expected %02h)", a[i], ad9866.spi_regs[a[i]], v[i]));
  end
endtask

//------------------------------------------------------------------------------
// discovery: reply contents, broadcast/unicast, port 1025, running flag
task automatic test_discovery();
  bit ok;
  bytes_t d;
  frame_info_t fi;

  cfg_eeprom_config = 8'h80;
  cfg_alt_mac = 16'hbeef;
  set_slow_adc(12'h111, 12'h222, 12'h333, 12'h444);
  bring_up(ok);
  if (!ok) return;

  d = disc_replies[$];
  fi = disc_info[$];
  check(d.size() == 60, $sformatf("discovery reply is 60 bytes (%0d)", d.size()));
  check(fi.dst_mac == HOST_MAC && fi.dst_ip == HOST_IP && fi.dst_port == HOST_PORT,
        "reply goes to the requesting host MAC/IP/port");
  check(fi.src_port == 16'd1024, $sformatf("reply source port 1024 (%0d)", fi.src_port));
  check(fi.src_ip == cfg_static_ip, $sformatf("reply source IP %s", ip2str(fi.src_ip)));
  check(fi.src_mac == 48'h00_1c_c0_a2_13_dd, $sformatf("board MAC %012h", fi.src_mac));
  check(d[0] == 8'hef && d[1] == 8'hfe && d[2] == 8'h02, "EF FE 02 (not running)");
  check(get48(d, 3) == fi.src_mac, "MAC in payload matches source MAC");
  check(d[9] == 8'd74, $sformatf("gateware major version 74 (%0d)", d[9]));
  check(d[10] == 8'h06, $sformatf("board id 0x06 Hermes-Lite (%02h)", d[10]));
  check(d[11] == 8'h80, $sformatf("EEPROM config bits (%02h)", d[11]));
  check(get32(d, 13) == cfg_static_ip, "static IP in payload");
  check(get16(d, 17) == cfg_alt_mac, "alternate MAC in payload");
  check(d[19] == 8'd4, $sformatf("number of receivers 4 (%0d)", d[19]));
  check(d[20][5:0] == 6'd5, $sformatf("board revision 5 (%0d)", d[20][5:0]));
  check(d[21] == 8'd102, $sformatf("gateware minor version 102 (%0d)", d[21]));

  // Unicast discovery
  discover(ok, 2.0, 1'b0);
  check(ok, "unicast discovery answered");

  // Discovery on port 1025 is answered from port 1025
  begin
    int n0 = disc_replies.size();
    real t0 = now_ms();
    send_udp(hpsdr_discovery(), 16'd1025, 1'b1, 16'd50001);
    while (disc_replies.size() == n0 && now_ms() - t0 < 2.0) wait_us(20);
    check(disc_replies.size() > n0, "discovery on port 1025 answered");
    if (disc_replies.size() > n0) begin
      check(disc_info[$].src_port == 16'd1025 && disc_info[$].dst_port == 16'd50001,
            $sformatf("port 1025 reply %0d -> %0d", disc_info[$].src_port, disc_info[$].dst_port));
    end
  end

  // While running the reply says EF FE 03
  set_config(0, 1);
  flush_cmds();
  hpsdr_start();
  wait_ms(0.2);
  discover(ok, 2.0, 1'b1);
  check(ok && disc_replies[$][2] == 8'h03,
        $sformatf("EF FE 03 while running (got %02h, run=%b run_sync=%b, EP6 packets %0d)",
                  disc_replies[$][2], `CORE.run, `CORE.run_sync, ep6_packets));
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// arp_icmp: ARP replies and ping
task automatic test_arp_icmp();
  bit ok;
  bytes_t f;
  frame_info_t fi;
  real t0;

  bring_up(ok);
  if (!ok) return;

  // ARP request for our IP
  phy.send_frame(arp_request(hl2_ip));
  t0 = now_ms();
  while (arp_replies.size() == 0 && now_ms() - t0 < 1.0) wait_us(10);
  check(arp_replies.size() == 1, $sformatf("one ARP reply (%0d)", arp_replies.size()));
  if (arp_replies.size() != 0) begin
    f = arp_replies.pop_front();
    check(get48(f, 0) == HOST_MAC, "ARP reply to host MAC");
    check(get16(f, 20) == 16'h0002, "ARP opcode reply");
    check(get48(f, 22) == hl2_mac && get32(f, 28) == hl2_ip, "ARP sender is the HL2");
    check(get48(f, 32) == HOST_MAC && get32(f, 38) == HOST_IP, "ARP target is the host");
  end

  // ARP request for another IP: no reply
  phy.send_frame(arp_request(hl2_ip + 1));
  wait_ms(0.3);
  check(arp_replies.size() == 0, "no ARP reply for another IP");

  // Ping with 32 and 1000 bytes of payload
  for (int k = 0; k < 2; k++) begin
    int len;
    len = (k == 0) ? 32 : 1000;
    phy.send_frame(icmp_echo(hl2_mac, hl2_ip, 16'h4242, 16'(k + 1), len));
    t0 = now_ms();
    while (icmp_replies.size() == 0 && now_ms() - t0 < 1.0) wait_us(10);
    check(icmp_replies.size() == 1, $sformatf("ICMP echo reply (%0d bytes payload)", len));
    if (icmp_replies.size() != 0) begin
      f = icmp_replies.pop_front();
      fi = parse_frame(f);
      check(fi.dst_ip == HOST_IP && fi.src_ip == hl2_ip, "echo reply addresses");
      check(f[fi.l4_off] == 8'd0, "ICMP type echo reply");
      check(csum16(f, fi.l4_off, 8 + len) == 16'h0000, "ICMP checksum");
      check(get16(f, fi.l4_off + 4) == 16'h4242 && get16(f, fi.l4_off + 6) == 16'(k + 1), "id/seq echoed");
      begin
        bit same = 1;
        for (int i = 0; i < len; i++) if (f[fi.l4_off + 8 + i] != 8'(i)) same = 0;
        check(same, "payload echoed");
      end
    end
  end
endtask

//------------------------------------------------------------------------------
// RX helpers

// Start streaming with the given sample rate / receivers and wait for n samples
// per receiver (after skipping 'settle' samples for the filters to fill)
task automatic rx_capture(input int nsamples, input int settle = 512, input real timeout_ms = 60.0);
  real t0 = now_ms();
  iq_capture_max = settle + nsamples;
  clear_iq();
  iq_capture = 1'b1;
  while (iq_buf.size() < settle + nsamples && now_ms() - t0 < timeout_ms) wait_us(50);
  iq_capture = 1'b0;
  check(iq_buf.size() >= settle + nsamples,
        $sformatf("captured %0d I/Q samples (%0d wanted)", iq_buf.size(), settle + nsamples));
endtask

function automatic real db(input real x);
  return 10.0 * $ln(x) / $ln(10.0);
endfunction

// I/Q convention of the HL2 in protocol 1: a signal above the receiver
// frequency shows up at a negative frequency when the samples are taken as
// I + jQ (the spectrum is conjugated). rx_sign maps RF offsets to baseband.
// TX uses the same convention: I + jQ = exp(j w t) is sent at f_tx - w/2pi.
real rx_sign = -1.0;
real tx_sign = -1.0;

// Check that receiver r sees a tone at RF offset df (Hz) and report its level
task automatic check_rx_tone(input int r, input real fs, input real df, input int skip,
                             output real level_dbfs);
  real f, p_sig, p_img, rms, fs24, f_exp;
  fs24 = 8388608.0;
  f_exp = rx_sign * df;
  f = iq_freq(r, fs, skip);
  rms = iq_rms(r, skip);
  p_sig = iq_dft_pow(r, fs, f_exp, skip);
  p_img = iq_dft_pow(r, fs, -f_exp, skip);
  level_dbfs = db(p_sig / (fs24 * fs24));
  info($sformatf("RX%0d: tone %0.1f Hz (expected %0.1f), %0.1f dBFS, image %0.1f dB below, purity %0.4f",
                 r + 1, f, f_exp, level_dbfs, db(p_sig / (p_img + 1e-30)), p_sig / (rms * rms + 1e-30)));
  check_near(f, f_exp, 2.0, $sformatf("RX%0d tone frequency (Hz)", r + 1));
  check(p_sig / (rms * rms + 1e-30) > 0.99, $sformatf("RX%0d output is a single tone", r + 1));
  check(db(p_sig / (p_img + 1e-30)) > 60.0, $sformatf("RX%0d image rejection > 60 dB", r + 1));
endtask

//------------------------------------------------------------------------------
// rx: four receivers at 192 ksps, tones on the ADC
task automatic test_rx();
  bit ok;
  real fs = 192000.0;
  real lvl [4];
  int  pk0, n0;

  bring_up(ok);
  if (!ok) return;

  // ADC: tone A 10.003 MHz, tone B 7.098 MHz, tone C 14.205 MHz (each -12 dBFS)
  ad9866.set_tone(0, 10.003e6, 0.25);
  ad9866.set_tone(1, 7.098e6, 0.25);
  ad9866.set_tone(2, 14.205e6, 0.25);

  set_config(2, 4, 32'h0000_0004);          // 192k, 4 receivers, duplex
  set_reg(6'h01, 32'd10_000_000);           // TX
  set_reg(6'h02, 32'd10_000_000);           // RX1: tone A at +3 kHz
  set_reg(6'h03, 32'd10_010_000);           // RX2: tone A at -7 kHz
  set_reg(6'h04, 32'd7_100_000);            // RX3: tone B at -2 kHz
  set_reg(6'h05, 32'd14_200_000);           // RX4: tone C at +5 kHz
  for (int a = 1; a <= 5; a++) send_cmd(6'(a), reg_val[a]);
  flush_cmds();
  ep2_run = 1'b1;
  hpsdr_start();
  n0 = ep6_packets;
  wait_ms(1.0);
  rx_capture(2048, 1024);
  pk0 = ep6_packets - n0;

  check_rx_tone(0, fs,  3000.0, 1024, lvl[0]);
  check_rx_tone(1, fs, -7000.0, 1024, lvl[1]);
  check_rx_tone(2, fs, -2000.0, 1024, lvl[2]);
  check_rx_tone(3, fs,  5000.0, 1024, lvl[3]);
  check_near(lvl[1] - lvl[0], 0.0, 0.2, "RX2 vs RX1 level for the same tone (dB)");
  check_near(lvl[2] - lvl[0], 0.0, 0.2, "RX3 vs RX1 level for tones of equal amplitude (dB)");
  check_near(lvl[3] - lvl[0], 0.0, 0.2, "RX4 vs RX1 level for tones of equal amplitude (dB)");

  check(ep6_seq_errors == 0, $sformatf("EP6 sequence numbers contiguous (%0d gaps)", ep6_seq_errors));
  check(ep6_sync_errors == 0, "EP6 frames start with 7F 7F 7F");
  check(ep6_dst_mac == HOST_MAC && ep6_dst_ip == HOST_IP && ep6_dst_port == HOST_PORT,
        "EP6 sent to the host that started the radio");
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// rx_rates: 48/96/192/384 ksps, one receiver, sample rate from the tone frequency
task automatic test_rx_rates();
  bit ok;
  real lvl;

  bring_up(ok);
  if (!ok) return;
  ad9866.set_tone(0, 5.0045e6, 0.5);
  set_reg(6'h01, 32'd5_000_000);
  set_reg(6'h02, 32'd5_000_000);
  ep2_run = 1'b1;
  for (int rate = 0; rate < 4; rate++) begin
    real fs = 48000.0 * (1 << rate);
    set_config(rate, 1, 32'h0000_0004);
    send_cmd(6'h02, reg_val[2]);
    flush_cmds();
    if (rate == 0) hpsdr_start();
    wait_ms(0.5);
    rx_capture(1024, 512, 80.0);
    // Sample rate from the EP6 packet rate (126 samples per packet with one receiver)
    info($sformatf("%0.0f ksps: EP6 rate %0.0f sps", fs / 1000.0, ep6_sample_rate(8)));
    check_near(ep6_sample_rate(8), fs, 0.05 * fs, $sformatf("EP6 sample rate at rate %0d (sps)", rate));
    check_rx_tone(0, fs, 4500.0, 512, lvl);
  end
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// TX helpers

// Capture n DAC samples (76.8 Msps) from the AD9866 model
task automatic dac_capture(input int n);
  ad9866.tx_capture.delete();
  ad9866.capture_max = n;
  ad9866.capture_en = 1'b1;
  while (ad9866.tx_capture.size() < n) wait_us(10);
  ad9866.capture_en = 1'b0;
endtask

// Fraction of the DAC signal power at f (Hz)
function automatic real dac_frac(input real f);
  return real_tone_fraction(ad9866.tx_capture, 76.8e6, f);
endfunction

// Wait until the DAC output is non zero; returns the time waited (ms)
task automatic wait_rf(output real t, input real timeout_ms = 60.0);
  real t0 = now_ms();
  while (!(ad_txquiet_n === 1'b1 && ad9866.tx_word != 12'sd0) && now_ms() - t0 < timeout_ms) wait_us(20);
  t = now_ms() - t0;
endtask

// PTT on with the EP2 stream, returns the time until RF appears at the DAC
task automatic ptt_to_rf(output real t_rf);
  host_ptt = 1'b1;
  wait_rf(t_rf);
endtask

// PTT off, returns the time until the AD9866 TX is disabled
task automatic ptt_off(output real t_off, input real timeout_ms = 60.0);
  real t0;
  host_ptt = 1'b0;
  t0 = now_ms();
  while (ad_txquiet_n !== 1'b0 && now_ms() - t0 < timeout_ms) wait_us(20);
  t_off = now_ms() - t0;
endtask

//------------------------------------------------------------------------------
// tx: I/Q tone through the TX chain to the DAC, PTT timing, PA/TR outputs
task automatic test_tx();
  bit  ok;
  real f_tx = 7.1e6, f_bb = 6000.0;
  real t_rf, t_off, fu, fl, fc, lvl;
  int  lat_reported;

  bring_up(ok);
  if (!ok) return;
  lat_reported = disc_replies[$][38];

  set_config(0, 1, 32'h0000_0004);
  set_reg(6'h01, 32'd7_100_000);
  set_reg(6'h02, 32'd7_100_000);
  set_reg(6'h09, 32'h8008_0000);          // drive level 0x80, PA enable
  for (int a = 0; a <= 9; a++) if (reg_set[a]) send_cmd(6'(a), reg_val[a]);
  flush_cmds();
  tx_bb_freq = f_bb;
  tx_bb_amp = 0.5;
  ep2_run = 1'b1;
  hpsdr_start();
  wait_ms(1.0);
  check(ad_txquiet_n == 1'b0 && pa_inttr == 1'b0 && pa_exttr == 1'b0, "no TX before PTT");
  check(ad9866.spi_regs[5'h0a] == 8'h48,
        $sformatf("AD9866 TX gain reg 0x0a = %02h for drive level 0x80 (expected 48)", ad9866.spi_regs[5'h0a]));

  // Phase A: default TX buffer latency, compared with the value the discovery
  // reply announces
  ptt_to_rf(t_rf);
  info($sformatf("default latency: RF %0.2f ms after PTT; discovery reports tx_buffer_latency %0d ms", t_rf, lat_reported));
  check_near(t_rf, lat_reported, 3.0,
             "default PTT to RF delay matches the tx_buffer_latency in the discovery reply (ms)");
  ptt_off(t_off);
  info($sformatf("default hang: TX off %0.2f ms after PTT release; discovery reports PTT hang %0d ms",
                 t_off, disc_replies[0][40][4:0]));
  check_near(t_off, lat_reported + disc_replies[0][40][4:0], 3.0,
             "default PTT release to TX off matches latency + PTT hang in the discovery reply (ms)");
  wait_ms(2.0);

  // Phase B: latency 10 ms, PTT hang 4 ms (command 0x17 as sent by PC programs)
  set_reg(6'h17, 32'h0000_040a);
  send_cmd(6'h17, reg_val[6'h17]);
  wait_ms(6.0);
  ptt_to_rf(t_rf);
  info($sformatf("latency 10 ms: RF %0.2f ms after PTT", t_rf));
  check_near(t_rf, 10.0, 3.0, "PTT to RF with tx_buffer_latency 10 ms (ms)");
  wait_ms(1.0);
  check(ad_txquiet_n === 1'b1, "AD9866 TX enabled");
  check(pa_inttr && pa_exttr && pwr_envbias && pwr_envpa && pwr_envop,
        $sformatf("PA/TR outputs on in TX (inttr %b exttr %b bias %b envpa %b envop %b)",
                  pa_inttr, pa_exttr, pwr_envbias, pwr_envpa, pwr_envop));
  check(rffe_rfsw_sel == 1'b1, "RF switch selects the PA path (PA enabled)");
  check(led_tx == 1'b0, "TX LED on (active low)");

  // The TX interpolation FIR (1024 taps at 384 kHz) needs ~1.3 ms to fill
  wait_ms(2.0);
  dac_capture(60000);
  fu = dac_frac(f_tx + tx_sign * f_bb);
  fl = dac_frac(f_tx - tx_sign * f_bb);
  fc = dac_frac(f_tx);
  lvl = 20.0 * $ln(real_rms(ad9866.tx_capture) / (2047.0 / $sqrt(2.0))) / $ln(10.0);
  info($sformatf("DAC: %0.2f dBFS, wanted sideband %0.4f, opposite %0.2e, carrier %0.2e", lvl, fu, fl, fc));
  check(fu > 0.99, $sformatf("I/Q tone at %0.0f Hz is transmitted at f_tx %s %0.0f Hz",
                             f_bb, (tx_sign > 0) ? "+" : "-", f_bb));
  check(fl < 1.0e-6, $sformatf("opposite sideband suppressed > 60 dB (%0.1f dB)", db(fu / (fl + 1e-30))));
  check(fc < 1.0e-6, $sformatf("carrier suppressed > 60 dB (%0.1f dB)", db(fu / (fc + 1e-30))));
  check_near(lvl, 20.0 * $ln(tx_bb_amp) / $ln(10.0), 0.3, "DAC level follows the I/Q amplitude (dBFS)");

  // Release PTT: the buffered 10 ms are sent, then the 4 ms hang
  ptt_off(t_off);
  info($sformatf("TX off %0.2f ms after PTT release", t_off));
  check_near(t_off, 14.0, 3.0, "PTT release to TX off (latency 10 + hang 4) (ms)");
  wait_us(100);
  check(!pa_inttr && !pa_exttr && !pwr_envbias && !pwr_envpa, "PA/TR outputs off after TX");
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// CW helpers

typedef struct { real t; real d; } elem_t;

// Keyed intervals in the DAC envelope log. Elements shorter than min_ms are
// counted as glitches and do not set the peak used for the threshold.
int env_glitches = 0;
int env_glitch_peak = 0;
task automatic env_elements(output elem_t e[$], output int peak, input real thr_frac = 0.5,
                            input real min_ms = 0.1);
  int  thr, st, pk;
  bit  in = 0;
  real b = ad9866.ENV_BLOCK_MS;
  int  nmin = $rtoi(min_ms / b) + 1;
  // Peak over runs of at least nmin blocks above 10% of the overall max
  int  mx = 0;
  foreach (ad9866.env_log[k]) if (ad9866.env_log[k] > mx) mx = ad9866.env_log[k];
  peak = 0;
  env_glitches = 0;
  env_glitch_peak = 0;
  for (int k = 0; k < ad9866.env_log.size(); k++) begin
    if (ad9866.env_log[k] > mx / 10) begin
      int j = k;
      pk = 0;
      while (j < ad9866.env_log.size() && ad9866.env_log[j] > mx / 10) begin
        if (ad9866.env_log[j] > pk) pk = ad9866.env_log[j];
        j++;
      end
      if (j - k >= nmin) begin
        if (pk > peak) peak = pk;
      end else begin
        env_glitches++;
        if (pk > env_glitch_peak) env_glitch_peak = pk;
      end
      k = j;
    end
  end
  thr = $rtoi(thr_frac * peak);
  e.delete();
  foreach (ad9866.env_log[k]) begin
    if (!in && ad9866.env_log[k] > thr) begin st = k; in = 1; end
    else if (in && ad9866.env_log[k] <= thr) begin
      if (k - st >= nmin) e.push_back('{ad9866.env_t0 + st * b, (k - st) * b});
      in = 0;
    end
  end
endtask

// Envelope log index where the rising edge of element e0 starts (last block
// at or below 0.5% of peak before the element)
function automatic int env_edge_start(input elem_t e0, input int peak);
  int k = $rtoi((e0.t - ad9866.env_t0) / ad9866.ENV_BLOCK_MS);
  while (k > 0 && ad9866.env_log[k] > peak / 200) k--;
  return k;
endfunction

// Envelope shape of the rising edge of e0: amplitude reached at 90% of the
// rise time (0.5% to 99.5% of peak). Raised cosine: 0.976, linear ramp: 0.90
function automatic real env_a90(input elem_t e0, input int peak);
  int k0, k1 = -1, k90;
  k0 = env_edge_start(e0, peak);
  for (int k = k0; k < ad9866.env_log.size(); k++)
    if (ad9866.env_log[k] >= (995 * peak) / 1000) begin k1 = k; break; end
  if (k1 < 0) return 0.0;
  k90 = k0 + $rtoi(0.9 * (k1 - k0));
  return real'(ad9866.env_log[k90]) / peak;
endfunction

// 10% to 90% rise time (ms) of the rising edge of e0
function automatic real env_rise_ms(input elem_t e0, input int peak);
  int k10 = -1, k90 = -1;
  for (int k = env_edge_start(e0, peak); k < ad9866.env_log.size(); k++) begin
    if (k10 < 0 && ad9866.env_log[k] > peak / 10) k10 = k;
    if (k90 < 0 && ad9866.env_log[k] > (9 * peak) / 10) begin k90 = k; break; end
  end
  return (k90 - k10) * ad9866.ENV_BLOCK_MS;
endfunction

// Print the envelope log (max per 'step_ms') for debugging (+debugenv)
task automatic dump_env(input real t_ref, input real step_ms = 0.25);
  int n = $rtoi(step_ms / ad9866.ENV_BLOCK_MS);
  string sline;
  if (!$test$plusargs("debugenv")) return;
  for (int k = 0; k < ad9866.env_log.size(); k += n) begin
    int m = 0;
    for (int j = k; j < k + n && j < ad9866.env_log.size(); j++) if (ad9866.env_log[j] > m) m = ad9866.env_log[j];
    $display("ENV %7.2f ms: %0d", ad9866.env_t0 + k * ad9866.ENV_BLOCK_MS - t_ref, m);
  end
endtask

// Keyer and CW settings (commands 0x0b, 0x0f, 0x10 like the PC programs)
task automatic cw_setup(input int mode, input int wpm, input int weight = 50,
                        input bit spacing = 0, input bit swap = 0,
                        input int ptt_delay_ms = 5, input int hang_ms = 30,
                        input int st_vol = 64, input int st_freq = 600, input bit cwx = 0);
  logic [31:0] d;
  d = 32'h0;
  d[22] = swap; d[15:14] = 2'(mode); d[13:8] = 6'(wpm); d[7] = spacing; d[6:0] = 7'(weight);
  set_reg(6'h0b, d);
  d = 32'h0;
  d[24] = cwx; d[23:16] = 8'(st_vol); d[15:8] = 8'(ptt_delay_ms);
  set_reg(6'h0f, d);
  d = 32'h0;
  {d[31:24], d[17:16]} = 10'(hang_ms);
  {d[15:8], d[3:0]} = 12'(st_freq);
  set_reg(6'h10, d);
  send_cmd(6'h0b, reg_val[6'h0b]);
  send_cmd(6'h0f, reg_val[6'h0f]);
  send_cmd(6'h10, reg_val[6'h10]);
endtask

// Common bring up for the TX/CW tests: TX at f_tx, drive 0x80, PA enabled,
// latency 10 ms / PTT hang 4 ms, EP2 stream and run on
task automatic tx_bring_up(output bit ok, input int f_tx = 7_030_000);
  bring_up(ok);
  if (!ok) return;
  set_config(0, 1, 32'h0000_0004);
  set_reg(6'h01, 32'(f_tx));
  set_reg(6'h02, 32'(f_tx));
  set_reg(6'h09, 32'h8008_0000);
  set_reg(6'h17, 32'h0000_040a);
  for (int a = 0; a < 64; a++) if (reg_set[a]) send_cmd(6'(a), reg_val[a]);
  flush_cmds();
  ep2_run = 1'b1;
  hpsdr_start();
  wait_ms(1.0);
endtask

// Sidetone DB1-1 activity while keyed: fraction of time high and number of edges
int unsigned st_edges = 0;
longint unsigned st_high = 0, st_total = 0;
bit st_measure = 0;
always @(io_db1_1) if (st_measure) st_edges++;
always @(posedge `CORE.clk_ad9866) if (st_measure) begin st_total++; if (io_db1_1) st_high++; end

//------------------------------------------------------------------------------
// cw_iambic: paddles -> iambic keyer -> CW envelope -> DAC, sidetone, status
task automatic test_cw_iambic();
  bit  ok;
  elem_t e[$];
  int  peak;
  real dot_ms = (57600 / 60 + 1) / 48.0;
  real dash_ms = ((57600 / 60) * 3 + 1) / 48.0;
  real t_key, fc;
  int  n_dot_resp, n_ptt_resp, r0;

  tx_bring_up(ok);
  if (!ok) return;
  cw_setup(1, 60);                  // Mode A, 60 WPM, PTT delay 5 ms, hang 30 ms
  flush_cmds();
  wait_ms(1.0);

  // One dot
  ad9866.env_start();
  r0 = ep6_resp.size();
  io_phone_tip = 1'b0;
  t_key = now_ms();
  wait_ms(5.0);
  io_phone_tip = 1'b1;
  // Sidetone and RF while the dot is sent
  wait (`CORE.cw_on === 1'b1);
  wait_ms(8.0);
  st_measure = 1;
  wait_ms(4.0);
  st_measure = 0;
  dac_capture(20000);
  fc = dac_frac(7.03e6);
  check(pa_inttr && pa_exttr && pwr_envbias, "PA/TR outputs on while sending CW");
  wait_ms(60.0);
  ad9866.env_en = 1'b0;

  env_elements(e, peak);
  dump_env(t_key);
  check(e.size() == 1, $sformatf("one RF element for one dot (%0d)", e.size()));
  if (e.size() >= 1) begin
    info($sformatf("dot: %0d RF elements, peak %0d (%0.1f dBFS), rise %0.2f ms, a90 %0.3f, carrier purity %0.4f",
                   e.size(), peak, 20.0 * $ln(peak / 2047.0) / $ln(10.0), env_rise_ms(e[0], peak),
                   env_a90(e[0], peak), fc));
    info($sformatf("dot: RF from %0.2f ms after the paddle, %0.2f ms long", e[0].t - t_key, e[0].d));
    check_near(e[0].d, dot_ms, 0.5, "dot length at 60 WPM on the air, 50% points (ms)");
    check_near(e[0].t - t_key, 5.0 + 1.5 + 2.0, 2.0, "paddle to RF 50% (PTT delay 5 ms + debounce + ramp) (ms)");
    check_near(env_rise_ms(e[0], peak), 3.0, 2.0, "CW envelope 10-90% rise time (ms)");
    check(env_a90(e[0], peak) > 0.95,
          $sformatf("CW envelope is a complete raised cosine (amplitude at 90%% of the rise %0.3f, expected ~0.976)",
                    env_a90(e[0], peak)));
  end
  check(fc > 0.99, "CW carrier on the TX frequency");
  check(peak > 1824, $sformatf("CW peak at full DAC scale like the linear ramp (%0d = %0.1f dBFS, expected > -1 dBFS)",
                               peak, 20.0 * $ln(peak / 2047.0) / $ln(10.0)));
  check(env_glitches == 0, $sformatf("no RF spikes outside the keyed element (%0d, peak %0d = %0.1f dBFS)",
                                      env_glitches, env_glitch_peak, 20.0 * $ln((env_glitch_peak + 1e-9) / 2047.0) / $ln(10.0)));

  // EP6 status while keyed: C0 bit 2 = key (dot), bit 0 = PTT
  n_dot_resp = 0;
  n_ptt_resp = 0;
  for (int i = r0; i < ep6_resp.size(); i++) begin
    if (ep6_resp[i].c0[2]) n_dot_resp++;
    if (ep6_resp[i].c0[0]) n_ptt_resp++;
  end
  check(n_dot_resp > 0, $sformatf("EP6 C0 key bit seen while keyed (%0d frames)", n_dot_resp));
  check(n_ptt_resp > 0, $sformatf("EP6 C0 PTT bit seen during CW (%0d frames)", n_ptt_resp));

  // Sidetone on DB1-1 (1 bit sigma-delta, 600 Hz, volume 64)
  info($sformatf("sidetone DB1-1: %0d edges in 4 ms, high %0.3f of the time", st_edges,
                 real'(st_high) / (st_total + 1)));
  check(st_edges > 100, $sformatf("sidetone DB1-1 toggles while keyed (%0d edges)", st_edges));
  check_near(real'(st_high) / (st_total + 1), 0.5, 0.1, "sidetone DB1-1 average density (offset binary)");
  check(pa_inttr == 1'b0 && pa_exttr == 1'b0, "PA/TR off after the CW hang time");

  // One dash
  ad9866.env_start();
  io_phone_ring = 1'b0;
  t_key = now_ms();
  wait_ms(5.0);
  io_phone_ring = 1'b1;
  wait_ms(110.0);
  ad9866.env_en = 1'b0;
  env_elements(e, peak);
  check(e.size() == 1, $sformatf("one RF element for one dash (%0d)", e.size()));
  if (e.size() >= 1) check_near(e[0].d, dash_ms, 0.5, "dash length at 60 WPM on the air (ms)");

  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// cw_straight: keyer mode 00, ring is a straight key
task automatic test_cw_straight();
  bit  ok;
  elem_t e[$];
  int  peak;
  real t_key;

  tx_bring_up(ok);
  if (!ok) return;
  cw_setup(0, 60, 50, 0, 0, 0, 30);           // straight, no PTT delay
  flush_cmds();
  wait_ms(1.0);
  ad9866.env_start();
  io_phone_ring = 1'b0;
  t_key = now_ms();
  wait_ms(15.0);
  io_phone_ring = 1'b1;
  wait_ms(10.0);
  io_phone_ring = 1'b0;
  wait_ms(25.0);
  io_phone_ring = 1'b1;
  wait_ms(50.0);
  ad9866.env_en = 1'b0;
  env_elements(e, peak);
  info($sformatf("straight key: %0d elements", e.size()));
  foreach (e[k]) info($sformatf("  element %0d at %0.2f ms, %0.2f ms", k, e[k].t - t_key, e[k].d));
  check(e.size() == 2, $sformatf("two RF elements (%0d)", e.size()));
  if (e.size() == 2) begin
    check_near(e[0].d, 15.0, 1.5, "first element follows the key (15 ms)");
    check_near(e[1].d, 25.0, 1.5, "second element follows the key (25 ms)");
  end
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// cwx: CW keyed by the PC through bit 0 of the EP2 I samples. The key is
// sampled per EP2 packet (126 samples, 2.625 ms), so key times are multiples
// of the packet period. Two elements: the second one starts during the CW hang.
task automatic test_cwx();
  bit ok;
  elem_t e[$];
  int  peak;
  real pk = ep2_period_ms;

  tx_bring_up(ok);
  if (!ok) return;
  cw_setup(1, 60, 50, 0, 0, 5, 30, 64, 600, 1'b1);   // CWX enabled, hang 30 ms
  flush_cmds();
  tx_cwx = 1'b1;
  tx_cwx_key = 1'b0;
  wait_ms(6.0);
  ad9866.env_start();
  // 8 packets key down (21 ms), 8 packets up, 12 packets down (31.5 ms)
  @(posedge ep2_tick); tx_cwx_key = 1'b1;
  repeat (8)  @(posedge ep2_tick);
  tx_cwx_key = 1'b0;
  repeat (8)  @(posedge ep2_tick);
  tx_cwx_key = 1'b1;
  repeat (12) @(posedge ep2_tick);
  tx_cwx_key = 1'b0;
  wait_ms(80.0);
  ad9866.env_en = 1'b0;
  env_elements(e, peak);
  info($sformatf("CWX: %0d elements, peak %0d", e.size(), peak));
  foreach (e[k]) info($sformatf("  element %0d at %0.2f ms: %0.2f ms", k, e[k].t, e[k].d));
  check(e.size() == 2, $sformatf("two RF elements from CWX (%0d)", e.size()));
  if (e.size() == 2) begin
    check_near(e[0].d, 8 * pk, 1.0, "first CWX element length, 8 packets (ms)");
    check_near(e[1].t - (e[0].t + e[0].d), 8 * pk, 1.0, "gap between CWX elements, 8 packets (ms)");
    check_near(e[1].d, 12 * pk, 1.0, "second CWX element (starts in the CW hang), 12 packets (ms)");
  end
  tx_cwx = 1'b0;
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// Response helpers

// Last normal EP6 response with C0[4:3] == addr received after index r0
function automatic bit find_resp(input int r0, input int addr, output resp_t r);
  for (int i = ep6_resp.size() - 1; i >= r0 && i >= 0; i--)
    if (!ep6_resp[i].c0[7] && ep6_resp[i].c0[4:3] == 2'(addr)) begin r = ep6_resp[i]; return 1; end
  return 0;
endfunction

// Command response (C0[7] set) for command address a received after index r0
function automatic bit find_cmd_resp(input int r0, input logic [5:0] a, output resp_t r);
  for (int i = r0; i < ep6_resp.size(); i++)
    if (ep6_resp[i].c0[7] && ep6_resp[i].c0[6:1] == a) begin r = ep6_resp[i]; return 1; end
  return 0;
endfunction

// Start streaming at 48 ksps with one receiver (commands need the EP2 stream)
task automatic rx_bring_up(output bit ok);
  bring_up(ok);
  if (!ok) return;
  set_config(0, 1, 32'h0000_0004);
  set_reg(6'h01, 32'd7_100_000);
  set_reg(6'h02, 32'd7_100_000);
  for (int a = 0; a < 64; a++) if (reg_set[a]) send_cmd(6'(a), reg_val[a]);
  flush_cmds();
  ep2_run = 1'b1;
  hpsdr_start();
  wait_ms(1.0);
endtask

//------------------------------------------------------------------------------
// responses: EP6 C0-C4 status words, slow ADC values, ADC overload, TX inhibit
task automatic test_responses();
  bit ok;
  resp_t r;
  int r0;
  bytes_t d;

  set_slow_adc(12'h123, 12'h456, 12'h789, 12'habc);
  rx_bring_up(ok);
  if (!ok) return;

  // Discovery reply carries the slow ADC readings
  d = disc_replies[0];
  check({d[28][3:0], d[29]} == 12'h456, $sformatf("discovery temperature %03h", {d[28][3:0], d[29]}));
  check({d[30][3:0], d[31]} == 12'habc, $sformatf("discovery forward power %03h", {d[30][3:0], d[31]}));
  check({d[32][3:0], d[33]} == 12'h123, $sformatf("discovery reverse power %03h", {d[32][3:0], d[33]}));
  check({d[34][3:0], d[35]} == 12'h789, $sformatf("discovery bias %03h", {d[34][3:0], d[35]}));

  r0 = ep6_resp.size();
  wait_ms(12.0);
  check(find_resp(r0, 0, r), "EP6 response slot 0 seen");
  if (find_resp(r0, 0, r)) begin
    check(r.data[7:0] == 8'd74, $sformatf("slot 0 C4 = gateware version (%0d)", r.data[7:0]));
    check(r.data[24] == 1'b0, "slot 0 C1 bit 0: no ADC overload");
    check(r.data[25] == 1'b1, "slot 0 C1 bit 1: TX not inhibited");
  end
  check(find_resp(r0, 1, r), "EP6 response slot 1 seen");
  if (find_resp(r0, 1, r)) begin
    check(r.data[27:16] == 12'h456, $sformatf("slot 1 temperature %03h", r.data[27:16]));
    check(r.data[11:0] == 12'habc, $sformatf("slot 1 forward power %03h", r.data[11:0]));
  end
  check(find_resp(r0, 2, r), "EP6 response slot 2 seen");
  if (find_resp(r0, 2, r)) begin
    check(r.data[27:16] == 12'h123, $sformatf("slot 2 reverse power %03h", r.data[27:16]));
    check(r.data[11:0] == 12'h789, $sformatf("slot 2 bias %03h", r.data[11:0]));
  end

  // Slow ADC values follow changes while running
  set_slow_adc(12'h321, 12'h654, 12'h987, 12'hcba);
  wait_ms(12.0);
  r0 = ep6_resp.size();
  wait_ms(12.0);
  if (find_resp(r0, 1, r))
    check(r.data[27:16] == 12'h654 && r.data[11:0] == 12'hcba, "slot 1 follows new slow ADC values");

  // ADC overload: clipping input sets C1 bit 0
  ad9866.set_tone(0, 5.0e6, 1.3);
  wait_ms(3.0);
  r0 = ep6_resp.size();
  wait_ms(12.0);
  check(find_resp(r0, 0, r) && r.data[24] == 1'b1, "slot 0 C1 bit 0 set with a clipping ADC input");
  ad9866.set_tone(0, 5.0e6, 0.25);
  wait_ms(3.0);
  r0 = ep6_resp.size();
  wait_ms(12.0);
  check(find_resp(r0, 0, r) && r.data[24] == 1'b0, "slot 0 C1 bit 0 clear again without clipping");

  // TX inhibit input (CN8, active low) reported in C1 bit 1
  io_cn8 = 1'b0;
  wait_ms(5.0);
  r0 = ep6_resp.size();
  wait_ms(12.0);
  check(find_resp(r0, 0, r) && r.data[25] == 1'b0, "slot 0 C1 bit 1 clear with TX inhibit");
  io_cn8 = 1'b1;
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// tx_inhibit: CN8 blocks transmit
task automatic test_tx_inhibit();
  bit ok;
  real t_rf;
  tx_bring_up(ok);
  if (!ok) return;
  tx_bb_amp = 0.5;
  io_cn8 = 1'b0;
  wait_ms(5.0);
  host_ptt = 1'b1;
  wait_ms(16.0);
  check(!pa_inttr && !pa_exttr && !pwr_envbias && !pwr_envpa && !pwr_envop,
        "TX inhibit keeps the PA, T/R relay and bias off");
  info($sformatf("with TX inhibit: AD9866 TXQUIET_n=%b, DAC word %0d", ad_txquiet_n, ad9866.tx_word));
  check(ad_txquiet_n !== 1'b1,
        "TX inhibit also keeps the AD9866 transmitter off");
  host_ptt = 1'b0;
  wait_ms(20.0);
  io_cn8 = 1'b1;
  wait_ms(5.0);
  ptt_to_rf(t_rf);
  check(ad_txquiet_n === 1'b1 && pa_inttr, "TX works again after TX inhibit is released");
  host_ptt = 1'b0;
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// tx_glitch: nothing must reach the DAC before the first TX samples
task automatic test_tx_glitch();
  bit ok;
  int mx, first_nz;
  tx_bring_up(ok);
  if (!ok) return;
  info($sformatf("fast LNA gain before TX: %02h", ad9866.pga_gain));
  tx_bb_amp = 0.5;
  ad9866.capture_max = 4000;
  ad9866.arm_txstart = 1'b1;
  host_ptt = 1'b1;
  wait (ad9866.capture_en && ad9866.tx_capture.size() >= 4000);
  ad9866.capture_en = 1'b0;
  mx = 0;
  first_nz = -1;
  foreach (ad9866.tx_capture[k]) begin
    int a;
    a = (ad9866.tx_capture[k] < 0) ? -ad9866.tx_capture[k] : ad9866.tx_capture[k];
    if (a > mx) mx = a;
    if (a != 0 && first_nz < 0) first_nz = k;
  end
  if (first_nz >= 0)
    info($sformatf("first DAC words after TX enable: %0d %0d %0d %0d (first non zero at %0d)",
                   ad9866.tx_capture[0], ad9866.tx_capture[1], ad9866.tx_capture[2], ad9866.tx_capture[3], first_nz));
  check(mx == 0, $sformatf("DAC output is zero while TX starts, before the TX samples (max |word| %0d)", mx));
  host_ptt = 1'b0;
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// i2c_cmd: I2C through commands 0x3c/0x3d, command responses, filter board
task automatic test_i2c_cmd();
  bit ok;
  resp_t r;
  int r0, nw;

  rx_bring_up(ok);
  if (!ok) return;

  // Write the filter board I/O expander (bus 2, 0x20) register 9
  send_cmd(6'h3d, {8'h06, 8'h20, 8'h09, 8'h55});
  wait_ms(6.0);
  check(filter.mem[9] == 8'h55, $sformatf("I2C write through 0x3d: filter reg 9 = %02h", filter.mem[9]));

  // Read it back with a command response: 4 bytes from register 9
  filter.mem[10] = 8'h66;
  filter.mem[11] = 8'h77;
  filter.mem[12] = 8'h88;
  r0 = ep6_resp.size();
  send_cmd(6'h3d, {8'h07, 8'h20, 8'h09, 8'h00}, 1'b1);
  wait_ms(8.0);
  check(find_cmd_resp(r0, 6'h3d, r), "command response for the I2C read");
  if (find_cmd_resp(r0, 6'h3d, r))
    check(r.data == 32'h88776655, $sformatf("I2C read data %08h (expected 88776655)", r.data));

  // Versa clock (bus 1) through 0x3c
  send_cmd(6'h3c, {8'h06, 8'h6a, 8'h10, 8'hc4});
  wait_ms(6.0);
  check(versa.mem[8'h10] == 8'hc4, $sformatf("I2C write through 0x3c: Versa reg 0x10 = %02h", versa.mem[8'h10]));

  // EEPROM (MCP4662) write, as the HL2 configuration tools do
  send_cmd(6'h3d, {8'h06, 8'hac, 8'h60, 8'h40});
  wait_ms(6.0);
  check(eeprom.mem9[6] == 9'h040, $sformatf("EEPROM register 6 written = %03h", eeprom.mem9[6]));

  // Response to a non I2C command echoes the data
  r0 = ep6_resp.size();
  send_cmd(6'h01, 32'd7_123_456, 1'b1);
  wait_ms(8.0);
  check(find_cmd_resp(r0, 6'h01, r) && r.data == 32'd7_123_456, "command response echoes command 0x01");

  // Command 0x00 filter/antenna bits drive the filter board over I2C (reg 0x0a)
  nw = filter.writes.size();
  set_config(0, 1, 32'h0000_0004 | (32'h15 << 17) | (32'h1 << 13));
  wait_ms(8.0);
  check(filter.writes.size() > nw, "filter board written after a filter change in command 0x00");
  if (filter.writes.size() > nw)
    // MCP23008 OLAT (0x0a) = {antenna, filters}, then 0x00 (the address wraps to IODIR: all outputs)
    check(filter.writes[nw].size() == 3 && filter.writes[nw][0] == 8'h0a && filter.writes[nw][1] == 8'h95 &&
          filter.writes[nw][2] == 8'h00,
          $sformatf("filter board write %0d bytes %02h %02h (expected 0a 95 00)", filter.writes[nw].size(),
                    filter.writes[nw][0], filter.writes[nw][1]));
  // Unchanged filter bits: no more writes
  nw = filter.writes.size();
  wait_ms(10.0);
  check(filter.writes.size() == nw, "no filter board writes while the filter bits do not change");
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// ad9866_spi_busy: two AD9866 SPI commands in the same EP2 packet
task automatic test_ad9866_spi_busy();
  bit ok;
  resp_t r;
  int r0;
  rx_bring_up(ok);
  if (!ok) return;
  ep2_run = 1'b0;
  wait_ms(3.0);
  r0 = ep6_resp.size();
  // 0x09: drive level 0x40 -> AD9866 reg 0x0a = 0x44; 0x3b: AD9866 reg 0x13 = 0x5a
  cmd_queue.push_back('{{1'b0, 6'h09}, 32'h4000_0000});
  cmd_queue.push_back('{{1'b1, 6'h3b}, {8'h06, 8'h13, 8'h00, 8'h5a}});
  send_ep2();
  ep2_run = 1'b1;
  wait_ms(8.0);
  check(ad9866.spi_regs[5'h0a] == 8'h44, $sformatf("first command applied: reg 0x0a = %02h", ad9866.spi_regs[5'h0a]));
  check(ad9866.spi_regs[5'h13] == 8'h5a,
        $sformatf("second SPI command of the same packet applied: reg 0x13 = %02h", ad9866.spi_regs[5'h13]));
  check(find_cmd_resp(r0, 6'h3b, r) && !find_cmd_resp(r0, 6'h3f, r),
        "0x3b write acknowledged (no error response 0x3f)");
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// ad9866_spi_init: a TX gain command that arrives during the AD9866 SPI init
// sequence (right after the radio reset) must still be written
task automatic test_ad9866_spi_init();
  bit ok;
  power_up();
  wait_network(ok);
  check(ok, "network has an IP address");
  discover(ok);
  check(ok, "discovery reply received");
  set_config(0, 1, 32'h0000_0004);
  flush_cmds();
  wait (`CORE.ad9866_rst === 1'b0);
  wait_us(30);
  info($sformatf("sending 0x09 during the SPI init (init step %0d of 19)", `CORE.control_i.ad9866ctrl_i.dut1_pc[5:1]));
  send_cmd(6'h09, 32'h4000_0000);          // drive level 0x40 -> AD9866 reg 0x0a = 0x44
  send_ep2();
  wait_ms(1.0);
  check(ad9866.spi_regs[5'h0a] == 8'h44,
        $sformatf("TX gain written after the init sequence: reg 0x0a = %02h", ad9866.spi_regs[5'h0a]));
  check(ad9866.spi_regs[5'h0c] == 8'h43, "init sequence completed");
endtask

//------------------------------------------------------------------------------
// lna_gain: fast LNA gain updates through the TX pins (FAST_LNA)
task automatic test_lna_gain();
  bit ok;
  real t_rf;
  tx_bring_up(ok);
  if (!ok) return;
  send_cmd(6'h0a, 32'h0000_006a);            // direct gain 0x2a
  wait_ms(6.0);
  check(ad9866.pga_gain == 6'h2a, $sformatf("RX gain 0x2a applied through PGA5 (%02h)", ad9866.pga_gain));
  set_reg(6'h0a, 32'h0000_0014);             // legacy encoding -> {1, 0x14} = 0x34
  send_cmd(6'h0a, reg_val[6'h0a]);
  wait_ms(6.0);
  check(ad9866.pga_gain == 6'h34, $sformatf("RX gain legacy value 0x14 -> 0x34 (%02h)", ad9866.pga_gain));

  // SSB TX without a TX gain: the RX gain is kept
  tx_bb_amp = 0.25;
  ptt_to_rf(t_rf);
  wait_ms(1.0);
  check(ad9866.pga_gain == 6'h34, $sformatf("gain unchanged in TX without TX gain enable (%02h)", ad9866.pga_gain));
  host_ptt = 1'b0;
  wait_ms(20.0);

  // TX gain enabled (command 0x0e bit 15, direct value 0x05)
  set_reg(6'h0e, 32'h0000_c500);
  send_cmd(6'h0e, reg_val[6'h0e]);
  wait_ms(6.0);
  ptt_to_rf(t_rf);
  wait_ms(1.0);
  check(ad9866.pga_gain == 6'h05, $sformatf("TX gain 0x05 applied in TX (%02h)", ad9866.pga_gain));
  host_ptt = 1'b0;
  wait_ms(20.0);
  check(ad9866.pga_gain == 6'h34, $sformatf("RX gain restored after TX (%02h)", ad9866.pga_gain));
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// watchdog: the radio stops when the EP2 stream stops
//
// The watchdog counts "watchdog_up" ticks from usopenhpsdr1, one per bandscope
// slot, i.e. every set_bs_cnt EP6 packets (command 0x00), and stops the radio
// after 4096 ticks without EP2 packets.
int unsigned wdt_ticks = 0;
always @(`CORE.watchdog_up) wdt_ticks++;

task automatic test_watchdog();
  bit ok;
  real t0;
  int p0, w0, sbc;
  rx_bring_up(ok);
  if (!ok) return;
  check(`CORE.run == 1'b1, "running");

  // Start up: usopenhpsdr1 decrements bs_cnt for every EP6 packet, also when
  // it is already 0 (the bandscope FIFO is not full yet when the first EP6
  // packets go out); the 7 bit counter wraps and the first tick comes 128
  // packets later
  wait_ms(5.0);
  sbc = `CORE.usopenhpsdr1_i.set_bs_cnt;
  info($sformatf("watchdog: bs_cnt %0d after %0d EP6 packets (set_bs_cnt %0d), %0d ticks",
                 `CORE.usopenhpsdr1_i.bs_cnt, ep6_packets, sbc, wdt_ticks));
  check(`CORE.usopenhpsdr1_i.bs_cnt <= sbc,
        $sformatf("bandscope/watchdog counter does not wrap at start (bs_cnt %0d, set_bs_cnt %0d)",
                  `CORE.usopenhpsdr1_i.bs_cnt, sbc));

  // Steady state cadence (start up transient skipped)
  `CORE.usopenhpsdr1_i.bs_cnt = 7'(sbc);
  wait_ms(3.0);
  p0 = ep6_packets;
  w0 = wdt_ticks;
  wait_ms(40.0);
  info($sformatf("watchdog: %0d ticks for %0d EP6 packets in 40 ms", wdt_ticks - w0, ep6_packets - p0));
  check(wdt_ticks - w0 >= (ep6_packets - p0) / sbc - 2,
        $sformatf("one watchdog/bandscope tick every set_bs_cnt=%0d EP6 packets (%0d ticks for %0d packets)",
                  sbc, wdt_ticks - w0, ep6_packets - p0));

  // Counter near the limit is cleared by incoming EP2 packets
  `CORE.dsopenhpsdr1_i.watchdog_cnt = 12'hff0;
  wait_ms(15.0);
  check(`CORE.run == 1'b1, "still running while EP2 packets arrive");

  // No EP2 packets: the watchdog stops the radio (counter fast-forwarded)
  ep2_run = 1'b0;
  wait_ms(3.0);
  `CORE.dsopenhpsdr1_i.watchdog_cnt = 12'hffe;
  `CORE.usopenhpsdr1_i.bs_cnt = 7'd1;
  t0 = now_ms();
  while (`CORE.run && now_ms() - t0 < 60.0) wait_us(100);
  check(`CORE.run == 1'b0, "radio stopped by the watchdog without EP2 packets");
  wait_ms(3.0);
  p0 = ep6_packets;
  wait_ms(10.0);
  check(ep6_packets == p0, "no EP6 packets after the watchdog stop");

  // Start with the watchdog disabled (bit 7 of the start command)
  send_udp(hpsdr_startstop(1'b1, 1'b0, 1'b1));
  wait_ms(3.0);
  `CORE.dsopenhpsdr1_i.watchdog_cnt = 12'hffe;
  `CORE.usopenhpsdr1_i.bs_cnt = 7'd1;
  wait_ms(30.0);
  check(`CORE.run == 1'b1, "watchdog disabled by the start command keeps the radio running");
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// dhcp: address from a DHCP server when no static IP is configured
task automatic test_dhcp();
  bit ok;
  cfg_eeprom_config = 8'h00;
  dhcp_server_on = 1'b1;
  power_up();
  wait_network(ok, 60.0);
  check(ok, "network has an IP address");
  check(`CORE.network_inst.local_ip == dhcp_offer_ip,
        $sformatf("IP from DHCP: %s", ip2str(`CORE.network_inst.local_ip)));
  check(`CORE.network_state_dhcp == 1'b0, "DHCP state flag");
  check(dhcp_discovers >= 1 && dhcp_requests >= 1,
        $sformatf("DHCP DISCOVER (%0d) and REQUEST (%0d) seen", dhcp_discovers, dhcp_requests));
  check(dhcp_requested_ip == dhcp_offer_ip, $sformatf("REQUEST asks for the offered IP (%s)", ip2str(dhcp_requested_ip)));
  wait_radio_ready();
  discover(ok);
  check(ok && disc_info[$].src_ip == dhcp_offer_ip, "discovery answered from the DHCP address");
endtask

//------------------------------------------------------------------------------
// eeprom_override: both paddles pressed at power up ignore the EEPROM IP config
task automatic test_eeprom_override();
  bit ok;
  cfg_eeprom_config = 8'h80;                 // static IP configured
  dhcp_server_on = 1'b1;
  io_phone_tip = 1'b0;
  io_phone_ring = 1'b0;
  power_up();
  wait_ms(8.0);
  io_phone_tip = 1'b1;
  io_phone_ring = 1'b1;
  wait_network(ok, 60.0);
  check(ok, "network has an IP address");
  check(`CORE.network_inst.local_ip == dhcp_offer_ip,
        $sformatf("static IP ignored, DHCP used: %s", ip2str(`CORE.network_inst.local_ip)));
  check(`CORE.eeprom_config[7:5] == 3'b000, "EEPROM config bits masked");
endtask

//------------------------------------------------------------------------------
// reboot: command 0x3a reboots to the factory image, but not while running
task automatic test_reboot();
  bit ok;
  rx_bring_up(ok);
  if (!ok) return;
  send_cmd(6'h3a, 32'h0000_0001);
  wait_ms(8.0);
  check(!rublock_reconfig(), "no reconfiguration while running");
  ep2_run = 1'b0;
  hpsdr_stop();
  wait_ms(1.0);
  check(rublock_reconfig(), "reconfiguration requested after the radio stops");
endtask

function automatic bit rublock_reconfig();
  return `CORE.INCLUDEASMII.remote_update_i.remote_update_core.sd4.reconfig_seen;
endfunction

//------------------------------------------------------------------------------
// factory_boot: the factory image loads the application image at power up;
// with both paddles pressed it stays in the factory image
task automatic test_factory_boot();
  cfg_factory_image = 1'b1;
  power_up();
  wait_ms(2.0);
  check(rublock_reconfig(), "factory image reconfigures into the application image");
endtask

task automatic test_factory_hold();
  cfg_factory_image = 1'b1;
  io_phone_tip = 1'b0;
  io_phone_ring = 1'b0;
  power_up();
  wait_ms(2.0);
  check(!rublock_reconfig(), "both paddles pressed: stays in the factory image");
  io_phone_tip = 1'b1;
  io_phone_ring = 1'b1;
endtask

//------------------------------------------------------------------------------
// wideband: EP4 raw ADC samples, one EP4 packet every set_bs_cnt EP6 packets
task automatic test_wideband();
  bit ok;
  logic signed [11:0] x[$];
  real fr, t0;
  int p0, b0, sbc;
  bring_up(ok);
  if (!ok) return;
  ad9866.set_tone(0, 7.5e6, 0.5);
  set_config(3, 1, 32'h0000_0004);            // 384 ksps: set_bs_cnt = 1 << 3 = 8
  flush_cmds();
  ep2_run = 1'b1;
  send_udp(hpsdr_startstop(1'b1, 1'b1));
  // The bandscope FIFO holds a 2048 sample snapshot that is refilled only
  // once it has been read out (4 EP4 packets): use the second snapshot
  t0 = now_ms();
  while (ep4_packets < 8 && now_ms() - t0 < 80.0) wait_us(100);
  check(ep4_packets >= 8, $sformatf("EP4 wide band packets received (%0d)", ep4_packets));
  if (ep4_samples.size() >= 4096) begin
    for (int k = 2048; k < 4096; k++) x.push_back(12'(ep4_samples[k] >>> 4));
    fr = real_tone_fraction(x, 76.8e6, 7.5e6);
    info($sformatf("EP4: tone fraction at 7.5 MHz %0.3f", fr));
    check(fr > 0.9, "EP4 samples contain the ADC tone (76.8 Msps raw samples)");
  end
  // Cadence
  sbc = `CORE.usopenhpsdr1_i.set_bs_cnt;
  p0 = ep6_packets;
  b0 = ep4_packets;
  wait_ms(40.0);
  info($sformatf("wideband: %0d EP4 for %0d EP6 packets in 40 ms (set_bs_cnt %0d)",
                 ep4_packets - b0, ep6_packets - p0, sbc));
  check(ep4_packets - b0 >= (ep6_packets - p0) / sbc - 2,
        $sformatf("one EP4 packet every set_bs_cnt=%0d EP6 packets (%0d EP4 for %0d EP6)",
                  sbc, ep4_packets - b0, ep6_packets - p0));
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// fan: fan PWM and overheat TX block from the temperature reading
task automatic test_fan();
  bit ok;
  real t0;
  set_slow_adc(12'h000, 12'h400, 12'h000, 12'h000);     // ~30 C
  tx_bring_up(ok);
  if (!ok) return;
  check(`CORE.control_i.FAN_blk.fan_state == 3'b000, "fan off at 30 C");
  adc.adc[1] = 12'h470;                                  // > 40 C
  t0 = now_ms();
  while (`CORE.control_i.FAN_blk.fan_state == 3'b000 && now_ms() - t0 < 60.0) wait_us(200);
  check(`CORE.control_i.FAN_blk.fan_state == 3'b001, "fan low speed above 37 C");
  adc.adc[1] = 12'h600;                                  // > 60 C
  t0 = now_ms();
  while (`CORE.control_i.FAN_blk.fan_state != 3'b110 && now_ms() - t0 < 120.0) wait_us(200);
  check(`CORE.control_i.FAN_blk.fan_state == 3'b110, "overheat state above 55 C");
  check(io_db1_4 == 1'b1, "fan output on in overheat");
  host_ptt = 1'b1;
  tx_bb_amp = 0.25;
  wait_ms(16.0);
  check(!pa_inttr && !pa_exttr && !pwr_envbias, "overheat blocks the PA/TR outputs");
  check(ad_txquiet_n !== 1'b1, "overheat also keeps the AD9866 transmitter off");
  host_ptt = 1'b0;
  ep2_run = 1'b0;
  hpsdr_stop();
endtask

//------------------------------------------------------------------------------
// Test registry: every test runs in its own process (one coroutine per test
// keeps the generated C++ functions small enough to compile quickly).

`define HL2_TEST(name) \
  initial begin \
    wait (test_go); \
    if (test_name == `"name`") begin \
      test_found = 1'b1; \
      test_``name(); \
      test_done = 1'b1; \
    end \
  end

`HL2_TEST(boot)
`HL2_TEST(discovery)
`HL2_TEST(arp_icmp)
`HL2_TEST(rx)
`HL2_TEST(rx_rates)
`HL2_TEST(tx)
`HL2_TEST(cw_iambic)
`HL2_TEST(cw_straight)
`HL2_TEST(cwx)
`HL2_TEST(responses)
`HL2_TEST(tx_inhibit)
`HL2_TEST(tx_glitch)
`HL2_TEST(i2c_cmd)
`HL2_TEST(ad9866_spi_busy)
`HL2_TEST(ad9866_spi_init)
`HL2_TEST(lna_gain)
`HL2_TEST(watchdog)
`HL2_TEST(dhcp)
`HL2_TEST(eeprom_override)
`HL2_TEST(reboot)
`HL2_TEST(factory_boot)
`HL2_TEST(factory_hold)
`HL2_TEST(wideband)
`HL2_TEST(fan)
