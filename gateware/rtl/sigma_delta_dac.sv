`timescale 1 ns/100 ps

// First order sigma-delta DAC with a 1 bit output.
// data_in is signed two's complement; it is converted to offset binary so that
// 0 gives a 50% pulse density (mid rail after the RC filter). The output is
// the carry of the 16 bit phase accumulator.
module sigma_delta_dac (
  input                clk,
  input         [15:0] data_in,
  input                enable,
  output reg           dac_out
);

  reg [16:0] accumulator = 17'b0;

  always @(posedge clk) begin
    if (enable) begin
      accumulator <= {1'b0, accumulator[15:0]} + {1'b0, ~data_in[15], data_in[14:0]};
      dac_out <= accumulator[16];
    end else begin
      accumulator <= 17'b0;
      dac_out <= 1'b0;
    end
  end

endmodule
