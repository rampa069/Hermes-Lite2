
module lfsr (
  input  wire        clk,
  input  wire        rst,
  output wire [7:0]  dither
);

  localparam INITIAL = 23'd1;
  reg [22:0] lfsr_reg;

  assign dither = lfsr_reg[7:0];

  always @(posedge clk) begin
    if (rst)
      lfsr_reg <= INITIAL;
    else begin
      lfsr_reg[21] <= lfsr_reg[21] ^ lfsr_reg[0];
      lfsr_reg[20:0] <= lfsr_reg[21:1];
    end
  end

endmodule
