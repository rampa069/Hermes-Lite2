// AD9866 model for the HL2 testbench (full duplex, 6 bit nibble interface).
//
// - Drives the 76.8 MHz CLKOUT (period 13020 ps, as ad9866pll expects).
// - RX: a 12 bit ADC sample per clock from a sum of tones plus optional noise,
//   sent as {hi nibble, RXSYNC=0} then {lo nibble, RXSYNC=1} at twice the clock.
// - TX: samples the TX nibbles on the falling edges of the 2x clock; a word is
//   complete when TXSYNC is high. While PGA5 is high the TX pins carry the fast
//   RX PGA gain (FAST_LNA), which is logged.
// - SPI: 16 bit writes {r/w, w1, w0, a[4:0], d[7:0]} sampled on SCLK rising.

`timescale 1ps/1fs

module ad9866_model (
  output logic       clk,
  output logic [5:0] rx,
  output logic       rxsync,
  input  logic [5:0] tx,
  input  logic       txsync,
  input  logic       txquiet_n,
  input  logic       pga5,
  input  logic       mode,
  input  logic       rst_n,
  input  logic       sclk,
  input  logic       sen_n,
  input  logic       sdio
);

localparam real FS = 76.8e6;
localparam real PI = 3.14159265358979323846;

//------------------------------------------------------------------------------
// Clock
initial begin
  clk = 1'b0;
  #3000;
  forever begin
    clk = 1'b1;
    #6510;
    clk = 1'b0;
    #6510;
  end
end

//------------------------------------------------------------------------------
// RX signal source
localparam int NTONES = 4;
real   tone_freq  [NTONES];
real   tone_amp   [NTONES];     // fraction of full scale
real   tone_phase [NTONES];
real   noise_amp  = 0.0;        // fraction of full scale, uniform
real   dc         = 0.0;
int    adc_override = -1;       // >= 0: constant raw ADC code
logic signed [11:0] adc_sample = 12'sd0;
longint unsigned n_adc = 0;

initial begin
  for (int i = 0; i < NTONES; i++) begin
    tone_freq[i] = 0.0;
    tone_amp[i] = 0.0;
    tone_phase[i] = 0.0;
  end
end

function automatic void set_tone(input int idx, input real freq, input real amp);
  tone_freq[idx] = freq;
  tone_amp[idx] = amp;
  tone_phase[idx] = 0.0;
endfunction

function automatic void clear_tones();
  for (int i = 0; i < NTONES; i++) tone_amp[i] = 0.0;
  noise_amp = 0.0;
  dc = 0.0;
  adc_override = -1;
endfunction

function automatic logic signed [11:0] next_adc();
  real v = dc;
  int  code;
  for (int i = 0; i < NTONES; i++) begin
    if (tone_amp[i] != 0.0) begin
      v += tone_amp[i] * $sin(tone_phase[i]);
      tone_phase[i] += 2.0 * PI * tone_freq[i] / FS;
      if (tone_phase[i] > 2.0 * PI) tone_phase[i] -= 2.0 * PI;
    end
  end
  if (noise_amp != 0.0) v += noise_amp * (($urandom % 65536) / 32768.0 - 1.0);
  code = $rtoi(v * 2047.0 + ((v >= 0.0) ? 0.5 : -0.5));
  if (code > 2047) code = 2047;
  if (code < -2048) code = -2048;
  if (adc_override >= 0) code = adc_override;
  return 12'(code);
endfunction

initial begin
  rx = 6'h00;
  rxsync = 1'b0;
end

always @(posedge clk) begin
  logic signed [11:0] s;
  s = next_adc();
  adc_sample <= s;
  n_adc++;
  #1600;
  rx = s[11:6];
  rxsync = 1'b0;
  #6510;
  rx = s[5:0];
  rxsync = 1'b1;
end

//------------------------------------------------------------------------------
// TX capture
logic [5:0]  tx_hi = 6'h00;
logic signed [11:0] tx_word = 12'sd0;
longint unsigned tx_words = 0;
logic [5:0]  pga_gain = 6'h00;
int unsigned pga_updates = 0;
bit          capture_en = 1'b0;
logic signed [11:0] tx_capture[$];
int          capture_max = 1 << 20;
real         tx_peak = 0.0;

// Envelope log: peak |DAC| over blocks of 1024 samples (13.3 us)
bit          env_en = 1'b0;
int          env_peak = 0;
int          env_cnt = 0;
int          env_log[$];
real         env_t0 = 0.0;           // time (ms) of env_log[0]
localparam real ENV_BLOCK_MS = 1024.0 / 76800.0;

task automatic env_start();
  env_log.delete();
  env_peak = 0;
  env_cnt = 0;
  env_t0 = $realtime / 1.0e9;
  env_en = 1'b1;
endtask

task automatic sample_tx();
  if (pga5 === 1'b1) begin
    if (pga_gain != tx) pga_updates++;
    pga_gain = tx;
  end
  if (txsync === 1'b1) begin
    tx_word = {tx_hi, tx};
    tx_words++;
    if (capture_en && tx_capture.size() < capture_max) tx_capture.push_back(tx_word);
  end else begin
    tx_hi = tx;
  end
endtask

// Capture armed to start when the AD9866 TX is enabled (TXQUIET_n rises)
bit arm_txstart = 1'b0;
always @(posedge txquiet_n) begin
  if (arm_txstart) begin
    tx_capture.delete();
    capture_en = 1'b1;
    arm_txstart = 1'b0;
  end
end

// One envelope sample per DAC clock; 0 while the AD9866 TX is disabled
task automatic env_sample();
  int a;
  a = (txquiet_n !== 1'b1) ? 0 : ((tx_word < 0) ? -tx_word : tx_word);
  if (a > env_peak) env_peak = a;
  env_cnt++;
  if (env_cnt == 1024) begin
    env_log.push_back(env_peak);
    env_peak = 0;
    env_cnt = 0;
  end
endtask

always @(posedge clk) begin
  #3255 sample_tx();
  #6510 sample_tx();
  if (env_en) env_sample();
end

//------------------------------------------------------------------------------
// SPI
logic [15:0] spi_sh = 16'h0;
int          spi_cnt = 0;
logic [7:0]  spi_regs [0:31];
logic [15:0] spi_log[$];

initial foreach (spi_regs[i]) spi_regs[i] = 8'h00;

always @(posedge sclk) begin
  if (sen_n === 1'b0) begin
    spi_sh = {spi_sh[14:0], sdio};
    spi_cnt++;
    if (spi_cnt == 16) begin
      spi_log.push_back(spi_sh);
      if (spi_sh[15] == 1'b0) spi_regs[spi_sh[12:8]] = spi_sh[7:0];
      spi_cnt = 0;
    end
  end
end

always @(posedge sen_n) spi_cnt = 0;

endmodule
