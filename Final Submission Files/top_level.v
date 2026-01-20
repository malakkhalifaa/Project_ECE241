module top_level
(CLOCK_50, KEY, SW,PS2_CLK,PS2_DAT,AUD_ADCDAT, AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,FPGA_I2C_SDAT, AUD_XCK,AUD_DACDAT,FPGA_I2C_SCLK,VGA_CLK, VGA_HS,  VGA_VS, VGA_BLANK_N,VGA_SYNC_N, VGA_R, VGA_G, VGA_B, HEX4, HEX5, HEX1, HEX2, HEX3, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;

//keyboard links
inout PS2_CLK;
inout PS2_DAT;

//audio links
input AUD_ADCDAT;
inout AUD_BCLK;
inout AUD_ADCLRCK;
inout AUD_DACLRCK;
inout FPGA_I2C_SDAT;

output AUD_XCK;
output AUD_DACDAT;
output FPGA_I2C_SCLK;
output VGA_CLK;
output VGA_HS;
output VGA_VS;
output VGA_BLANK_N;
output VGA_SYNC_N;
output [7:0] VGA_R;
output [7:0] VGA_G;
output [7:0] VGA_B;
output [6:0] HEX4;
output [6:0] HEX5;
output [6:0] HEX2;
output [6:0] HEX3;
output [6:0] HEX1;
output [9:0] LEDR;

wire reset_game;
assign reset_game = KEY[0];
wire collision;
wire draw_pacman;
wire erase;
wire [3:0] score;
wire [6:0] countdown_reg;
wire [8:0] x_coordinate;
wire [7:0] y_coordinate;
wire [2:0] pacman_colour;

wire VGA_CLK_game;
wire VGA_HS_game;
wire VGA_VS_game;
wire VGA_BLANK_game;
wire VGA_SYNC_game;
wire [7:0]  VGA_R_game;
wire [7:0]  VGA_G_game;
wire [7:0]  VGA_B_game;

wire VGA_CLK_start;
wire VGA_HS_start;
wire VGA_VS_start;
wire VGA_BLANK_start;
wire VGA_SYNC_start;
wire [7:0]  VGA_R_start;
wire [7:0]  VGA_G_start;
wire [7:0]  VGA_B_start;

wire game_ended;
pacman_logic p1
(.clk(CLOCK_50), .reset (reset_game), .restart_game (SW[1]), .x_coordinate (x_coordinate),
.y_coordinate (y_coordinate), .pixel_color (pacman_colour), .erase (erase), .draw_pacman  (draw_pacman), .countdown  (countdown_reg), .score (score), .collision_flag(collision), .endgame (game_ended), .PS2_CLK  (PS2_CLK), .PS2_DAT  (PS2_DAT), .HEX4 (HEX4), .HEX5 (HEX5));



wire time_out;
count_down cd1 (.clk(CLOCK_50), .reset(reset_game), .HEX2(HEX2), .HEX3(HEX3), .time_out(time_out));

seg7_decoder s1 (.digit(score), .seg(HEX1));



wire [3:0] sound_key;
assign sound_key = {KEY[3:2], ~sound_trigger, KEY[0]};

audio_demo a1 (.CLOCK_50 (CLOCK_50), .KEY (sound_key), .AUD_ADCDAT(AUD_ADCDAT), .AUD_BCLK   (AUD_BCLK), .AUD_ADCLRCK(AUD_ADCLRCK), .AUD_DACLRCK(AUD_DACLRCK), .FPGA_I2C_SDAT(FPGA_I2C_SDAT), .AUD_XCK    (AUD_XCK), .AUD_DACDAT (AUD_DACDAT), .FPGA_I2C_SCLK(FPGA_I2C_SCLK), .SW (SW[3:0]) );


pacman_pixel pp1 (.clock (CLOCK_50), .reset (~reset_game), .pacman_x (x_coordinate), .pacman_y (y_coordinate), .collision (collision), .draw_request (draw_pacman), .clear_request (erase), .VGA_CLK (VGA_CLK_game), .VGA_HS (VGA_HS_game), .VGA_VS (VGA_VS_game), .VGA_BLANK_N (VGA_BLANK_game), .VGA_SYNC_N  (VGA_SYNC_game), .VGA_R (VGA_R_game), .VGA_G (VGA_G_game), .VGA_B      (VGA_B_game));


pacmaze_screen ps1 (.clk(CLOCK_50), .reset(reset_game), .VGA_CLK(VGA_CLK_start), .VGA_HS(VGA_HS_start), .VGA_VS(VGA_VS_start), .VGA_BLANK_N(VGA_BLANK_start), .VGA_SYNC_N(VGA_SYNC_start), .VGA_R(VGA_R_start), .VGA_G(VGA_G_start), .VGA_B(VGA_B_start));



reg start_screen = 1'b1; //initially setting the screen to begin at start screen

always @(posedge CLOCK_50 or negedge KEY[0]) begin
if (!KEY[0]) begin
start_screen <= 1'b0;
end
else begin
if (game_ended || time_out)
start_screen <= 1'b1;
end
end

reg sound_trigger;
reg prev_key_state;

always @(posedge CLOCK_50) begin
prev_key_state <= KEY[0];
if (KEY[0] && !prev_key_state) begin
sound_trigger <= 1'b1;
end
else begin
sound_trigger <= 1'b0;
end
end


// VGA output multiplexing based on screen state
reg [7:0] red_out, green_out, blue_out;
reg vga_clk_out, vga_hs_out, vga_vs_out, vga_blank_out, vga_sync_out;



always @(*) begin
    if (start_screen) begin
        vga_clk_out = VGA_CLK_start;
        vga_hs_out = VGA_HS_start;
        vga_vs_out = VGA_VS_start;
        vga_blank_out = VGA_BLANK_start;
        vga_sync_out = VGA_SYNC_start;
        red_out = VGA_R_start;
        green_out = VGA_G_start;
        blue_out = VGA_B_start;
    end else begin
        vga_clk_out = VGA_CLK_game;
        vga_hs_out = VGA_HS_game;
        vga_vs_out = VGA_VS_game;
        vga_blank_out = VGA_BLANK_game;
        vga_sync_out = VGA_SYNC_game;
        red_out = VGA_R_game;
        green_out = VGA_G_game;
        blue_out = VGA_B_game;
    end
end

assign VGA_CLK = vga_clk_out;
assign VGA_HS = vga_hs_out;
assign VGA_VS = vga_vs_out;
assign VGA_BLANK_N = vga_blank_out;
assign VGA_SYNC_N = vga_sync_out;
assign VGA_R = red_out;
assign VGA_G = green_out;
assign VGA_B = blue_out;

endmodule
