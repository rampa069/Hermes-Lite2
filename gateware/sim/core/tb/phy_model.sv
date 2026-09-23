// Ethernet PHY model for the HL2 testbench: KSZ9031 at 1000BASE-T full duplex.
//
// - RGMII receive side (PHY -> FPGA): send_frame() queues a frame; preamble,
//   SFD and FCS are added here. RXD/RX_CTL change 2 ns after each RXC edge, so
//   they are stable around the sampling edges (the real PHY centers RXC).
// - RGMII transmit side (FPGA -> PHY): frames are captured on TXC edges, the
//   preamble is stripped, the FCS is checked and the frame is put in rx_frames.
// - MDIO (clause 22) slave at PHYAD 7 with a small register file.

`timescale 1ps/1fs

module phy_model #(
  parameter int PHYAD = 7
) (
  output logic       rx_clk,
  output logic [3:0] rxd,
  output logic       rx_ctl,
  input  logic       tx_clk,
  input  logic [3:0] txd,
  input  logic       tx_ctl,
  inout  wire        mdio,
  input  logic       mdc
);

import hl2_pkg::*;

//------------------------------------------------------------------------------
// CRC32 (IEEE 802.3)
function automatic logic [31:0] crc32(input bytes_t d);
  logic [31:0] c = 32'hffffffff;
  foreach (d[i]) begin
    c = c ^ {24'h0, d[i]};
    for (int k = 0; k < 8; k++) c = c[0] ? (c >> 1) ^ 32'hedb88320 : (c >> 1);
  end
  return ~c;
endfunction

//------------------------------------------------------------------------------
// RGMII receive path (to the FPGA)
typedef struct packed { logic ctl; logic [7:0] data; } rgmii_byte_t;
rgmii_byte_t txq[$];
int unsigned frames_sent = 0;
logic link_up = 1'b1;

task automatic send_frame(input bytes_t frame);
  bytes_t f;
  logic [31:0] fcs;
  f = frame;
  while (f.size() < 60) f.push_back(8'h00);          // pad to minimum size
  fcs = crc32(f);
  for (int i = 0; i < 7; i++) txq.push_back('{1'b1, 8'h55});
  txq.push_back('{1'b1, 8'hd5});
  foreach (f[i]) txq.push_back('{1'b1, f[i]});
  for (int i = 0; i < 4; i++) txq.push_back('{1'b1, fcs[8*i +: 8]});
  for (int i = 0; i < 12; i++) txq.push_back('{1'b0, 8'h00});   // IFG
  frames_sent++;
endtask

function automatic bit tx_idle();
  return txq.size() == 0;
endfunction

initial begin
  rgmii_byte_t b;
  rx_clk = 1'b0;
  rxd    = 4'h0;
  rx_ctl = 1'b0;
  #1234;
  forever begin
    b = (txq.size() != 0) ? txq.pop_front() : '{1'b0, 8'h00};
    #2000 rxd = b.data[3:0]; rx_ctl = b.ctl;       // for the rising edge
    #2000 rx_clk = 1'b1;
    #2000 rxd = b.data[7:4]; rx_ctl = b.ctl;       // for the falling edge (DV ^ ER)
    #2000 rx_clk = 1'b0;
  end
end

//------------------------------------------------------------------------------
// RGMII transmit path (from the FPGA)
bytes_t rx_frames[$];
int unsigned frames_received = 0;
int unsigned fcs_errors = 0;
bytes_t cur;
logic [3:0] lo_nib;
logic       lo_ctl;
logic       in_frame = 1'b0;

always @(posedge tx_clk) begin
  lo_nib <= txd;
  lo_ctl <= tx_ctl;
end

always @(negedge tx_clk) begin
  if (lo_ctl) begin
    cur.push_back({txd, lo_nib});
    in_frame <= 1'b1;
  end else if (in_frame) begin
    in_frame <= 1'b0;
    finish_frame();
  end
end

task automatic finish_frame();
  int sfd = -1;
  bytes_t f;
  logic [31:0] fcs, got;
  for (int i = 0; i < cur.size() && i < 9; i++) begin
    if (cur[i] == 8'hd5) begin sfd = i; break; end
    if (cur[i] != 8'h55) break;
  end
  if (sfd < 1 || cur.size() < sfd + 1 + 64) begin
    $display("%t PHY: malformed frame from FPGA (%0d bytes, sfd at %0d)", $realtime, cur.size(), sfd);
    fcs_errors++;
  end else begin
    for (int i = sfd + 1; i < cur.size() - 4; i++) f.push_back(cur[i]);
    fcs = crc32(f);
    got = {cur[cur.size()-1], cur[cur.size()-2], cur[cur.size()-3], cur[cur.size()-4]};
    if (fcs != got) begin
      $display("%t PHY: FCS error in frame from FPGA: got %h expected %h", $realtime, got, fcs);
      fcs_errors++;
    end else begin
      rx_frames.push_back(f);
      frames_received++;
    end
  end
  cur.delete();
endtask

//------------------------------------------------------------------------------
// MDIO slave
logic [15:0] regs [0:31];
logic [15:0] mdio_writes[$];      // {regad, data} log: regad in [20:16] of the entry
logic [4:0]  mdio_write_addr[$];
logic        mdio_oe = 1'b0, mdio_out = 1'b0;
assign mdio = mdio_oe ? mdio_out : 1'bz;

initial begin
  foreach (regs[i]) regs[i] = 16'h0000;
  regs[0]    = 16'h1140;
  regs[1]    = 16'h796d;               // link up, autoneg complete
  regs[2]    = 16'h0022;
  regs[3]    = 16'h1622;               // KSZ9031RNX
  regs[5'h1f] = 16'h0048;              // 1000 Mbps, full duplex
end

int   ones = 0;
int   bitcnt = 0;
logic [13:0] hdr;
enum { M_IDLE, M_HDR, M_TA, M_READ, M_WRITE } mstate = M_IDLE;
logic [15:0] shreg;

always @(posedge mdc) begin
  logic b;
  b = (mdio === 1'b0) ? 1'b0 : 1'b1;
  case (mstate)
    M_IDLE: begin
      mdio_oe <= 1'b0;
      if (b) ones <= ones + 1;
      else begin
        if (ones >= 32) begin mstate <= M_HDR; bitcnt <= 1; hdr <= 14'b0; end
        ones <= 0;
      end
    end
    M_HDR: begin
      // start bit '0' already seen; collect: 1, op(2), phyad(5), regad(5)
      hdr <= {hdr[12:0], b};
      bitcnt <= bitcnt + 1;
      if (bitcnt == 13) begin
        logic [13:0] h;
        h = {hdr[12:0], b};
        // h = {start1, op[1:0], phyad[4:0], regad[4:0]} in the low 13 bits
        if (h[12] != 1'b1 || h[9:5] != PHYAD[4:0]) begin
          mstate <= M_IDLE;
        end else if (h[11:10] == 2'b10) begin
          // Speed/duplex (0x1f) and link status (0x01) follow link_up
          mstate <= M_TA;
          shreg  <= (h[4:0] == 5'h1f) ? (link_up ? 16'h0048 : 16'h0000) :
                    (h[4:0] == 5'h01) ? (link_up ? 16'h796d : 16'h7969) : regs[h[4:0]];
        end else if (h[11:10] == 2'b01) begin
          mstate <= M_WRITE;
          bitcnt <= 0;
          hdr <= h;
        end else begin
          mstate <= M_IDLE;
        end
      end
    end
    M_TA: begin
      // first TA bit is Z; drive the second TA bit '0', data follows
      mdio_oe <= 1'b1;
      mdio_out <= 1'b0;
      bitcnt <= 0;
      mstate <= M_READ;
    end
    M_READ: begin
      if (bitcnt < 16) begin
        mdio_out <= shreg[15];
        shreg <= {shreg[14:0], 1'b0};
        bitcnt <= bitcnt + 1;
      end else begin
        mdio_oe <= 1'b0;
        mstate <= M_IDLE;
        ones <= 0;
      end
    end
    M_WRITE: begin
      // two TA bits then 16 data bits
      bitcnt <= bitcnt + 1;
      if (bitcnt >= 2) shreg <= {shreg[14:0], b};
      if (bitcnt == 17) begin
        logic [15:0] d;
        d = {shreg[14:0], b};
        if (hdr[4:0] != 5'h1f && hdr[4:0] != 5'h01) regs[hdr[4:0]] = d;
        mdio_writes.push_back(d);
        mdio_write_addr.push_back(hdr[4:0]);
        mstate <= M_IDLE;
        ones <= 0;
      end
    end
  endcase
end

endmodule
