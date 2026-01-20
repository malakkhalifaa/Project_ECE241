module pacmaze_screen (clk, reset, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);

input  wire clk;
input  wire reset;
output wire VGA_CLK;
output wire VGA_HS;
output wire VGA_VS;
output wire VGA_BLANK_N;
output wire VGA_SYNC_N;
output wire [7:0]  VGA_R;
output wire [7:0]  VGA_G;
output wire [7:0]  VGA_B;

vga_adapter VGA (.reset (reset), .clk (clk), .colour(3'b000), .x(8'd0), .y(7'd0), .write(1'b0), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N), .VGA_CLK(VGA_CLK));

defparam VGA.RESOLUTION = "160 x 120";
defparam VGA.COLOUR_DEPTH = 3;
defparam VGA.BACKGROUND_IMAGE = "titlefinal.mif";

endmodule
