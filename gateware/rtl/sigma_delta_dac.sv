`timescale 1 ns/100 ps

module sigma_delta_dac (
  input                clk,
  input         [15:0] data_in,
  input                enable,
  output reg           dac_out
);

  reg [16:0] accumulator = 17'b0;

  always @(posedge clk) begin
    if (enable) begin
      accumulator <= accumulator[16] ? ({1'b0, data_in} - accumulator[16:0])
                                     : ({1'b0, data_in} + accumulator[16:0]);
      dac_out <= ~accumulator[16];
    end else begin
      accumulator <= 17'b0;
      dac_out <= 1'b0;
    end
  end

endmodule
