
module tx_watchdog #(
  parameter TIMEOUT = 153600000
)(
  input  wire clk,
  input  wire rst,
  input  wire activity,
  output reg  tx_enable
);

  reg [31:0] counter;

  always @(posedge clk) begin
    if (rst) begin
      counter   <= 32'd0;
      tx_enable <= 1'b0;
    end else begin
      if (activity) begin
        counter   <= TIMEOUT[31:0];
        tx_enable <= 1'b1;
      end else if (counter != 32'd0) begin
        counter   <= counter - 32'd1;
        tx_enable <= 1'b1;
      end else begin
        tx_enable <= 1'b0;
      end
    end
  end

endmodule
