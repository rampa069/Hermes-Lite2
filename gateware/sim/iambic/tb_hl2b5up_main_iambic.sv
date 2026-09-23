//
// Icarus Verilog testbench for the hl2b5up_main_iambic variant.
//
// The full hermeslite top level (PLLs, Ethernet, AD9866, ...) is not simulable in
// Icarus, so this bench covers the logic that makes this variant different from
// hl2b5up_main (HL2_CW=2, HL2_SIDETONE_DB1=1):
//
//   phone tip/ring -> debounce -> cw_openhpsdr/iambic -> cw_keydown / cw_ptt
//                                                      -> cw_sidetone -> sigma_delta_dac -> io_db1_1
//
// The glue in hl2b5up_main_iambic_cw mirrors control.sv and hermeslite_core.sv
// for this configuration. radio.sv is replaced by a small model of its CW
// envelope (cw_on / cw_profile ramp), see below.
//
// Clocks as on the board: clk_ctrl 2.5 MHz, clk_slow 48 kHz (76.8 MHz / 1600),
// clk_ad9866 76.8 MHz. The 76.8 MHz clock is only run when needed to keep the
// simulation fast.
//

`timescale 1 ns/1 ps

module tb_hl2b5up_main_iambic;

//------------------------------------------------------------------------------
// Clocks
reg clk_ctrl = 1'b0;
always #200 clk_ctrl = ~clk_ctrl;               // 2.5 MHz

reg clk_slow = 1'b0;
always #10416.667 clk_slow = ~clk_slow;         // 48 kHz

reg clk_ad9866 = 1'b0;
reg fast_en    = 1'b0;                          // gate for the 76.8 MHz clock
reg keep_fast  = 1'b0;
always begin
  wait (fast_en);
  #6.510 clk_ad9866 = ~clk_ad9866;              // 76.8 MHz
end

//------------------------------------------------------------------------------
// DUT
reg  [ 5:0] cmd_addr        = 6'h0;
reg  [31:0] cmd_data        = 32'h0;
reg         cmd_rqst_io     = 1'b0;
reg         cmd_rqst_ad9866 = 1'b0;
reg         io_phone_tip    = 1'b1;             // active low, tip = dot
reg         io_phone_ring   = 1'b1;             // active low, ring = dash

wire cw_keydown, cw_ptt, io_db1_1;

hl2b5up_main_iambic_cw dut (
  .clk_ctrl        (clk_ctrl       ),
  .clk_slow        (clk_slow       ),
  .clk_ad9866      (clk_ad9866     ),
  .cmd_addr        (cmd_addr       ),
  .cmd_data        (cmd_data       ),
  .cmd_rqst_io     (cmd_rqst_io    ),
  .cmd_rqst_ad9866 (cmd_rqst_ad9866),
  .io_phone_tip    (io_phone_tip   ),
  .io_phone_ring   (io_phone_ring  ),
  .cw_keydown      (cw_keydown     ),
  .ext_ptt         (cw_ptt         ),
  .io_sidetone_out (io_db1_1       )
);

// The FPGA clears every register at configuration; many of these have no
// initializer in the RTL and would otherwise stay X forever in simulation.
initial begin
  dut.de_phone_tip.pb_history  = 6'b0;
  dut.de_phone_tip.clean_pb    = 1'b0;
  dut.de_phone_ring.pb_history = 6'b0;
  dut.de_phone_ring.clean_pb   = 1'b0;
  dut.cw_openhpsdr_i.keyer_reverse = 1'b0;
  dut.cw_openhpsdr_i.keyer_speed   = 6'd0;
  dut.cw_openhpsdr_i.keyer_mode    = 2'd0;
  dut.cw_openhpsdr_i.keyer_weight  = 8'd0;
  dut.cw_openhpsdr_i.keyer_spacing = 1'b0;
  dut.cw_openhpsdr_i.cw_ptt_delay  = 8'd0;
  dut.cw_openhpsdr_i.cw_hang_time  = 10'd0;
  dut.cw_openhpsdr_i.dot_delay     = 16'd0;
  dut.cw_openhpsdr_i.dash_delay    = 18'd0;
  dut.cw_openhpsdr_i.iambic_i.keyer_out = 1'b0;
  dut.cw_openhpsdr_i.iambic_i.cw_ptt    = 1'b0;
  dut.cw_openhpsdr_i.iambic_i.delay     = 0;
  dut.cw_sidetone_i.period = 10'd0;
  dut.cw_sidetone_i.acc    = 21'd0;
  dut.cw_sidetone_i.freq   = 12'd0;
  dut.cw_sidetone_i.scaler = 10'd0;
  dut.cw_sidetone_i.tblptr = 10'd0;
end

initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("tb_hl2b5up_main_iambic.vcd");
    $dumpvars(0, tb_hl2b5up_main_iambic);
  end
end

//------------------------------------------------------------------------------
// Bookkeeping
integer errors = 0;
integer checks = 0;

task automatic check(input bit cond, input string msg);
  checks = checks + 1;
  if (!cond) begin
    errors = errors + 1;
    $display("  FAIL: %s", msg);
  end else if ($test$plusargs("verbose")) begin
    $display("  ok:   %s", msg);
  end
endtask

task automatic check_near(input real act, input real exp, input real tol, input string what);
  checks = checks + 1;
  if (act > exp + tol || act < exp - tol) begin
    errors = errors + 1;
    $display("  FAIL: %s = %0.3f, expected %0.3f +/- %0.3f", what, act, exp, tol);
  end else if ($test$plusargs("verbose")) begin
    $display("  ok:   %s = %0.3f (expected %0.3f)", what, act, exp);
  end
endtask

function real now_ms();
  now_ms = $realtime / 1.0e6;
endfunction

task automatic wait_ms(input real t);
  #(t * 1.0e6);
endtask

// Key-down / PTT edge log (times in ms)
localparam MAXEL = 64;
real    kd_rise [0:MAXEL-1];
real    kd_fall [0:MAXEL-1];
integer n_rise = 0, n_fall = 0;
real    ptt_rise = 0.0, ptt_fall = 0.0;
reg     log_en = 1'b0;

always @(posedge cw_keydown) if (log_en && n_rise < MAXEL) begin kd_rise[n_rise] = now_ms(); n_rise = n_rise + 1; end
always @(negedge cw_keydown) if (log_en && n_fall < MAXEL) begin kd_fall[n_fall] = now_ms(); n_fall = n_fall + 1; end
always @(posedge cw_ptt)     if (log_en) ptt_rise = now_ms();
always @(negedge cw_ptt)     if (log_en) ptt_fall = now_ms();

task automatic clear_log();
  n_rise = 0;
  n_fall = 0;
  ptt_rise = 0.0;
  ptt_fall = 0.0;
  log_en = 1'b1;
endtask

// Wait until the keyer has finished (PTT released) and settle a bit.
task automatic wait_idle();
  wait_ms(2);
  wait (cw_ptt == 1'b0);
  wait_ms(2);
endtask

task automatic dump_log();
  integer i;
  for (i = 0; i < n_rise; i = i + 1)
    $display("    element %0d: start %0.3f ms  width %0.3f ms", i, kd_rise[i],
             (i < n_fall) ? kd_fall[i] - kd_rise[i] : -1.0);
endtask

//------------------------------------------------------------------------------
// Protocol 1 command helpers
integer cfg_ptt_delay = 0;    // ms
integer cfg_hang      = 0;    // ms
integer cfg_vol       = 0;    // sidetone volume 0-127
integer cfg_freq      = 600;  // sidetone frequency Hz

task automatic send_cmd(input [5:0] addr, input [31:0] data);
  fast_en = 1'b1;
  @(negedge clk_ctrl);   cmd_addr = addr; cmd_data = data; cmd_rqst_io = 1'b1;
  @(negedge clk_ctrl);   cmd_rqst_io = 1'b0;
  @(negedge clk_ad9866); cmd_rqst_ad9866 = 1'b1;
  @(negedge clk_ad9866); cmd_rqst_ad9866 = 1'b0;
  fast_en = keep_fast;
  repeat (60) @(posedge clk_ctrl);             // dot/dash divider needs 50 clocks
endtask

task automatic send_cw_config();
  reg [31:0] d;
  // 0x0f: [23:16] sidetone volume, [15:8] CW PTT delay (ms)
  d = 32'h0;
  d[23:16] = cfg_vol;
  d[15:8]  = cfg_ptt_delay;
  send_cmd(6'h0f, d);
  // 0x10: {[31:24],[17:16]} CW hang time (ms), {[15:8],[3:0]} sidetone frequency (Hz)
  d = 32'h0;
  {d[31:24], d[17:16]} = cfg_hang;
  {d[15:8],  d[3:0]}   = cfg_freq;
  send_cmd(6'h10, d);
endtask

// Keyer timing in clk_slow ticks, as the RTL is expected to compute it
integer exp_dot_ticks, exp_dash_ticks;
real    dot_ms, dash_ms, tick_ms;
initial tick_ms = 1.0 / 48.0;

task automatic set_keyer(input [1:0] mode, input integer wpm, input integer weight,
                         input bit spacing, input bit swap);
  reg [31:0] d;
  d = 32'h0;
  d[22]    = swap;
  d[15:14] = mode;
  d[13:8]  = wpm;
  d[7]     = spacing;
  d[6:0]   = weight;
  send_cmd(6'h0b, d);
  exp_dot_ticks  = 57600 / wpm;                        // 1200 ms / WPM at 48 kHz
  exp_dash_ticks = (exp_dot_ticks * 3 * weight) / 50;
  // The keyer holds an element for delay+1 ticks
  dot_ms  = (exp_dot_ticks  + 1) * tick_ms;
  dash_ms = (exp_dash_ticks + 1) * tick_ms;
endtask

// Paddles (active low on the connector)
task automatic tap_tip(input real t);  io_phone_tip  = 1'b0; wait_ms(t); io_phone_tip  = 1'b1; endtask
task automatic tap_ring(input real t); io_phone_ring = 1'b0; wait_ms(t); io_phone_ring = 1'b1; endtask

// Check every element width and the gap between elements
task automatic check_train(input real width, input real gap, input real tol, input string what);
  integer i;
  for (i = 0; i < n_fall; i = i + 1)
    check_near(kd_fall[i] - kd_rise[i], width, tol, $sformatf("%s width[%0d] (ms)", what, i));
  for (i = 0; i + 1 < n_rise && i < n_fall; i = i + 1)
    check_near(kd_rise[i+1] - kd_fall[i], gap, tol, $sformatf("%s gap[%0d] (ms)", what, i));
endtask

//------------------------------------------------------------------------------
// Tests

// 1. Dot/dash length divider in cw_openhpsdr for every speed and a few weights
task automatic test_speed_divider();
  integer wpm, wi, weight, bad;
  integer weights [0:2];
  weights[0] = 33; weights[1] = 50; weights[2] = 66;
  $display("[1] keyer speed/weight divider, 1..60 WPM");
  bad = 0;
  for (wi = 0; wi < 3; wi = wi + 1) begin
    weight = weights[wi];
    for (wpm = 1; wpm <= 60; wpm = wpm + 1) begin
      set_keyer(2'b01, wpm, weight, 1'b0, 1'b0);
      if (dut.cw_openhpsdr_i.dot_delay  !== exp_dot_ticks[15:0] ||
          dut.cw_openhpsdr_i.dash_delay !== exp_dash_ticks[17:0]) begin
        bad = bad + 1;
        if (bad <= 10)
          $display("  %0d WPM weight %0d: dot %0d (exp %0d) dash %0d (exp %0d)", wpm, weight,
                   dut.cw_openhpsdr_i.dot_delay, exp_dot_ticks,
                   dut.cw_openhpsdr_i.dash_delay, exp_dash_ticks);
      end
    end
  end
  check(bad == 0, $sformatf("dot/dash delays match 57600/WPM and 3*dot*weight/50 (%0d mismatches)", bad));
endtask

// 2. Single dot tap: element length, PTT delay and hang time
task automatic test_single_dot();
  real t0;
  $display("[2] Mode A, 40 WPM: single dot, PTT delay %0d ms, hang %0d ms", cfg_ptt_delay, cfg_hang);
  set_keyer(2'b01, 40, 50, 1'b0, 1'b0);
  clear_log();
  t0 = now_ms();
  tap_tip(5);
  wait_idle();
  check(n_rise == 1 && n_fall == 1, $sformatf("one element sent (got %0d)", n_rise));
  if (n_fall >= 1) begin
    check_near(kd_fall[0] - kd_rise[0], dot_ms, 0.1, "dot width (ms)");
    // debounce: a press shows up on the 2nd msec_pulse (1-2 ms), a release on the 1st (0-1 ms)
    check_near(ptt_rise - t0, 1.55, 0.6, "paddle to PTT latency (ms)");
    check_near(kd_rise[0] - ptt_rise, cfg_ptt_delay + 2 * tick_ms, 0.1, "PTT lead before key (ms)");
    // DOTDELAY + DOTHELD + BKDELAY (hang) + LOOP
    check_near(ptt_fall - kd_fall[0], dot_ms + cfg_hang + 3 * tick_ms, 0.1, "PTT tail after key (ms)");
  end
endtask

// 3. Held dot paddle: dot train with 1:1 duty
task automatic test_dot_train();
  $display("[3] Mode A, 40 WPM: held dot paddle");
  set_keyer(2'b01, 40, 50, 1'b0, 1'b0);
  clear_log();
  tap_tip(200);
  wait_idle();
  check(n_rise >= 3, $sformatf("at least 3 dots (got %0d)", n_rise));
  check_train(dot_ms, dot_ms + 2 * tick_ms, 0.1, "dot");
endtask

// 4. Held dash paddle and weighting
task automatic test_dash_train(input integer weight);
  $display("[4] Mode A, 40 WPM, weight %0d: held dash paddle", weight);
  set_keyer(2'b01, 40, weight, 1'b0, 1'b0);
  clear_log();
  tap_ring(350);
  wait_idle();
  check(n_rise >= 3, $sformatf("at least 3 dashes (got %0d)", n_rise));
  check_train(dash_ms, dot_ms + 2 * tick_ms, 0.1, "dash");
endtask

// 5. Squeeze: dash first, then both, release both in the middle of the 3rd element.
//    Mode A stops after the current element (K = -.-), Mode B adds the opposite one (C = -.-.).
task automatic test_squeeze(input [1:0] mode);
  integer expect_n, i;
  $display("[5] Mode %s, 40 WPM: squeeze, release during 3rd element", (mode == 2'b01) ? "A" : "B");
  set_keyer(mode, 40, 50, 1'b0, 1'b0);
  clear_log();
  io_phone_ring = 1'b0;
  wait_ms(2);
  io_phone_tip = 1'b0;
  wait (n_rise == 3);
  wait_ms(20);
  io_phone_ring = 1'b1;
  io_phone_tip  = 1'b1;
  wait_idle();
  expect_n = (mode == 2'b01) ? 3 : 4;
  check(n_rise == expect_n, $sformatf("%0d elements sent (got %0d)", expect_n, n_rise));
  for (i = 0; i < n_fall && i < 4; i = i + 1)
    check_near(kd_fall[i] - kd_rise[i], (i % 2 == 0) ? dash_ms : dot_ms, 0.1,
               $sformatf("element %0d is a %s (ms)", i, (i % 2 == 0) ? "dash" : "dot"));
  if ($test$plusargs("verbose")) dump_log();
endtask

// 6. Paddle swap: tip becomes dash
task automatic test_paddle_swap();
  $display("[6] Mode A, 40 WPM, paddle swap: tip tap");
  set_keyer(2'b01, 40, 50, 1'b0, 1'b1);
  clear_log();
  tap_tip(5);
  wait_idle();
  check(n_rise == 1, $sformatf("one element sent (got %0d)", n_rise));
  if (n_fall >= 1) check_near(kd_fall[0] - kd_rise[0], dash_ms, 0.1, "swapped tip sends a dash (ms)");
  set_keyer(2'b01, 40, 50, 1'b0, 1'b0);
endtask

// 7. Automatic letter space: a dot entered right after a dot waits for a 3-dot space
task automatic test_letter_space(input bit spacing);
  real gap, gap_exp;
  $display("[7] Mode A, 40 WPM, letter spacing %s", spacing ? "on" : "off");
  set_keyer(2'b01, 40, 50, spacing, 1'b0);
  clear_log();
  tap_tip(5);
  wait (n_fall == 1);
  wait_ms(dot_ms + 3.0);
  tap_tip(5);
  wait_idle();
  check(n_rise == 2, $sformatf("two elements sent (got %0d)", n_rise));
  if (n_rise == 2) begin
    gap = kd_rise[1] - kd_fall[0];
    if (spacing) begin
      // DOTDELAY + DOTHELD + LETTERSPACE(2*dot) + PREDOT
      gap_exp = (3 * exp_dot_ticks + 4) * tick_ms;
      check_near(gap, gap_exp, 0.1, "gap with letter space (ms)");
    end else begin
      // paddle pressed dot+3 ms after the dot, plus 1-2 ms debounce
      check_near(gap, dot_ms + 3.0 + 1.55, 0.6, "gap without letter space (ms)");
    end
  end
endtask

// 8. Mode 00: ring is a straight key, tip gives automatic (bug) dots
task automatic test_straight_and_bug();
  real t0;
  $display("[8] Mode straight/bug, 40 WPM");
  set_keyer(2'b00, 40, 50, 1'b0, 1'b0);
  clear_log();
  t0 = now_ms();
  tap_ring(100);
  wait_idle();
  check(n_rise == 1, $sformatf("straight key: one element (got %0d)", n_rise));
  if (n_fall >= 1) begin
    check_near(kd_rise[0] - t0, cfg_ptt_delay + 1.55, 0.6, "straight key: press to key-down (ms)");
    check_near(kd_fall[0] - (t0 + 100.0), 0.6, 0.6, "straight key: release to key-up (ms)");
  end

  clear_log();
  tap_tip(150);
  wait_idle();
  check(n_rise >= 2, $sformatf("bug: at least 2 automatic dots (got %0d)", n_rise));
  check_train(dot_ms, dot_ms + 2 * tick_ms, 0.1, "bug dot");
endtask

// 9. Sidetone generator and DB1-1 sigma-delta output
task automatic test_sidetone();
  integer i, n, ones, win, nwin, ncross;
  integer s, s_prev, s_max, s_min;
  real    s_sum, dens, dens_exp, err_sum, err_max;
  real    t_first, t_last, f_meas, peak_exp;
  integer dac_bad;

  $display("[9] sidetone %0d Hz, volume %0d, on DB1-1", cfg_freq, cfg_vol);
  keep_fast = 1'b1;
  fast_en   = 1'b1;
  send_cw_config();
  set_keyer(2'b00, 40, 50, 1'b0, 1'b0);
  clear_log();

  io_phone_ring = 1'b0;                     // straight key down
  wait (dut.cw_on == 1'b1);
  wait_ms(4.5);                             // envelope ramp (radio.sv) is ~4.1 ms

  // Measure 5 ms of sidetone and DAC output in windows of one sine step
  win = dut.cw_sidetone_i.period;
  nwin = 0; ncross = 0; err_sum = 0.0; err_max = 0.0;
  s_max = -32768; s_min = 32767; s_prev = 0;
  t_first = 0.0; t_last = 0.0;
  n = 5 * 76800 / win;
  for (i = 0; i < n; i = i + 1) begin
    ones = 0; s_sum = 0.0;
    repeat (win) begin
      @(posedge clk_ad9866);
      s = $signed(dut.sidetone_audio);
      ones  = ones + io_db1_1;
      s_sum = s_sum + s;
      if (s > s_max) s_max = s;
      if (s < s_min) s_min = s;
      if (s_prev < 0 && s >= 0) begin
        if (ncross == 0) t_first = now_ms();
        t_last = now_ms();
        ncross = ncross + 1;
      end
      s_prev = s;
    end
    // Expected pulse density for an offset-binary 1-bit DAC: (x + 32768) / 65536
    dens     = ones * 1.0 / win;
    dens_exp = (s_sum / win + 32768.0) / 65536.0;
    err_sum  = err_sum + ((dens > dens_exp) ? dens - dens_exp : dens_exp - dens);
    if (((dens > dens_exp) ? dens - dens_exp : dens_exp - dens) > err_max)
      err_max = (dens > dens_exp) ? dens - dens_exp : dens_exp - dens;
    nwin = nwin + 1;
  end

  check(ncross >= 2, $sformatf("sidetone oscillates (%0d rising zero crossings)", ncross));
  if (ncross >= 2) begin
    f_meas = (ncross - 1) / ((t_last - t_first) / 1000.0);
    check_near(f_meas, 75000.0 / (75000 / cfg_freq), cfg_freq * 0.01, "sidetone frequency (Hz)");
  end
  // sine peak 255 * profile 77 (MSBs of 17 bits) * volume (MSBs of 24 bits)
  peak_exp = ((255 * 77) / 2 * cfg_vol) / 256;
  check_near(s_max, peak_exp, peak_exp * 0.03, "sidetone positive peak");
  check_near(-s_min, peak_exp, peak_exp * 0.03, "sidetone negative peak");
  $display("  DAC pulse density error: mean %0.4f max %0.4f over %0d windows", err_sum / nwin, err_max, nwin);
  check(err_sum / nwin < 0.02, "DB1-1 pulse density follows the sidetone (mean error < 0.02)");

  // Key up: once cw_on drops the DAC output must be held low
  io_phone_ring = 1'b1;
  wait (dut.cw_on == 1'b0);
  repeat (2) @(posedge clk_ad9866);         // dac_out is registered
  dac_bad = 0;
  repeat (38400) begin
    @(posedge clk_ad9866);
    if (io_db1_1 !== 1'b0) dac_bad = dac_bad + 1;
  end
  check(dac_bad == 0, "DB1-1 low after key up");
  wait_idle();

  // Volume 0 disables the DAC even while keyed
  cfg_vol = 0;
  send_cw_config();
  io_phone_ring = 1'b0;
  wait (dut.cw_on == 1'b1);
  repeat (2) @(posedge clk_ad9866);
  dac_bad = 0;
  repeat (5 * 76800) begin
    @(posedge clk_ad9866);
    if (io_db1_1 !== 1'b0) dac_bad = dac_bad + 1;
  end
  check(dac_bad == 0, "DB1-1 low with volume 0 while keyed");
  io_phone_ring = 1'b1;
  wait_idle();

  keep_fast = 1'b0;
  fast_en   = 1'b0;
endtask

//------------------------------------------------------------------------------
initial begin
  $display("hl2b5up_main_iambic CW testbench");
  wait_ms(10);                              // debouncers settle

  cfg_ptt_delay = 5;
  cfg_hang      = 50;
  cfg_vol       = 0;
  cfg_freq      = 600;
  send_cw_config();

  test_speed_divider();
  test_single_dot();
  test_dot_train();
  test_dash_train(50);
  test_dash_train(66);
  test_squeeze(2'b01);
  test_squeeze(2'b10);
  test_paddle_swap();
  test_letter_space(1'b1);
  test_letter_space(1'b0);
  test_straight_and_bug();

  cfg_vol = 64;
  test_sidetone();

  $display("");
  if (errors == 0) $display("PASSED: %0d checks", checks);
  else             $display("FAILED: %0d of %0d checks", errors, checks);
  $finish;
end

// Watchdog
initial begin
  #(20.0e9);
  $display("FAILED: watchdog timeout");
  $finish;
end

endmodule


//------------------------------------------------------------------------------
// CW path of hl2b5up_main_iambic: HL2_CW=2, HL2_AK4951=0, HL2_SIDETONE_DB1=1.
//------------------------------------------------------------------------------
module hl2b5up_main_iambic_cw (
  input         clk_ctrl,
  input         clk_slow,
  input         clk_ad9866,
  input  [ 5:0] cmd_addr,
  input  [31:0] cmd_data,
  input         cmd_rqst_io,
  input         cmd_rqst_ad9866,
  input         io_phone_tip,
  input         io_phone_ring,
  output        cw_keydown,
  output        ext_ptt,
  output        io_sidetone_out
);

// control.sv: millisecond pulse for the debouncers
logic [9:0] qmillisec_count = 10'd0;
logic [1:0] millisec_count  = 2'd0;
logic       msec_pulse;

always @(posedge clk_ctrl) begin
  if (qmillisec_count == 10'd0) begin
    qmillisec_count <= 10'd625;
    millisec_count  <= millisec_count - 2'd1;
  end else begin
    qmillisec_count <= qmillisec_count - 10'd1;
  end
end
assign msec_pulse = (qmillisec_count == 10'd0) & (&millisec_count);

// control.sv: CW == 2, AK4951 == 0
logic ext_cwkey, clean_ring, cw_ptt;

debounce de_phone_tip (.clean_pb(ext_cwkey),  .pb(~io_phone_tip),  .clk(clk_ctrl), .msec_pulse(msec_pulse));
debounce de_phone_ring(.clean_pb(clean_ring), .pb(~io_phone_ring), .clk(clk_ctrl), .msec_pulse(msec_pulse));

assign ext_ptt = cw_ptt;

cw_openhpsdr cw_openhpsdr_i (
  .clk               (clk_ctrl  ),
  .clk_slow          (clk_slow  ),
  .cmd_addr          (cmd_addr  ),
  .cmd_data          (cmd_data  ),
  .cmd_rqst          (cmd_rqst_io),
  .dot_key           (ext_cwkey ),
  .dash_key          (clean_ring),
  .cw_ptt            (cw_ptt    ),
  .cw_keydown        (cw_keydown)
);

// hermeslite_core.sv: cw_keydown into the AD9866 domain
logic cw_keydown_ad9866sync;
sync sync_cw_keydown (
  .clock(clk_ad9866),
  .sig_in(cw_keydown),
  .sig_out(cw_keydown_ad9866sync)
);

// Model of radio.sv CWTX: cw_profile ramps one step per clock between 0 and
// MAX_CWLEVEL, cw_on is high while keyed or ramping. The CWHANG state is not
// modelled (it keeps cw_on high with cw_profile[18:12] == 0).
localparam MAX_CWLEVEL = 19'h4d800;
logic [18:0] cw_profile = 19'h0;
logic        cw_on;

always @(posedge clk_ad9866) begin
  if (cw_keydown_ad9866sync === 1'b1) begin
    if (cw_profile != MAX_CWLEVEL) cw_profile <= cw_profile + 19'h1;
  end else if (cw_profile != 19'h0) begin
    cw_profile <= cw_profile - 19'h1;
  end
end
assign cw_on = (cw_keydown_ad9866sync === 1'b1) | (cw_profile != 19'h0);

// hermeslite_core.sv: CW == 2 without AK4951
logic [ 7:0] sidetone_vol  = 8'h0;
logic [11:0] sidetone_freq = 12'h0;

always @(posedge clk_ad9866) begin
  if (cmd_rqst_ad9866) begin
    case (cmd_addr)
      6'h0f: begin
        sidetone_vol <= cmd_data[23:16];
      end
      6'h10: begin
        sidetone_freq <= {cmd_data[15:8], cmd_data[3:0]};
      end
    endcase
  end
end

wire signed [15:0] sidetone_audio;

cw_sidetone cw_sidetone_i (
  .clk(clk_ad9866),
  .tone_enb(cw_on),
  .tonefreq(sidetone_freq),
  .profile(cw_profile[18:12]),
  .audiovolume(sidetone_vol),
  .sidetone(sidetone_audio)
);

sigma_delta_dac sigma_delta_dac_i (
  .clk(clk_ad9866),
  .data_in(sidetone_audio),
  .enable(cw_on & (sidetone_vol != 8'b0)),
  .dac_out(io_sidetone_out)
);

endmodule
