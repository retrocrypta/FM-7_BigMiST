`default_nettype none

module guest_top(
    input         CLOCK_27,
    `ifdef USE_CLOCK_50
    input         CLOCK_50,
    `endif

    // LED outputs
    output        LED,

    // Video outputs
    output  [5:0] VGA_R,
    output  [5:0] VGA_G,
    output  [5:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,

    `ifdef USE_HDMI
    output        HDMI_RST,
    output  [7:0] HDMI_R,
    output  [7:0] HDMI_G,
    output  [7:0] HDMI_B,
    output        HDMI_HS,
    output        HDMI_VS,
    output        HDMI_PCLK,
    output        HDMI_DE,
    inout         HDMI_SDA,
    inout         HDMI_SCL,
    input         HDMI_INT,
    `endif

    // Audio outputs
    output        AUDIO_L,
    output        AUDIO_R,
`ifdef I2S_AUDIO
        output        I2S_BCK,
        output        I2S_LRCK,
        output        I2S_DATA,
`endif
`ifdef I2S_AUDIO_HDMI
        output        HDMI_MCLK,
        output        HDMI_BCK,
        output        HDMI_LRCK,
        output        HDMI_SDATA,
`endif
`ifdef SPDIF_AUDIO
        output        SPDIF,
`endif	 

    // SPI interface to control module
    input         SPI_SCK,
    input         SPI_SS2,
    input         SPI_SS3,
    input         SPI_DI,
    output        SPI_DO,
    input         CONF_DATA0,

    // SDRAM interface
    inout  [15:0] SDRAM_DQ,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nWE,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nCS,
    output        SDRAM_CLK,
    output        SDRAM_CKE
);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef USE_QSPI
localparam bit QSPI = 1;
assign QDAT = 4'hZ;
`else
localparam bit QSPI = 0;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam bit HDMI = 1;
assign HDMI_RST = 1'b1;
`else
localparam bit HDMI = 0;
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
`define SEP "-;",
`else
localparam bit BIG_OSD = 0;
`define SEP
`endif

// remove this if the 2nd chip is actually used
`ifdef DUAL_SDRAM
assign SDRAM2_A = 13'hZZZZ;
assign SDRAM2_BA = 0;
assign SDRAM2_DQML = 0;
assign SDRAM2_DQMH = 0;
assign SDRAM2_CKE = 0;
assign SDRAM2_CLK = 0;
assign SDRAM2_nCS = 1;
assign SDRAM2_DQ = 16'hZZZZ;
assign SDRAM2_nCAS = 1;
assign SDRAM2_nRAS = 1;
assign SDRAM2_nWE = 1;
`endif

`ifdef USE_HDMI
wire        i2c_start;
wire        i2c_read;
wire  [6:0] i2c_addr;
wire  [7:0] i2c_subaddr;
wire  [7:0] i2c_dout;
wire  [7:0] i2c_din;
wire        i2c_ack;
wire        i2c_end;
`endif


// Configuration string
localparam CONF_STR = {
    "FM-7;;",
    "F1,t77,Load Tape;",
    "O8,Tape Rewind;",
    "O9,Tape Audio,Off,On;",
    "OAB,BootROM,Basic,1,2,3;",
    `SEP
    "O2,TV Mode,NTSC,PAL;",
    "O34,Noise,White,Red,Green,Blue;",
    "T0,Reset;",
    "V,v1.0."
};

// Clocks and PLL
wire clk_sys,_2MHz;
wire locked;

pll pll(
    .inclk0(CLOCK_50),
    .c0(clk_sys),  // SDRAM clock
    .c1(_2MHz),  // System clock
    .locked(locked)
);

// Reset logic
wire reset = ~locked | status[0] | buttons[1];

reg old_ioctl_download;
always @(posedge clk_sys)
  old_ioctl_download <= ioctl_download;


  
wire rewind = (old_ioctl_download & ~ioctl_download) | status[8];
wire [13:0] audio_out;
wire buzzer;
wire [7:0] relay_snd;

wire [15:0] cin_audio = { 1'b0, cin & motor & status[9], 13'b0 };
wire [15:0] core_audio =  { 1'b0, audio_out, 1'b0 };
wire [15:0] buz_audio = { 1'b0, buzzer, 14'b0 };
wire [15:0] relay_audio = { 1'b0, (status[9] ? relay_snd : 8'd0), 7'b0 };



assign audio_l = cin_audio + core_audio + buz_audio + relay_audio;
assign audio_r = cin_audio + core_audio + buz_audio + relay_audio;



// Status and control signals
wire [31:0] status;
wire  [1:0] buttons;
wire  [1:0] scandoubler_disable;
wire        ypbpr;
wire        no_csync;

// Data IO interface
wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_dout;

data_io #(.DOUT_16(1)) data_io
(
    .clk_sys(clk_sys),
    .SPI_SCK(SPI_SCK),
    .SPI_SS2(SPI_SS2),
    .SPI_DI(SPI_DI),
    .clkref_n(1'b0),
    .ioctl_download(ioctl_download),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout)
);

// User IO interface
wire [31:0] joy1, joy2;
wire [10:0] ps2_key;
wire forced_scandoubler;

user_io #(
    .STRLEN($size(CONF_STR)>>3),
    .SD_IMAGES(1),
    .FEATURES(32'h0 | (BIG_OSD << 13))
) user_io(
	.clk_sys             (clk_sys          ),
   .clk_sd              (clk_sys          ),
	.SPI_SS_IO           (CONF_DATA0),
	.SPI_CLK             (SPI_SCK),
	.SPI_MOSI            (SPI_DI),
	.SPI_MISO            (SPI_DO),

	.conf_str            (CONF_STR),
	.status              (status),
	.scandoubler_disable (forced_scandoubler),
	.ypbpr               (ypbpr),
	.no_csync            (no_csync),
	.buttons             (buttons),
	
   .key_strobe(key_strobe),
   .key_code(key_code),
   .key_pressed(key_pressed),
   .key_extended(key_extended),
	 
`ifdef USE_HDMI
	.i2c_start      (i2c_start      ),
	.i2c_read       (i2c_read       ),
	.i2c_addr       (i2c_addr       ),
	.i2c_subaddr    (i2c_subaddr    ),
	.i2c_dout       (i2c_dout       ),
	.i2c_din        (i2c_din        ),
	.i2c_ack        (i2c_ack        ),
	.i2c_end        (i2c_end        ),
`endif
);

// Video signals
wire [7:0] video_r, video_g, video_b;
wire       video_hs, video_vs;
wire       video_hblank, video_vblank;
wire       ce_pix;

// Video output
mist_video #(
    .COLOR_DEPTH(8),
    .SD_HCNT_WIDTH(10),
    .USE_BLANKS(1'b1),
    .OUT_COLOR_DEPTH(VGA_BITS),
    .BIG_OSD(BIG_OSD)
) mist_video(
    .clk_sys(clk_sys),
    .SPI_SCK(SPI_SCK),
    .SPI_SS3(SPI_SS3),
    .SPI_DI(SPI_DI),
    .R(video_r),
    .G(video_g),
    .B(video_b),
    .HSync(video_hs),
    .VSync(video_vs),
    .HBlank(video_hblank),
    .VBlank(video_vblank),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_VS(VGA_VS),
    .VGA_HS(VGA_HS),
    .ce_divider(1'b0),
    .scandoubler_disable(scandoubler_disable),
    .scanlines(status[3:1]),
    .ypbpr(ypbpr),
    .no_csync(no_csync)
);

// Audio output
wire [15:0] audio_l, audio_r;

dac #(.C_bits(16)) dac_l(
    .clk_i(clk_sys),
    .res_n_i(1),
    .dac_i(audio_l),
    .dac_o(AUDIO_L)
);

dac #(.C_bits(16)) dac_r(
    .clk_i(clk_sys),
    .res_n_i(1),
    .dac_i(audio_r),
    .dac_o(AUDIO_R)
);

`ifdef I2S_AUDIO

wire [31:0] clk_rate =  32'd48_000_000;

i2s i2s (
        .reset(reset),
        .clk(clk_sys),
        .clk_rate(clk_rate),

        .sclk(I2S_BCK),
        .lrclk(I2S_LRCK),
        .sdata(I2S_DATA),

        .left_chan (audio_l),
        .right_chan(audio_r)
);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clk_sys) begin
        HDMI_BCK <= I2S_BCK;
        HDMI_LRCK <= I2S_LRCK;
        HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif (
        .clk_i(clk_sys),
        .rst_i(1'b0),
        .clk_rate_i(clk_rate),
        .spdif_o(SPDIF),
        .sample_i({audio_l,audio_r})
);
`endif


// Core instance
wire buffer;

core u_core(
    .RESETn(~reset),
    .CLKSYS(clk_sys),
    .HBLANK(video_hblank),
    .VBLANK(video_vblank),
    .VSync(video_vs),
    .HSync(video_hs),
    .grb({video_g[7], video_r[7], video_b[7]}),
    .ps2_key(ps2_key),
    .ce_pix(ce_pix),
    .audio_out   ( audio_out     ),
    .buzzer      ( buzzer        ),
    // tape
    .cin         ( cin           ),
    .motor       ( motor         ),
    .bootrom_sel ( status[11:10] )
);

wire cin;
wire motor;
wire [15:0] sdram_data;
wire [24:0] sdram_addr;
wire need_more_byte;
wire sdram_ready;

t77_decode u_t77_decode(
  .CLKSYS     ( clk_sys        ),
  .start      ( motor          ),
  .data       ( sdram_data     ),
  .data_stb   ( sdram_ready    ),
  .sdram_addr ( sdram_addr     ),
  .sdram_rd   ( need_more_byte ),
  .sout       ( cin            ),
  .rewind     ( rewind         )
);


sdram u_sdram(
  .*,
  .init  ( ~locked                                  ),
  .clk   ( clk_sys                                  ),
  .wtbt  ( 2'b11                                    ),
  .addr  ( ioctl_download ? ioctl_addr : sdram_addr ),
  .dout  ( sdram_data                               ),
  .din   ( ioctl_dout                               ),
  .we    ( ioctl_wr                                 ),
  .rd    ( need_more_byte                           ),
  .ready ( sdram_ready                              )
);

pcm pcm(
  .CLKSYS         ( clk_sys   ),
  .motor          ( motor     ),
  .unsigned_audio ( relay_snd )
);

// LED assignment (inverted)
assign LED = ~ioctl_download;

`ifdef USE_HDMI
assign HDMI_RST = 1'b1;
`endif
// [8] - extended, [9] - pressed, [10] - toggles with every press/release
wire        key_pressed;
wire [7:0]  key_code;
wire        key_strobe;
wire        key_extended;


assign ps2_key = {key_strobe,key_pressed,key_extended,key_code};


endmodule
