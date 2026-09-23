// Behavioral simulation models for the Altera IP used by rtl/localaudio/cw_sidetone.v
// (sin1k9r = altsyncram ROM, mult_s9_s8_s16 / mult_s16_s8_s16 = lpm_mult).
// Only for Icarus Verilog; Quartus uses the real .qip cores.

`timescale 1 ns/100 ps

// 1024 x 9 bit signed sine ROM, registered output (outdata_reg_a = "CLOCK0").
// Contents come from sin1k9r.mif, converted to hex by the Makefile.
module sin1k9r (
  input        [9:0] address,
  input              clock,
  output reg   [8:0] q
);
  reg [8:0] rom [0:1023];
  initial $readmemh("sin1k9r.hex", rom);
  always @(posedge clock) q <= rom[address];
endmodule

// lpm_mult SIGNED, LPM_PIPELINE=1. When LPM_WIDTHP < WIDTHA+WIDTHB the core keeps
// the WIDTHP most significant bits of the full product.
module mult_s9_s8_s16 (
  input               clock,
  input  signed [8:0] dataa,
  input  signed [7:0] datab,
  output reg    [15:0] result
);
  wire signed [16:0] p = dataa * datab;
  always @(posedge clock) result <= p[16:1];
endmodule

module mult_s16_s8_s16 (
  input               clock,
  input  signed [15:0] dataa,
  input  signed [7:0]  datab,
  output reg    [15:0] result
);
  wire signed [23:0] p = dataa * datab;
  always @(posedge clock) result <= p[23:8];
endmodule
