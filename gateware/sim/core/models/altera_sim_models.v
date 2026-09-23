//
// Behavioral simulation models of the Intel/Altera megafunctions and hard
// blocks used by the Hermes-Lite 2 gateware, for Verilator (--timing) and
// Icarus Verilog.
//
// These are written from the documented behavior of each megafunction and only
// implement the features and parameters that the HL2 RTL uses. They are not
// cycle-exact copies of altera_mf.v / 220model.v (not available on macOS).
//
// Memory init files: altsyncram loads "<basename>.hex" from the simulation run
// directory for init_file "<path>/<basename>.mif". The Makefile generates the
// .hex files from the .mif files in rtl/ with scripts/mif2hex.py.
//

`timescale 1 ps/1 fs

//------------------------------------------------------------------------------
// altpll: outputs are free running clocks derived from inclk0_input_frequency
// (ps). They start aligned to an input rising edge (plus clkN_phase_shift) once
// areset is low. The testbench must drive the input clock with exactly the
// period given in inclk0_input_frequency; with 1 fs precision all periods
// used by the HL2 PLLs are exact, so outputs stay phase locked to the input.
//------------------------------------------------------------------------------
module altpll (
  inclk, fbin, pllena, clkswitch, areset, pfdena, clkena, extclkena, scanclk,
  scanaclr, scanclkena, scanread, scanwrite, scandata, phasecounterselect,
  phaseupdown, phasestep, configupdate, fbmimicbidir, clk, extclk, clkbad,
  enable0, enable1, activeclock, clkloss, locked, scandataout, scandone,
  sclkout0, sclkout1, phasedone, vcooverrange, vcounderrange, fbout, fref,
  icdrclk
);
  parameter intended_device_family = "Cyclone IV E";
  parameter operation_mode = "NORMAL";
  parameter pll_type = "AUTO";
  parameter bandwidth_type = "AUTO";
  parameter compensate_clock = "CLK0";
  parameter inclk0_input_frequency = 10000;
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "altpll";
  parameter self_reset_on_loss_lock = "OFF";
  parameter width_clock = 5;
  parameter clk0_multiply_by = 1, clk0_divide_by = 1, clk0_duty_cycle = 50;
  parameter clk1_multiply_by = 1, clk1_divide_by = 1, clk1_duty_cycle = 50;
  parameter clk2_multiply_by = 1, clk2_divide_by = 1, clk2_duty_cycle = 50;
  parameter clk3_multiply_by = 1, clk3_divide_by = 1, clk3_duty_cycle = 50;
  parameter clk4_multiply_by = 1, clk4_divide_by = 1, clk4_duty_cycle = 50;
  parameter clk0_phase_shift = "0", clk1_phase_shift = "0", clk2_phase_shift = "0",
            clk3_phase_shift = "0", clk4_phase_shift = "0";
  parameter port_activeclock = "PORT_UNUSED", port_areset = "PORT_UNUSED",
            port_clkbad0 = "PORT_UNUSED", port_clkbad1 = "PORT_UNUSED",
            port_clkloss = "PORT_UNUSED", port_clkswitch = "PORT_UNUSED",
            port_configupdate = "PORT_UNUSED", port_fbin = "PORT_UNUSED",
            port_inclk0 = "PORT_USED", port_inclk1 = "PORT_UNUSED",
            port_locked = "PORT_UNUSED", port_pfdena = "PORT_UNUSED",
            port_phasecounterselect = "PORT_UNUSED", port_phasedone = "PORT_UNUSED",
            port_phasestep = "PORT_UNUSED", port_phaseupdown = "PORT_UNUSED",
            port_pllena = "PORT_UNUSED", port_scanaclr = "PORT_UNUSED",
            port_scanclk = "PORT_UNUSED", port_scanclkena = "PORT_UNUSED",
            port_scandata = "PORT_UNUSED", port_scandataout = "PORT_UNUSED",
            port_scandone = "PORT_UNUSED", port_scanread = "PORT_UNUSED",
            port_scanwrite = "PORT_UNUSED",
            port_clk0 = "PORT_USED", port_clk1 = "PORT_UNUSED", port_clk2 = "PORT_UNUSED",
            port_clk3 = "PORT_UNUSED", port_clk4 = "PORT_UNUSED", port_clk5 = "PORT_UNUSED",
            port_clkena0 = "PORT_UNUSED", port_clkena1 = "PORT_UNUSED",
            port_clkena2 = "PORT_UNUSED", port_clkena3 = "PORT_UNUSED",
            port_clkena4 = "PORT_UNUSED", port_clkena5 = "PORT_UNUSED",
            port_extclk0 = "PORT_UNUSED", port_extclk1 = "PORT_UNUSED",
            port_extclk2 = "PORT_UNUSED", port_extclk3 = "PORT_UNUSED";

  input  [1:0] inclk;
  input        fbin, pllena, clkswitch, areset, pfdena;
  input  [5:0] clkena;
  input  [3:0] extclkena;
  input        scanclk, scanaclr, scanclkena, scanread, scanwrite, scandata;
  input  [3:0] phasecounterselect;
  input        phaseupdown, phasestep, configupdate;
  inout        fbmimicbidir;
  output [width_clock-1:0] clk;
  output [3:0] extclk;
  output [1:0] clkbad;
  output       enable0, enable1, activeclock, clkloss, locked;
  output       scandataout, scandone, sclkout0, sclkout1, phasedone;
  output       vcooverrange, vcounderrange, fbout, fref, icdrclk;

  assign extclk = 4'b0;
  assign clkbad = 2'b0;
  assign {enable0, enable1, activeclock, clkloss} = 4'b0;
  assign {scandataout, scandone, sclkout0, sclkout1} = 4'b0;
  assign {phasedone, vcooverrange, vcounderrange, fbout, fref, icdrclk} = 6'b0;

  wire    rst = (areset === 1'b1);
  integer ncycles = 0;
  reg     lock_r = 1'b0;
  event   start_ev;
  assign  locked = lock_r;

  always @(posedge inclk[0] or posedge rst) begin
    if (rst) begin
      ncycles = 0;
      lock_r <= 1'b0;
    end else begin
      ncycles = ncycles + 1;
      if (ncycles == 4) -> start_ev;
      if (ncycles == 32) lock_r <= 1'b1;
    end
  end

  function integer pmul(input integer i);
    case (i) 0: pmul = clk0_multiply_by; 1: pmul = clk1_multiply_by; 2: pmul = clk2_multiply_by;
             3: pmul = clk3_multiply_by; default: pmul = clk4_multiply_by; endcase
  endfunction
  function integer pdiv(input integer i);
    case (i) 0: pdiv = clk0_divide_by; 1: pdiv = clk1_divide_by; 2: pdiv = clk2_divide_by;
             3: pdiv = clk3_divide_by; default: pdiv = clk4_divide_by; endcase
  endfunction
  function integer pduty(input integer i);
    case (i) 0: pduty = clk0_duty_cycle; 1: pduty = clk1_duty_cycle; 2: pduty = clk2_duty_cycle;
             3: pduty = clk3_duty_cycle; default: pduty = clk4_duty_cycle; endcase
  endfunction

  genvar g;
  generate
    for (g = 0; g < width_clock; g = g + 1) begin : outclk
      localparam integer M = pmul(g);
      localparam integer D = pdiv(g);
      localparam integer DUTY = pduty(g);
      localparam real    POUT = 1.0 * inclk0_input_frequency * D / M;
      localparam real    THIGH = POUT * DUTY / 100.0;
      reg     c = 1'b0;
      integer phase_ps = 0;
      real    ph;
      assign clk[g] = c;

      initial begin
        case (g)
          0: void'($sscanf(clk0_phase_shift, "%d", phase_ps));
          1: void'($sscanf(clk1_phase_shift, "%d", phase_ps));
          2: void'($sscanf(clk2_phase_shift, "%d", phase_ps));
          3: void'($sscanf(clk3_phase_shift, "%d", phase_ps));
          default: void'($sscanf(clk4_phase_shift, "%d", phase_ps));
        endcase
        ph = phase_ps;
        while (ph >= POUT) ph = ph - POUT;
        forever begin
          @(start_ev);
          #(ph);
          while (!rst) begin
            c = 1'b1;
            #(THIGH);
            c = 1'b0;
            #(POUT - THIGH);
          end
        end
      end
    end
  endgenerate
endmodule

//------------------------------------------------------------------------------
// altclkctrl: clock multiplexer
//------------------------------------------------------------------------------
module altclkctrl (clkselect, ena, inclk, outclk);
  parameter clock_type = "AUTO";
  parameter number_of_clocks = 4;
  parameter width_clkselect = 2;
  parameter intended_device_family = "Cyclone IV E";
  parameter ena_register_mode = "none";
  parameter implement_in_les = "OFF";
  parameter use_glitch_free_switch_over_implementation = "OFF";
  parameter lpm_type = "altclkctrl";
  parameter lpm_hint = "unused";
  input  [width_clkselect-1:0] clkselect;
  input                        ena;
  input  [number_of_clocks-1:0] inclk;
  output                       outclk;
  assign outclk = (ena !== 1'b0) ? inclk[clkselect] : 1'b0;
endmodule

//------------------------------------------------------------------------------
// altsyncram: ROM, SINGLE_PORT and DUAL_PORT modes
//------------------------------------------------------------------------------
module altsyncram (
  wren_a, wren_b, rden_a, rden_b, data_a, data_b, address_a, address_b,
  clock0, clock1, clocken0, clocken1, clocken2, clocken3, aclr0, aclr1,
  byteena_a, byteena_b, addressstall_a, addressstall_b, q_a, q_b, eccstatus
);
  parameter operation_mode = "BIDIR_DUAL_PORT";
  parameter width_a = 1, widthad_a = 1, numwords_a = 0;
  parameter width_b = 1, widthad_b = 1, numwords_b = 0;
  parameter width_byteena_a = 1, width_byteena_b = 1;
  parameter outdata_reg_a = "UNREGISTERED", outdata_reg_b = "UNREGISTERED";
  parameter address_reg_b = "CLOCK1";
  parameter address_aclr_a = "NONE", address_aclr_b = "NONE";
  parameter outdata_aclr_a = "NONE", outdata_aclr_b = "NONE";
  parameter clock_enable_input_a = "NORMAL", clock_enable_input_b = "NORMAL";
  parameter clock_enable_output_a = "NORMAL", clock_enable_output_b = "NORMAL";
  parameter read_during_write_mode_mixed_ports = "DONT_CARE";
  parameter read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ";
  parameter power_up_uninitialized = "FALSE";
  parameter init_file = "UNUSED";
  parameter init_file_layout = "PORT_A";
  parameter ram_block_type = "AUTO";
  parameter intended_device_family = "Cyclone IV E";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "altsyncram";

  localparam WORDS_A = (numwords_a > 0) ? numwords_a : (1 << widthad_a);

  input                  wren_a, wren_b, rden_a, rden_b;
  input  [width_a-1:0]   data_a;
  input  [width_b-1:0]   data_b;
  input  [widthad_a-1:0] address_a;
  input  [widthad_b-1:0] address_b;
  input                  clock0, clock1, clocken0, clocken1, clocken2, clocken3;
  input                  aclr0, aclr1;
  input  [width_byteena_a-1:0] byteena_a;
  input  [width_byteena_b-1:0] byteena_b;
  input                  addressstall_a, addressstall_b;
  output [width_a-1:0]   q_a;
  output [width_b-1:0]   q_b;
  output [2:0]           eccstatus;

  assign eccstatus = 3'b0;

  reg [width_a-1:0] mem [0:WORDS_A-1];

  // Resolve "<dir>/<name>.mif" to "<name>.hex" in the run directory
  function string hexname(input string f);
    integer k, st, en;
    st = 0;
    en = f.len();
    for (k = 0; k < f.len(); k = k + 1) begin
      if (f[k] == "/") st = k + 1;
      if (f[k] == ".") en = k;
    end
    hexname = {f.substr(st, en - 1), ".hex"};
  endfunction

  integer i, fd;
  string  hf;
  initial begin
    for (i = 0; i < WORDS_A; i = i + 1) mem[i] = {width_a{1'b0}};
    if (init_file != "UNUSED" && init_file != "") begin
      hf = hexname(init_file);
      fd = $fopen(hf, "r");
      if (fd == 0) begin
        $display("ERROR: altsyncram %m: init file %s (from %s) not found", hf, init_file);
      end else begin
        $fclose(fd);
        $readmemh(hf, mem);
      end
    end
  end

  wire clk_b = (address_reg_b == "CLOCK1") ? clock1 : clock0;
  wire clk_qb = (outdata_reg_b == "CLOCK1") ? clock1 : clock0;

  // Port A
  reg [width_a-1:0] ra = {width_a{1'b0}}, qa_r = {width_a{1'b0}};
  always @(posedge clock0) begin
    if (wren_a === 1'b1 && operation_mode != "ROM") mem[address_a] <= data_a;
    ra <= mem[address_a];
  end
  always @(posedge clock0) qa_r <= ra;
  assign q_a = (outdata_reg_a == "UNREGISTERED") ? ra : qa_r;

  // Port B (read port in DUAL_PORT mode)
  reg [width_b-1:0] rb = {width_b{1'b0}}, qb_r = {width_b{1'b0}};
  always @(posedge clk_b) rb <= mem[address_b];
  always @(posedge clk_qb) qb_r <= rb;
  assign q_b = (outdata_reg_b == "UNREGISTERED") ? rb : qb_r;
endmodule

//------------------------------------------------------------------------------
// dcfifo / dcfifo_mixed_widths
// Pointers count write-side words. Each side sees the other pointer through a
// two stage synchronizer. Narrow write / wide read: the first written word
// appears in the least significant bits of q.
//------------------------------------------------------------------------------
module dcfifo_mixed_widths (
  data, rdclk, wrclk, aclr, rdreq, wrreq, rdfull, wrfull, rdempty, wrempty,
  rdusedw, wrusedw, q, eccstatus
);
  parameter lpm_width = 8;
  parameter lpm_width_r = lpm_width;
  parameter lpm_widthu = 8;
  parameter lpm_widthu_r = lpm_widthu;
  parameter lpm_numwords = 256;
  parameter lpm_showahead = "OFF";
  parameter add_usedw_msb_bit = "OFF";
  parameter overflow_checking = "ON";
  parameter underflow_checking = "ON";
  parameter rdsync_delaypipe = 3;
  parameter wrsync_delaypipe = 3;
  parameter read_aclr_synch = "OFF";
  parameter write_aclr_synch = "OFF";
  parameter wrsync_aclr_synch = "OFF";
  parameter use_eab = "ON";
  parameter intended_device_family = "Cyclone IV E";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "dcfifo_mixed_widths";

  localparam R = lpm_width_r / lpm_width;   // write words per read word
  localparam PW = 32;

  input  [lpm_width-1:0]    data;
  input                     rdclk, wrclk, aclr, rdreq, wrreq;
  output                    rdfull, wrfull, rdempty, wrempty;
  output [lpm_widthu_r-1:0] rdusedw;
  output [lpm_widthu-1:0]   wrusedw;
  output [lpm_width_r-1:0]  q;
  output [3:0]              eccstatus;

  assign eccstatus = 4'b0;

  initial begin
    if (lpm_width_r % lpm_width != 0 || lpm_width_r < lpm_width)
      $display("ERROR: dcfifo model %m only supports narrow write / wide read (%0d/%0d)",
               lpm_width, lpm_width_r);
  end

  reg [lpm_width-1:0] mem [0:lpm_numwords-1];
  reg [PW-1:0] wptr = 0, rptr = 0;
  reg [PW-1:0] wptr_rs1 = 0, wptr_rs2 = 0;     // wptr seen by read side
  reg [PW-1:0] rptr_ws1 = 0, rptr_ws2 = 0;     // rptr seen by write side
  wire clr = (aclr === 1'b1);

  wire [PW-1:0] wr_level = wptr - rptr_ws2;
  wire [PW-1:0] rd_level = wptr_rs2 - rptr;
  wire          full_w   = (wr_level >= lpm_numwords);
  wire          empty_r  = (rd_level < R);

  assign wrfull  = full_w;
  assign wrempty = (wr_level == 0);
  assign wrusedw = wr_level[lpm_widthu-1:0];
  assign rdempty = empty_r;
  assign rdfull  = (rd_level >= lpm_numwords);
  assign rdusedw = (rd_level / R);

  always @(posedge wrclk or posedge clr) begin
    if (clr) begin
      wptr <= 0;
      rptr_ws1 <= 0;
      rptr_ws2 <= 0;
    end else begin
      rptr_ws1 <= rptr;
      rptr_ws2 <= rptr_ws1;
      if (wrreq === 1'b1 && !(full_w && overflow_checking == "ON")) begin
        mem[wptr % lpm_numwords] <= data;
        wptr <= wptr + 1;
      end
    end
  end

  function [lpm_width_r-1:0] word_at(input [PW-1:0] p);
    integer k;
    for (k = 0; k < R; k = k + 1)
      word_at[k*lpm_width +: lpm_width] = mem[(p + k) % lpm_numwords];
  endfunction

  reg [lpm_width_r-1:0] q_r = 0;
  always @(posedge rdclk or posedge clr) begin
    if (clr) begin
      rptr <= 0;
      wptr_rs1 <= 0;
      wptr_rs2 <= 0;
    end else begin
      wptr_rs1 <= wptr;
      wptr_rs2 <= wptr_rs1;
      if (rdreq === 1'b1 && !(empty_r && underflow_checking == "ON")) begin
        if (lpm_showahead != "ON") q_r <= word_at(rptr);
        rptr <= rptr + R;
      end
    end
  end

  assign q = (lpm_showahead == "ON") ? word_at(rptr) : q_r;
endmodule

module dcfifo (
  data, rdclk, wrclk, aclr, rdreq, wrreq, rdfull, wrfull, rdempty, wrempty,
  rdusedw, wrusedw, q, eccstatus
);
  parameter lpm_width = 8;
  parameter lpm_widthu = 8;
  parameter lpm_numwords = 256;
  parameter lpm_showahead = "OFF";
  parameter add_usedw_msb_bit = "OFF";
  parameter overflow_checking = "ON";
  parameter underflow_checking = "ON";
  parameter rdsync_delaypipe = 3;
  parameter wrsync_delaypipe = 3;
  parameter read_aclr_synch = "OFF";
  parameter write_aclr_synch = "OFF";
  parameter wrsync_aclr_synch = "OFF";
  parameter use_eab = "ON";
  parameter intended_device_family = "Cyclone IV E";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "dcfifo";

  input  [lpm_width-1:0]  data;
  input                   rdclk, wrclk, aclr, rdreq, wrreq;
  output                  rdfull, wrfull, rdempty, wrempty;
  output [lpm_widthu-1:0] rdusedw, wrusedw;
  output [lpm_width-1:0]  q;
  output [3:0]            eccstatus;

  dcfifo_mixed_widths #(
    .lpm_width(lpm_width), .lpm_width_r(lpm_width),
    .lpm_widthu(lpm_widthu), .lpm_widthu_r(lpm_widthu),
    .lpm_numwords(lpm_numwords), .lpm_showahead(lpm_showahead),
    .overflow_checking(overflow_checking), .underflow_checking(underflow_checking)
  ) fifo (
    .data(data), .rdclk(rdclk), .wrclk(wrclk), .aclr(aclr), .rdreq(rdreq), .wrreq(wrreq),
    .rdfull(rdfull), .wrfull(wrfull), .rdempty(rdempty), .wrempty(wrempty),
    .rdusedw(rdusedw), .wrusedw(wrusedw), .q(q), .eccstatus(eccstatus)
  );
endmodule

//------------------------------------------------------------------------------
// scfifo
//------------------------------------------------------------------------------
module scfifo (
  data, clock, wrreq, rdreq, aclr, sclr, q, usedw, full, empty, almost_full,
  almost_empty, eccstatus
);
  parameter lpm_width = 8;
  parameter lpm_widthu = 8;
  parameter lpm_numwords = 256;
  parameter lpm_showahead = "OFF";
  parameter overflow_checking = "ON";
  parameter underflow_checking = "ON";
  parameter almost_full_value = 0;
  parameter almost_empty_value = 0;
  parameter use_eab = "ON";
  parameter add_ram_output_register = "OFF";
  parameter intended_device_family = "Cyclone IV E";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "scfifo";

  input  [lpm_width-1:0]  data;
  input                   clock, wrreq, rdreq, aclr, sclr;
  output [lpm_width-1:0]  q;
  output [lpm_widthu-1:0] usedw;
  output                  full, empty, almost_full, almost_empty;
  output [3:0]            eccstatus;

  assign eccstatus = 4'b0;

  reg [lpm_width-1:0] mem [0:lpm_numwords-1];
  integer wp = 0, rp = 0, cnt = 0;
  reg [lpm_width-1:0] q_r = 0;
  wire do_wr = (wrreq === 1'b1) && !(cnt >= lpm_numwords && overflow_checking == "ON");
  wire do_rd = (rdreq === 1'b1) && !(cnt == 0 && underflow_checking == "ON");

  always @(posedge clock or posedge aclr) begin
    if (aclr === 1'b1) begin
      wp = 0; rp = 0; cnt = 0;
    end else if (sclr === 1'b1) begin
      wp = 0; rp = 0; cnt = 0;
    end else begin
      if (do_rd) begin
        if (lpm_showahead != "ON") q_r <= mem[rp];
        rp = (rp + 1) % lpm_numwords;
      end
      if (do_wr) begin
        mem[wp] <= data;
        wp = (wp + 1) % lpm_numwords;
      end
      cnt = cnt + (do_wr ? 1 : 0) - (do_rd ? 1 : 0);
    end
  end

  assign q            = (lpm_showahead == "ON") ? mem[rp] : q_r;
  assign usedw        = cnt;
  assign full         = (cnt >= lpm_numwords);
  assign empty        = (cnt == 0);
  assign almost_full  = (cnt >= almost_full_value);
  assign almost_empty = (cnt < almost_empty_value);
endmodule

//------------------------------------------------------------------------------
// lpm_mult: when lpm_widthp < widtha+widthb the MSBs of the product are kept
//------------------------------------------------------------------------------
module lpm_mult (dataa, datab, sum, aclr, sclr, clock, clken, result);
  parameter lpm_widtha = 1;
  parameter lpm_widthb = 1;
  parameter lpm_widthp = 2;
  parameter lpm_widths = 1;
  parameter lpm_representation = "UNSIGNED";
  parameter lpm_pipeline = 0;
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "LPM_MULT";

  localparam FW = lpm_widtha + lpm_widthb;

  input  [lpm_widtha-1:0] dataa;
  input  [lpm_widthb-1:0] datab;
  input  [lpm_widths-1:0] sum;
  input                   aclr, sclr, clock, clken;
  output [lpm_widthp-1:0] result;

  wire signed [FW:0] pa = {{(lpm_widthb+1){(lpm_representation == "SIGNED") & dataa[lpm_widtha-1]}}, dataa};
  wire signed [FW:0] pb = {{(lpm_widtha+1){(lpm_representation == "SIGNED") & datab[lpm_widthb-1]}}, datab};
  wire signed [FW:0] pfull = pa * pb;
  wire [lpm_widthp-1:0] p;

  generate
    if (lpm_widthp <= FW) begin : trunc
      assign p = pfull[FW-1 -: lpm_widthp];
    end else begin : ext
      assign p = {{(lpm_widthp-FW){pfull[FW-1]}}, pfull[FW-1:0]};
    end
  endgenerate

  generate
    if (lpm_pipeline == 0) begin : comb
      assign result = p;
    end else begin : piped
      reg [lpm_widthp-1:0] pipe [0:lpm_pipeline-1];
      integer k;
      initial for (k = 0; k < lpm_pipeline; k = k + 1) pipe[k] = 0;
      always @(posedge clock or posedge aclr) begin
        if (aclr === 1'b1) begin
          for (k = 0; k < lpm_pipeline; k = k + 1) pipe[k] <= 0;
        end else if (clken !== 1'b0) begin
          pipe[0] <= p;
          for (k = 1; k < lpm_pipeline; k = k + 1) pipe[k] <= pipe[k-1];
        end
      end
      assign result = pipe[lpm_pipeline-1];
    end
  endgenerate
endmodule

//------------------------------------------------------------------------------
// lpm_compare (combinational, unsigned)
//------------------------------------------------------------------------------
module lpm_compare (dataa, datab, clock, aclr, clken, alb, aeb, agb, aleb, aneb, ageb);
  parameter lpm_width = 1;
  parameter lpm_representation = "UNSIGNED";
  parameter lpm_pipeline = 0;
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "lpm_compare";
  input  [lpm_width-1:0] dataa, datab;
  input  clock, aclr, clken;
  output alb, aeb, agb, aleb, aneb, ageb;
  assign alb  = dataa <  datab;
  assign aeb  = dataa == datab;
  assign agb  = dataa >  datab;
  assign aleb = dataa <= datab;
  assign aneb = dataa != datab;
  assign ageb = dataa >= datab;
endmodule

//------------------------------------------------------------------------------
// lpm_counter
//------------------------------------------------------------------------------
module lpm_counter (clock, clk_en, cnt_en, updown, cin, aclr, aset, aload, sclr,
                    sset, sload, data, q, cout, eq);
  parameter lpm_width = 1;
  parameter lpm_direction = "UNUSED";
  parameter lpm_modulus = 0;
  parameter lpm_avalue = "UNUSED";
  parameter lpm_svalue = "UNUSED";
  parameter lpm_port_updown = "PORT_CONNECTIVITY";
  parameter lpm_pvalue = "UNUSED";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "LPM_COUNTER";

  localparam [lpm_width:0] MAXV = (lpm_modulus > 0) ? lpm_modulus - 1 : {lpm_width{1'b1}};

  input                  clock, clk_en, cnt_en, updown, cin, aclr, aset, aload;
  input                  sclr, sset, sload;
  input  [lpm_width-1:0] data;
  output [lpm_width-1:0] q;
  output                 cout;
  output [15:0]          eq;

  reg [lpm_width-1:0] cnt = 0;
  wire up = (lpm_direction == "UP") ? 1'b1 :
            (lpm_direction == "DOWN") ? 1'b0 : (updown !== 1'b0);

  always @(posedge clock or posedge aclr or posedge aset or posedge aload) begin
    if (aclr === 1'b1)       cnt <= 0;
    else if (aset === 1'b1)  cnt <= {lpm_width{1'b1}};
    else if (aload === 1'b1) cnt <= data;
    else if (clk_en !== 1'b0) begin
      if (sclr === 1'b1)       cnt <= 0;
      else if (sset === 1'b1)  cnt <= {lpm_width{1'b1}};
      else if (sload === 1'b1) cnt <= data;
      else if (cnt_en !== 1'b0 && cin !== 1'b0) begin
        if (up) cnt <= (cnt == MAXV) ? 0 : cnt + 1'b1;
        else    cnt <= (cnt == 0) ? MAXV[lpm_width-1:0] : cnt - 1'b1;
      end
    end
  end

  assign q    = cnt;
  assign cout = (cin !== 1'b0) & (up ? (cnt == MAXV) : (cnt == 0));
  assign eq   = 16'b0;
endmodule

//------------------------------------------------------------------------------
// a_graycounter: q is the Gray code of the binary count qbin
//------------------------------------------------------------------------------
module a_graycounter (clock, clk_en, cnt_en, updown, aclr, sclr, q, qbin);
  parameter width = 2;
  parameter pvalue = 0;
  parameter lpm_type = "a_graycounter";
  input              clock, clk_en, cnt_en, updown, aclr, sclr;
  output [width-1:0] q, qbin;
  reg [width-1:0] b = pvalue;
  always @(posedge clock or posedge aclr) begin
    if (aclr === 1'b1) b <= pvalue;
    else if (clk_en !== 1'b0) begin
      if (sclr === 1'b1) b <= pvalue;
      else if (cnt_en !== 1'b0) b <= (updown === 1'b0) ? b - 1'b1 : b + 1'b1;
    end
  end
  assign qbin = b;
  assign q    = b ^ (b >> 1);
endmodule

//------------------------------------------------------------------------------
// altshift_taps
//------------------------------------------------------------------------------
module altshift_taps (shiftin, clock, clken, aclr, shiftout, taps);
  parameter width = 1;
  parameter number_of_taps = 1;
  parameter tap_distance = 1;
  parameter power_up_state = "CLEARED";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "altshift_taps";
  localparam N = number_of_taps * tap_distance;
  input  [width-1:0] shiftin;
  input              clock, clken, aclr;
  output [width-1:0] shiftout;
  output [width*number_of_taps-1:0] taps;
  reg [width-1:0] sr [0:N-1];
  integer k;
  initial for (k = 0; k < N; k = k + 1) sr[k] = 0;
  always @(posedge clock) begin
    if (clken !== 1'b0) begin
      for (k = N - 1; k > 0; k = k - 1) sr[k] <= sr[k-1];
      sr[0] <= shiftin;
    end
  end
  genvar g;
  generate
    for (g = 0; g < number_of_taps; g = g + 1) begin : tap
      assign taps[g*width +: width] = sr[(g+1)*tap_distance - 1];
    end
  endgenerate
  assign shiftout = sr[N-1];
endmodule

//------------------------------------------------------------------------------
// altddio_in: dataout_h is sampled on the rising edge, dataout_l on the
// preceding falling edge; both change on the rising edge. invert_input_clocks
// swaps the edges.
//------------------------------------------------------------------------------
module altddio_in (datain, inclock, inclocken, aset, aclr, sset, sclr, dataout_h, dataout_l);
  parameter width = 1;
  parameter invert_input_clocks = "OFF";
  parameter power_up_high = "OFF";
  parameter intended_device_family = "Cyclone IV E";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "altddio_in";
  input  [width-1:0] datain;
  input              inclock, inclocken, aset, aclr, sset, sclr;
  output reg [width-1:0] dataout_h = 0;
  output reg [width-1:0] dataout_l = 0;
  wire clk = (invert_input_clocks == "ON") ? ~inclock : inclock;
  reg [width-1:0] l_neg = 0;
  always @(negedge clk) l_neg <= datain;
  always @(posedge clk) begin
    dataout_h <= datain;
    dataout_l <= l_neg;
  end
endmodule

//------------------------------------------------------------------------------
// altddio_out: datain_h is driven while outclock is high, datain_l while low
//------------------------------------------------------------------------------
module altddio_out (datain_h, datain_l, outclock, outclocken, aset, aclr, sset, sclr,
                    oe, dataout, oe_out);
  parameter width = 1;
  parameter power_up_high = "OFF";
  parameter oe_reg = "UNREGISTERED";
  parameter extend_oe_disable = "OFF";
  parameter invert_output = "OFF";
  parameter intended_device_family = "Cyclone IV E";
  parameter lpm_hint = "UNUSED";
  parameter lpm_type = "altddio_out";
  input  [width-1:0] datain_h, datain_l;
  input              outclock, outclocken, aset, aclr, sset, sclr, oe;
  output [width-1:0] dataout;
  output [width-1:0] oe_out;
  reg [width-1:0] h = 0, l0 = 0, l = 0;
  always @(posedge outclock) begin
    h  <= datain_h;
    l0 <= datain_l;
  end
  always @(negedge outclock) l <= l0;
  assign dataout = outclock ? h : l;
  assign oe_out  = {width{1'b1}};
endmodule

//------------------------------------------------------------------------------
// Cyclone IV hard blocks. The active serial (EPCS flash) interface and the
// remote update block are only stubs: the flash reads back what the testbench
// puts on asmi_miso and the remote update shift register reads as zero.
//------------------------------------------------------------------------------
module cycloneive_asmiblock (dclkin, scein, sdoin, oe, data0out);
  input  dclkin, scein, sdoin, oe;
  output data0out;
  reg    miso = 1'b0;         // driven by a flash model through hierarchical access
  assign data0out = miso;
endmodule

module cycloneive_rublock (clk, shiftnld, captnupdt, regin, rsttimer, rconfig, regout);
  input  clk, shiftnld, captnupdt, regin, rsttimer, rconfig;
  output regout;
  reg    reconfig_seen = 1'b0;
  always @(posedge rconfig) begin
    reconfig_seen <= 1'b1;
    $display("%t: cycloneive_rublock %m: reconfiguration requested", $realtime);
  end
  assign regout = 1'b0;
endmodule

//------------------------------------------------------------------------------
// altsquare: result = data * data
//------------------------------------------------------------------------------
module altsquare (data, clock, ena, aclr, sclr, result);
  parameter data_width = 1;
  parameter result_width = 2;
  parameter pipeline = 0;
  parameter representation = "UNSIGNED";
  parameter lpm_type = "ALTSQUARE";
  input  [data_width-1:0]   data;
  input                     clock, ena, aclr, sclr;
  output [result_width-1:0] result;
  wire signed [2*data_width:0] d = (representation == "SIGNED") ?
      {{(data_width+1){data[data_width-1]}}, data} : {{(data_width+1){1'b0}}, data};
  wire signed [2*data_width:0] p = d * d;
  wire [result_width-1:0] r = p[result_width-1:0];
  generate
    if (pipeline == 0) begin : comb
      assign result = r;
    end else begin : piped
      reg [result_width-1:0] pipe [0:pipeline-1];
      integer k;
      always @(posedge clock) if (ena !== 1'b0) begin
        pipe[0] <= r;
        for (k = 1; k < pipeline; k = k + 1) pipe[k] <= pipe[k-1];
      end
      assign result = pipe[pipeline-1];
    end
  endgenerate
endmodule

//------------------------------------------------------------------------------
// altsqrt: integer square root with remainder, 'pipeline' clocks of latency
//------------------------------------------------------------------------------
module altsqrt (radical, clk, ena, aclr, q, remainder);
  parameter width = 1;
  parameter q_port_width = 1;
  parameter r_port_width = 1;
  parameter pipeline = 0;
  parameter lpm_type = "ALTSQRT";
  parameter lpm_hint = "UNUSED";
  input  [width-1:0]        radical;
  input                     clk, ena, aclr;
  output [q_port_width-1:0] q;
  output [r_port_width-1:0] remainder;

  function [q_port_width+r_port_width-1:0] isqrt(input [width-1:0] x);
    reg [width-1:0] rem, root, bit_;
    integer k;
    begin
      rem = x;
      root = 0;
      bit_ = {{(width-2){1'b0}}, 2'b01} << (((width + 1) / 2 - 1) * 2);
      for (k = 0; k < (width + 1) / 2; k = k + 1) begin
        if (rem >= root + bit_) begin
          rem = rem - (root + bit_);
          root = (root >> 1) + bit_;
        end else begin
          root = root >> 1;
        end
        bit_ = bit_ >> 2;
      end
      isqrt = {root[q_port_width-1:0], rem[r_port_width-1:0]};
    end
  endfunction

  wire [q_port_width+r_port_width-1:0] res = isqrt(radical);
  generate
    if (pipeline == 0) begin : comb
      assign {q, remainder} = res;
    end else begin : piped
      reg [q_port_width+r_port_width-1:0] pipe [0:pipeline-1];
      integer k;
      always @(posedge clk) if (ena !== 1'b0) begin
        pipe[0] <= res;
        for (k = 1; k < pipeline; k = k + 1) pipe[k] <= pipe[k-1];
      end
      assign {q, remainder} = pipe[pipeline-1];
    end
  endgenerate
endmodule
