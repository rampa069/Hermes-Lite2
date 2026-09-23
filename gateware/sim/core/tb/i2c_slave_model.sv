// I2C slave model (open drain) for the HL2 testbench.
//
// KIND:
//   "REG8"     register pointer + 8 bit registers with auto increment
//              (Versa 5P49V5923, MCP23008 filter board, generic devices)
//   "MCP4662"  digital pot / EEPROM: command byte {addr[3:0], cmd[1:0], d9, d8},
//              cmd 00 write, 11 read; a read returns {7'b0, d8}, d[7:0], repeated
//   "MAX11613" 4 channel 12 bit ADC; setup/config writes are logged, a read
//              returns {4'hf, ch[11:8]}, ch[7:0] for channels 0..3

`timescale 1ps/1fs

module i2c_slave_model #(
  parameter logic [6:0] ADDR = 7'h50,
  parameter string      KIND = "REG8"
) (
  inout wire scl,
  inout wire sda
);

import hl2_pkg::*;

logic       sda_low = 1'b0;
assign sda = sda_low ? 1'b0 : 1'bz;

wire scl_in = (scl !== 1'b0);
wire sda_in = (sda !== 1'b0);

// Device state
logic [7:0]  mem [0:255];
logic [8:0]  mem9 [0:15];         // MCP4662 registers (9 bit)
logic [11:0] adc [0:3];
logic [7:0]  ptr = 8'h00;
logic [3:0]  mcp_addr = 4'h0;
logic [1:0]  mcp_cmd = 2'b00;
logic        mcp_hi = 1'b1;
int          adc_idx = 0;

// Logs for the tests
bytes_t      cur_write;
bytes_t      writes[$];           // one entry per write transaction (data bytes only)
int unsigned reads = 0;
int unsigned nacked_addr = 0;

initial begin
  foreach (mem[i]) mem[i] = 8'h00;
  foreach (mem9[i]) mem9[i] = 9'h000;
  foreach (adc[i]) adc[i] = 12'h000;
end

typedef enum { S_IDLE, S_ADDR, S_WDATA, S_RDATA, S_IGNORE } st_t;
st_t  st = S_IDLE;
logic [7:0] sh = 8'h00;
logic [7:0] txb = 8'h00;
int   cnt = 0;
bit   ack_phase = 0;
bit   rw = 0;
bit   master_nack = 0;
int   widx = 0;

function automatic logic [7:0] next_read_byte();
  logic [7:0] b;
  if (KIND == "MCP4662") begin
    b = mcp_hi ? {7'b0, mem9[mcp_addr][8]} : mem9[mcp_addr][7:0];
    mcp_hi = ~mcp_hi;
  end else if (KIND == "MAX11613") begin
    b = adc_idx[0] ? adc[adc_idx/2][7:0] : {4'hf, adc[adc_idx/2][11:8]};
    adc_idx = (adc_idx + 1) % 8;
  end else begin
    b = mem[ptr];
    ptr = ptr + 8'h01;
  end
  return b;
endfunction

function automatic void got_write_byte(input logic [7:0] b);
  cur_write.push_back(b);
  if (KIND == "MCP4662") begin
    if (widx == 0) begin
      mcp_addr = b[7:4];
      mcp_cmd  = b[3:2];
      mcp_hi   = 1'b1;
      if (mcp_cmd == 2'b00) mem9[mcp_addr][8] = b[0];
    end else if (widx == 1 && mcp_cmd == 2'b00) begin
      mem9[mcp_addr][7:0] = b;
    end
  end else if (KIND == "MAX11613") begin
    adc_idx = 0;
  end else begin
    if (widx == 0) ptr = b;
    else begin
      mem[ptr] = b;
      ptr = ptr + 8'h01;
    end
  end
  widx++;
endfunction

function automatic void end_transaction();
  if (st == S_WDATA || (st == S_ADDR && cur_write.size() != 0)) begin
    if (cur_write.size() != 0) writes.push_back(cur_write);
  end
  cur_write.delete();
endfunction

// START / repeated START: SDA falls while SCL is high
always @(negedge sda_in) begin
  if (scl_in) begin
    end_transaction();
    st = S_ADDR;
    cnt = 0;
    ack_phase = 0;
    sda_low = 1'b0;
  end
end

// STOP: SDA rises while SCL is high
always @(posedge sda_in) begin
  if (scl_in && !sda_low) begin
    end_transaction();
    st = S_IDLE;
    sda_low = 1'b0;
  end
end

always @(posedge scl_in) begin
  case (st)
    S_ADDR, S_WDATA: if (!ack_phase) begin sh = {sh[6:0], sda_in}; cnt++; end
    S_RDATA:         if (ack_phase) master_nack = sda_in;
    default: ;
  endcase
end

always @(negedge scl_in) begin
  case (st)
    S_ADDR: begin
      if (ack_phase) begin
        ack_phase = 0;
        sda_low = 1'b0;
        widx = 0;
        if (rw) begin
          reads++;
          txb = next_read_byte();
          sda_low = ~txb[7];
          cnt = 1;
          st = S_RDATA;
        end else begin
          cnt = 0;
          st = S_WDATA;
        end
      end else if (cnt == 8) begin
        if (sh[7:1] == ADDR) begin
          rw = sh[0];
          ack_phase = 1;
          sda_low = 1'b1;
        end else begin
          nacked_addr++;
          st = S_IGNORE;
        end
      end
    end
    S_WDATA: begin
      if (ack_phase) begin
        ack_phase = 0;
        sda_low = 1'b0;
        cnt = 0;
      end else if (cnt == 8) begin
        got_write_byte(sh);
        ack_phase = 1;
        sda_low = 1'b1;
      end
    end
    S_RDATA: begin
      if (ack_phase) begin
        ack_phase = 0;
        if (master_nack) begin
          sda_low = 1'b0;
          st = S_IGNORE;
        end else begin
          txb = next_read_byte();
          sda_low = ~txb[7];
          cnt = 1;
        end
      end else if (cnt == 8) begin
        sda_low = 1'b0;             // release for the master ACK
        ack_phase = 1;
      end else begin
        sda_low = ~txb[7 - cnt];
        cnt++;
      end
    end
    default: ;
  endcase
end

endmodule
