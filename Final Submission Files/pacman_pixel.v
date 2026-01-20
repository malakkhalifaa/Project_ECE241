module pacman_pixel( clk, reset, pacman_x, pacman_y, collision, draw, erase, VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);

input wire clk;
input wire reset;
input wire [8:0] pacman_x;
input wire [7:0] pacman_y;
input wire collision;
input wire draw;
input wire erase;

output wire VGA_CLK;
output wire VGA_HS;
output wire VGA_VS;
output wire VGA_BLANK_N;
output wire VGA_SYNC_N;
output wire [7:0] VGA_R;
output wire [7:0] VGA_G;
output wire [7:0] VGA_B;

parameter
pacman_size = 5,
pacman_pixels = 25,
pacman_index_max = 5'd24,
pacman_center_offset = 2'd2,
screen_width = 9'd160,
screen_height = 8'd120,
total_pixels = 17'd19199,
address_bit_size = 15,
idle_state = 2'd0,
drawing_state = 2'd1,
erase_state = 2'd2,
idle_food_state = 2'd0,
wait_food_state = 2'd1,
draw_food_state = 2'd2,
black_colour = 3'b000,
yellow_colour = 3'b110,
white_colour = 3'b111,
pacman_size_factor = 5'd5;

reg  [8:0] pixel_x;
reg  [7:0] pixel_y;
reg  [2:0] pixel_colour;
reg plot_enable;
reg [4:0] current_pixel_index;
reg [1:0] pacman_state;
reg [8:0] pacman_center_x;
reg [7:0] pacman_center_y;

reg [8:0] draw_x_coordinate;
reg [7:0] draw_y_coordinate;
reg draw_wire;
reg erase_wire;

reg [8:0] prev_x_coordinate;
reg [7:0] prev_y_coordinate;
reg erase_tracks;

reg [16:0] food_address;
reg [1:0] food_state;
reg [8:0] food_x_coordinate;
reg [7:0] food_y_coordinate;
wire [2:0] food_colour;

wire pacman_pixel;
wire [2:0] pacman_row;
wire [2:0] pacman_col;

finalfinalROM food_rom (.address(food_address[address_bit_size-1:0]), .clk(clk), .q(food_colour));

wire [24:0] pacman_pattern = 25'b01100_11111_11100_11111_01100;
assign pacman_pixel = pacman_pattern[24 - current_pixel_index];

assign pacman_row = current_pixel_index / pacman_size_factor;
assign pacman_col = current_pixel_index % pacman_size_factor;

always @(posedge clk) begin
plot_enable <= 1'b0;
if (reset) begin
        pixel_x <= 9'd0;
        pixel_y <= 8'd0;
        pixel_colour <= black_colour;
        current_pixel_index <= 5'd0;
        pacman_state <= idle_state;
        pacman_center_x <= 9'd0;
        pacman_center_y <= 8'd0;
        draw_wire <= 1'b0;
        erase_wire <= 1'b0;
        draw_x_coordinate <= 9'd0;
        draw_y_coordinate <= 8'd0;
        erase_tracks <= 1'b1;
        food_address <= 17'd0;
        food_x_coordinate <= 9'd0;
        food_y_coordinate <= 8'd0;
        food_state <= wait_food_state;
   	 end
 	   else begin
        case (food_state)
            idle_food_state: ;
            wait_food_state: food_state <= draw_food_state;
            draw_food_state: begin
                	if (food_colour == white_colour) begin
                    pixel_x <= food_x_coordinate;
                    pixel_y <= food_y_coordinate;
                    pixel_colour <= white_colour;
                    plot_enable <= 1'b1;
                	end

                if (food_address < total_pixels) begin
                    food_address <= food_address + 1'b1;
                    food_x_coordinate <= food_address % screen_width;
                    food_y_coordinate <= food_address / screen_width;
                    food_state <= wait_food_state;
                end
                else food_state <= idle_food_state;
            end
            default: food_state <= idle_food_state;
        endcase

        if (food_state == idle_food_state) begin
            if (erase) erase_wire <= 1'b1;
            if (draw) draw_wire <= 1'b1;

            case (pacman_state)
                idle_state: begin
                    if (erase_tracks && (prev_x_coordinate != 9'd0 || prev_y_coordinate != 8'd0)) begin
                        pacman_center_x <= prev_x_coordinate;
                        pacman_center_y <= prev_y_coordinate;
                        current_pixel_index <= 5'd0;
                        pacman_state <= erase_state;
                        erase_tracks <= 1'b0;
                    end
                    else if (erase_wire) begin
                        current_pixel_index <= 5'd0;
                        pacman_state <= erase_state;
                        erase_wire <= 1'b0;
                    end
                    else if (draw_wire) begin
                        pacman_center_x <= draw_x_coordinate;
                        pacman_center_y <= draw_y_coordinate;
                        current_pixel_index <= 5'd0;
                        pacman_state <= drawing_state;
                        draw_wire <= 1'b0;
                    end
                end

                drawing_state: begin
                    if (current_pixel_index < pacman_pixels) begin
                        if (pacman_pixel) begin
                            pixel_x <= pacman_center_x + pacman_col - pacman_center_offset;
                            pixel_y <= pacman_center_y + pacman_row - pacman_center_offset;
                            pixel_colour <= yellow_colour;
                            plot_enable <= 1'b1;
                        end
                        current_pixel_index <= current_pixel_index + 1'b1;
                    end
                    else begin
                        prev_x_coordinate <= pacman_center_x;
                        prev_y_coordinate <= pacman_center_y;

                        if (erase_wire) begin
                            current_pixel_index <= 5'd0;
                            pacman_state <= erase_state;
                            erase_wire <= 1'b0;
                        end
                        else if (draw_wire) begin
                            pacman_center_x <= draw_x_coordinate;
                            pacman_center_y <= draw_y_coordinate;
                            current_pixel_index <= 5'd0;
                            pacman_state <= drawing_state;
                            draw_wire <= 1'b0;
                        end
                        else pacman_state <= idle_state;
                    end
                end
                erase_state: begin
                    if (current_pixel_index < pacman_pixels) begin
                        if (pacman_pixel) begin
                            pixel_x <= pacman_center_x + pacman_col - pacman_center_offset;
                            pixel_y <= pacman_center_y + pacman_row - pacman_center_offset;
                            pixel_colour <= black_colour;
                            plot_enable <= 1'b1;
                        end
                        current_pixel_index <= current_pixel_index + 1'b1;
                    end
                    else begin
                        if (erase_wire) begin
                            current_pixel_index <= 5'd0;
                            pacman_state <= erase_state;
                            erase_wire <= 1'b0;
                        end
                        else if (draw_wire) begin
                            pacman_center_x <= draw_x_coordinate;
                            pacman_center_y <= draw_y_coordinate;
                            current_pixel_index <= 5'd0;
                            pacman_state <= drawing_state;
                            draw_wire <= 1'b0;
                        end
                        else pacman_state <= idle_state;
                    end
                end

                default: pacman_state <= idle_state;
            endcase
        end
    end
end

vga_adapter VGA (.reset(~reset), .clk(clk), .colour(pixel_colour), .x(pixel_x), .y(pixel_y), .write(plot_enable), .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS), .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N), .VGA_CLK(VGA_CLK));

defparam VGA.RESOLUTION = "160x120";
defparam VGA.COLOR_DEPTH = 3;
defparam VGA.BACKGROUND_IMAGE = "finalfinalmaze.mif";

endmodule


