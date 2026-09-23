// Protocol helpers for the HL2 testbench: Ethernet, ARP, IPv4, UDP, ICMP and
// OpenHPSDR protocol 1 as implemented by the Hermes-Lite 2.

`timescale 1ps/1fs

package hl2_pkg;

typedef logic [7:0] bytes_t[$];

// Host (PC) identity used by the tests
localparam logic [47:0] HOST_MAC  = 48'h02_00_00_00_00_01;
localparam logic [31:0] HOST_IP   = {8'd192, 8'd168, 8'd33, 8'd10};
localparam logic [15:0] HOST_PORT = 16'd50000;
localparam logic [47:0] BCAST_MAC = 48'hff_ff_ff_ff_ff_ff;

//------------------------------------------------------------------------------
// Byte helpers
function automatic void put16(ref bytes_t b, input logic [15:0] v);
  b.push_back(v[15:8]);
  b.push_back(v[7:0]);
endfunction

function automatic void put32(ref bytes_t b, input logic [31:0] v);
  put16(b, v[31:16]);
  put16(b, v[15:0]);
endfunction

function automatic void put48(ref bytes_t b, input logic [47:0] v);
  put16(b, v[47:32]);
  put32(b, v[31:0]);
endfunction

function automatic logic [15:0] get16(input bytes_t b, input int off);
  return {b[off], b[off+1]};
endfunction

function automatic logic [31:0] get32(input bytes_t b, input int off);
  return {b[off], b[off+1], b[off+2], b[off+3]};
endfunction

function automatic logic [47:0] get48(input bytes_t b, input int off);
  return {b[off], b[off+1], b[off+2], b[off+3], b[off+4], b[off+5]};
endfunction

function automatic logic [15:0] csum16(input bytes_t b, input int off, input int len,
                                       input logic [31:0] init = 0);
  logic [31:0] s = init;
  for (int i = 0; i < len; i += 2)
    s += {b[off+i], (i + 1 < len) ? b[off+i+1] : 8'h00};
  while (s[31:16] != 0) s = s[15:0] + s[31:16];
  return ~s[15:0];
endfunction

function automatic string ip2str(input logic [31:0] ip);
  return $sformatf("%0d.%0d.%0d.%0d", ip[31:24], ip[23:16], ip[15:8], ip[7:0]);
endfunction

//------------------------------------------------------------------------------
// Frame builders
function automatic bytes_t eth_header(input logic [47:0] dst, input logic [47:0] src,
                                      input logic [15:0] ethertype);
  bytes_t b;
  put48(b, dst);
  put48(b, src);
  put16(b, ethertype);
  return b;
endfunction

function automatic bytes_t ipv4_packet(input logic [31:0] src, input logic [31:0] dst,
                                       input logic [7:0] proto, input bytes_t payload);
  bytes_t b;
  logic [15:0] c;
  b.push_back(8'h45);
  b.push_back(8'h00);
  put16(b, 16'(20 + payload.size()));
  put16(b, 16'h1234);            // id
  put16(b, 16'h4000);            // don't fragment
  b.push_back(8'd64);            // ttl
  b.push_back(proto);
  put16(b, 16'h0000);            // checksum placeholder
  put32(b, src);
  put32(b, dst);
  c = csum16(b, 0, 20);
  b[10] = c[15:8];
  b[11] = c[7:0];
  foreach (payload[i]) b.push_back(payload[i]);
  return b;
endfunction

function automatic bytes_t udp_frame(input logic [47:0] dst_mac, input logic [31:0] dst_ip,
                                     input logic [15:0] dst_port, input bytes_t payload,
                                     input logic [15:0] src_port = HOST_PORT,
                                     input logic [47:0] src_mac = HOST_MAC,
                                     input logic [31:0] src_ip = HOST_IP);
  bytes_t u, ip, f;
  logic [31:0] ph;
  logic [15:0] c;
  put16(u, src_port);
  put16(u, dst_port);
  put16(u, 16'(8 + payload.size()));
  put16(u, 16'h0000);
  foreach (payload[i]) u.push_back(payload[i]);
  ph = src_ip[31:16] + src_ip[15:0] + dst_ip[31:16] + dst_ip[15:0] + 32'd17 + u.size();
  c = csum16(u, 0, u.size(), ph);
  if (c == 16'h0000) c = 16'hffff;
  u[6] = c[15:8];
  u[7] = c[7:0];
  ip = ipv4_packet(src_ip, dst_ip, 8'd17, u);
  f = eth_header(dst_mac, src_mac, 16'h0800);
  foreach (ip[i]) f.push_back(ip[i]);
  return f;
endfunction

function automatic bytes_t arp_request(input logic [31:0] target_ip,
                                       input logic [47:0] src_mac = HOST_MAC,
                                       input logic [31:0] src_ip = HOST_IP);
  bytes_t f;
  f = eth_header(BCAST_MAC, src_mac, 16'h0806);
  put16(f, 16'h0001);
  put16(f, 16'h0800);
  f.push_back(8'd6);
  f.push_back(8'd4);
  put16(f, 16'h0001);            // request
  put48(f, src_mac);
  put32(f, src_ip);
  put48(f, 48'h0);
  put32(f, target_ip);
  return f;
endfunction

function automatic bytes_t icmp_echo(input logic [47:0] dst_mac, input logic [31:0] dst_ip,
                                     input logic [15:0] id, input logic [15:0] seq,
                                     input int payload_len);
  bytes_t ic, ip, f;
  logic [15:0] c;
  ic.push_back(8'd8);
  ic.push_back(8'd0);
  put16(ic, 16'h0000);
  put16(ic, id);
  put16(ic, seq);
  for (int i = 0; i < payload_len; i++) ic.push_back(8'(i));
  c = csum16(ic, 0, ic.size());
  ic[2] = c[15:8];
  ic[3] = c[7:0];
  ip = ipv4_packet(HOST_IP, dst_ip, 8'd1, ic);
  f = eth_header(dst_mac, HOST_MAC, 16'h0800);
  foreach (ip[i]) f.push_back(ip[i]);
  return f;
endfunction

//------------------------------------------------------------------------------
// Frame parsing
typedef struct {
  logic [47:0] dst_mac, src_mac;
  logic [15:0] ethertype;
  logic [31:0] src_ip, dst_ip;
  logic [7:0]  proto;
  logic [15:0] src_port, dst_port;
  bit          ip_csum_ok;
  bit          udp_csum_ok;
  int          l4_off;       // offset of the IP payload
  int          payload_off;  // offset of the UDP payload
  int          payload_len;
} frame_info_t;

function automatic frame_info_t parse_frame(input bytes_t f);
  frame_info_t fi;
  int ihl, iplen, ulen;
  fi.dst_mac = get48(f, 0);
  fi.src_mac = get48(f, 6);
  fi.ethertype = get16(f, 12);
  fi.payload_off = -1;
  if (fi.ethertype == 16'h0800 && f.size() >= 34) begin
    ihl = 4 * f[14][3:0];
    iplen = get16(f, 16);
    fi.proto = f[23];
    fi.src_ip = get32(f, 26);
    fi.dst_ip = get32(f, 30);
    fi.ip_csum_ok = (csum16(f, 14, ihl) == 16'h0000);
    fi.l4_off = 14 + ihl;
    if (fi.proto == 8'd17) begin
      logic [31:0] ph;
      fi.src_port = get16(f, fi.l4_off);
      fi.dst_port = get16(f, fi.l4_off + 2);
      ulen = get16(f, fi.l4_off + 4);
      fi.payload_off = fi.l4_off + 8;
      fi.payload_len = ulen - 8;
      if (get16(f, fi.l4_off + 6) == 16'h0000) begin
        fi.udp_csum_ok = 1'b1;      // checksum not used
      end else begin
        ph = fi.src_ip[31:16] + fi.src_ip[15:0] + fi.dst_ip[31:16] + fi.dst_ip[15:0] + 32'd17 + ulen;
        fi.udp_csum_ok = (csum16(f, fi.l4_off, ulen, ph) == 16'h0000);
      end
    end
  end
  return fi;
endfunction

//------------------------------------------------------------------------------
// OpenHPSDR protocol 1
typedef struct {
  logic [6:0]  addr;      // C0[7:1] = {resprqst, addr[5:0]}; bit 6 = response request
  logic [31:0] data;      // C1..C4
} hpsdr_cmd_t;

typedef struct {
  logic signed [15:0] i, q;
  logic signed [15:0] l, r;
} tx_sample_t;

function automatic bytes_t hpsdr_discovery();
  bytes_t p;
  p.push_back(8'hef);
  p.push_back(8'hfe);
  p.push_back(8'h02);
  for (int i = 0; i < 60; i++) p.push_back(8'h00);
  return p;
endfunction

function automatic bytes_t hpsdr_startstop(input bit run, input bit wide = 1'b0,
                                           input bit no_watchdog = 1'b0);
  bytes_t p;
  p.push_back(8'hef);
  p.push_back(8'hfe);
  p.push_back(8'h04);
  p.push_back({no_watchdog, 5'b0, wide, run});
  for (int i = 0; i < 60; i++) p.push_back(8'h00);
  return p;
endfunction

// EP2 packet: two 512 byte frames, each with one command and 63 samples.
// C0 = {resprqst, addr[5:0], ptt}
function automatic bytes_t hpsdr_ep2(input logic [31:0] seq, input hpsdr_cmd_t c0,
                                     input hpsdr_cmd_t c1, input bit ptt,
                                     input tx_sample_t s[$]);
  bytes_t p;
  hpsdr_cmd_t c;
  int k = 0;
  p.push_back(8'hef);
  p.push_back(8'hfe);
  p.push_back(8'h01);
  p.push_back(8'h02);
  put32(p, seq);
  for (int fr = 0; fr < 2; fr++) begin
    c = fr ? c1 : c0;
    p.push_back(8'h7f);
    p.push_back(8'h7f);
    p.push_back(8'h7f);
    p.push_back({c.addr[6], c.addr[5:0], ptt});
    put32(p, c.data);
    for (int n = 0; n < 63; n++) begin
      tx_sample_t x;
      x = (k < s.size()) ? s[k] : '{0, 0, 0, 0};
      k++;
      put16(p, x.l);
      put16(p, x.r);
      put16(p, x.i);
      put16(p, x.q);
    end
  end
  return p;
endfunction

endpackage
