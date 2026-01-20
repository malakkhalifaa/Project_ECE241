module pacman_movement(clk, reset, pacman_x, pacman_y, timer, draw_up, draw_down, draw_left, draw_right, draw_idle, draw_delay, draw_collision_up, draw_collision_down, draw_collision_right, draw_collision_left, game_end, draw_pacman, clear_tracks, move_up, move_down, move_left, move_right, movement_reset, score);

input clk;
input  reset;
input  [8:0] pacman_x;
input  [7:0] pacman_y;
input  [6:0] timer;

output reg draw_up, draw_down, draw_left, draw_right, draw_idle, draw_delay, draw_collision_up, draw_collision_down, draw_collision_right, draw_collision_left, game_end, draw_pacman, clear_tracks;

input move_up, move_down, move_left, move_right, movement_reset;
output reg [3:0] score;

//FSM registers
reg [4:0] current_state, next_state;

//enable from divider
wire rate_enable;

//reading the ROM
wire [16:0] maze_address;

//converting pacman coordinates into 1D memory index
//maze data is stored as a flat array, so each row is 160 cells wide
assign maze_address = (pacman_y*17'd160) + pacman_x;

//checking the position of the entire width and height of pacman, not just the center pixel (he’s 17 pixels wide so 17 bits)

wire [16:0] up_pixel_0, up_pixel_1, up_pixel_2, up_pixel_3, up_pixel_4;
assign up_pixel_0 = maze_address - 17'd482;
assign up_pixel_1 = maze_address - 17'd481;
assign up_pixel_2 = maze_address - 17'd480;
assign up_pixel_3 = maze_address - 17'd479;
assign up_pixel_4 = maze_address - 17'd478;




wire [16:0] right_pixel_0, right_pixel_1, right_pixel_2, right_pixel_3, right_pixel_4;
assign right_pixel_0 = maze_address - 17'd317;
assign right_pixel_1 = maze_address - 17'd157;
assign right_pixel_2 = maze_address + 17'd3;
assign right_pixel_3 = maze_address + 17'd163;
assign right_pixel_4 = maze_address + 17'd323;

wire [16:0] left_pixel_0, left_pixel_1, left_pixel_2, left_pixel_3, left_pixel_4;
assign left_pixel_0 = maze_address-17'd323;  
assign left_pixel_1 = maze_address-17'd163;  
assign left_pixel_2 = maze_address-17'd3;   
assign left_pixel_3 = maze_address+17'd157;
assign left_pixel_4 = maze_address + 17'd317;  

wire [16:0] down_pixel_0, down_pixel_1, down_pixel_2, down_pixel_3, down_pixel_4;
assign down_pixel_0 = maze_address + 17'd478;  
assign down_pixel_1 = maze_address + 17'd479;
assign down_pixel_2 = maze_address + 17'd480;
assign down_pixel_3 = maze_address + 17'd481;
assign down_pixel_4 = maze_address + 17'd482;

// now we read all pacman pixels from maze memory (we are using finalfinalROM with finalfinalmaze.mif)
wire [2:0] up_read_0, up_read_1, up_read_2, up_read_3, up_read_4;
wire [2:0] down_read_0, down_read_1, down_read_2, down_read_3, down_read_4;
wire [2:0] left_read_0, left_read_1, left_read_2, left_read_3, left_read_4;
wire [2:0] right_read_0, right_read_1, right_read_2, right_read_3, right_read_4;

finalfinalROM rom_up_0 (.address(up_pixel_0[14:0]), .clk(clk), .q(up_read_0));
finalfinalROM rom_up_1 (.address(up_pixel_1[14:0]), .clk(clk), .q(up_read_1));
finalfinalROM rom_up_2 (.address(up_pixel_2[14:0]), .clk(clk), .q(up_read_2));
finalfinalROM rom_up_3 (.address(up_pixel_3[14:0]), .clk(clk), .q(up_read_3));
finalfinalROM rom_up_4 (.address(up_pixel_4[14:0]), .clk(clk), .q(up_read_4));

finalfinalROM rom_down_0 (.address(down_pixel_0[14:0]), .clk(clk), .q(down_read_0));
finalfinalROM rom_down_1 (.address(down_pixel_1[14:0]), .clk(clk), .q(down_read_1));
finalfinalROM rom_down_2 (.address(down_pixel_2[14:0]), .clk(clk), .q(down_read_2));
finalfinalROM rom_down_3 (.address(down_pixel_3[14:0]), .clk(clk), .q(down_read_3));
finalfinalROM rom_down_4 (.address(down_pixel_4[14:0]), .clk(clk), .q(down_read_4));

finalfinalROM rom_left_0 (.address(left_pixel_0[14:0]),  .clk(clk), .q(left_read_0));
finalfinalROM rom_left_1 (.address(left_pixel_1[14:0]),  .clk(clk), .q(left_read_1));
finalfinalROM rom_left_2 (.address(left_pixel_2[14:0]),  .clk(clk), .q(left_read_2));
finalfinalROM rom_left_3 (.address(left_pixel_3[14:0]),  .clk(clk), .q(left_read_3));
finalfinalROM rom_left_4 (.address(left_pixel_4[14:0]),  .clk(clk), .q(left_read_4));

finalfinalROM rom_right_0 (.address(right_pixel_0[14:0]), .clk(clk), .q(right_read_0));
finalfinalROM rom_right_1 (.address(right_pixel_1[14:0]), .clk(clk), .q(right_read_1));
finalfinalROM rom_right_2 (.address(right_pixel_2[14:0]), .clk(clk), .q(right_read_2));
finalfinalROM rom_right_3 (.address(right_pixel_3[14:0]), .clk(clk), .q(right_read_3));
finalfinalROM rom_right_4 (.address(right_pixel_4[14:0]), .clk(clk), .q(right_read_4));

//now we combine pacman pixels to check if any of the edges of pacman hits a wall/ghost
wire wall_check_up, wall_check_down, wall_check_left, wall_check_right;
wire ghost_check_up, ghost_check_down, ghost_check_left, ghost_check_right;
wire food_check_up, food_check_down, food_check_left, food_check_right;

//checking for blue coloured pixels (walls)
assign wall_check_up = (up_read_0 == 3'b001) || (up_read_1 == 3'b001) || (up_read_2 == 3'b001) || (up_read_3 == 3'b001) || (up_read_4 == 3'b001);
assign wall_check_down = (down_read_0 == 3'b001) || (down_read_1 == 3'b001) || (down_read_2 == 3'b001) || (down_read_3 == 3'b001) || (down_read_4 == 3'b001);
assign wall_check_left = (left_read_0 == 3'b001) || (left_read_1 == 3'b001) || (left_read_2 == 3'b001) || (left_read_3 == 3'b001) || (left_read_4 == 3'b001);
assign wall_check_right = (right_read_0 == 3'b001) || (right_read_1 == 3'b001) || (right_read_2 == 3'b001) || (right_read_3 == 3'b001) || (right_read_4 == 3'b001);

//checking for red, yellow, green, cyan and pink pixels (ghosts)
assign ghost_check_up = (up_read_0 == 3'b010) || (up_read_0 == 3'b100) || (up_read_0 == 3'b101) || (up_read_0 == 3'b011) || (up_read_0 == 3'b110) || (up_read_1 == 3'b010) || (up_read_1 == 3'b100) || (up_read_1 == 3'b101) || (up_read_1 == 3'b011) || (up_read_1 == 3'b110) || (up_read_2 == 3'b010) || (up_read_2 == 3'b100) || (up_read_2 == 3'b101) || (up_read_2 == 3'b011) || (up_read_2 == 3'b110) || (up_read_3 == 3'b010) || (up_read_3 == 3'b100) || (up_read_3 == 3'b101) || (up_read_3 == 3'b011) || (up_read_3 == 3'b110) || (up_read_4 == 3'b010) || (up_read_4 == 3'b100) || (up_read_4 == 3'b101) || (up_read_4 == 3'b011) || (up_read_4 == 3'b110);
assign ghost_check_down = (down_read_0 == 3'b010) || (down_read_0 == 3'b100) || (down_read_0 == 3'b101) || (down_read_0 == 3'b011) || (down_read_0 == 3'b110) || (down_read_1 == 3'b010) || (down_read_1 == 3'b100) || (down_read_1 == 3'b101) || (down_read_1 == 3'b011) || (down_read_1 == 3'b110) || (down_read_2 == 3'b010) || (down_read_2 == 3'b100) || (down_read_2 == 3'b101) || (down_read_2 == 3'b011) || (down_read_2 == 3'b110) || (down_read_3 == 3'b010) || (down_read_3 == 3'b100) || (down_read_3 == 3'b101) || (down_read_3 == 3'b011) || (down_read_3 == 3'b110) || (down_read_4 == 3'b010) || (down_read_4 == 3'b100) || (down_read_4 == 3'b101) || (down_read_4 == 3'b011) || (down_read_4 == 3'b110);
assign ghost_check_left = (left_read_0 == 3'b010) || (left_read_0 == 3'b100) || (left_read_0 == 3'b101) || (left_read_0 == 3'b011) || (left_read_0 == 3'b110) || (left_read_1 == 3'b010) || (left_read_1 == 3'b100) || (left_read_1 == 3'b101) || (left_read_1 == 3'b011) || (left_read_1 == 3'b110) || (left_read_2 == 3'b010) || (left_read_2 == 3'b100) || (left_read_2 == 3'b101) || (left_read_2 == 3'b011) || (left_read_2 == 3'b110) || (left_read_3 == 3'b010) || (left_read_3 == 3'b100) || (left_read_3 == 3'b101) || (left_read_3 == 3'b011) || (left_read_3 == 3'b110) || (left_read_4 == 3'b010) || (left_read_4 == 3'b100) || (left_read_4 == 3'b101) || (left_read_4 == 3'b011) || (left_read_4 == 3'b110);
assign ghost_check_right = (right_read_0 == 3'b010) || (right_read_0 == 3'b100) || (right_read_0 == 3'b101) || (right_read_0 == 3'b011) || (right_read_0 == 3'b110) || (right_read_1 == 3'b010) || (right_read_1 == 3'b100) || (right_read_1 == 3'b101) || (right_read_1 == 3'b011) || (right_read_1 == 3'b110) || (right_read_2 == 3'b010) || (right_read_2 == 3'b100) || (right_read_2 == 3'b101) || (right_read_2 == 3'b011) || (right_read_2 == 3'b110) || (right_read_3 == 3'b010) || (right_read_3 == 3'b100) || (right_read_3 == 3'b101) || (right_read_3 == 3'b011) || (right_read_3 == 3'b110) || (right_read_4 == 3'b010) || (right_read_4 == 3'b100) || (right_read_4 == 3'b101) || (right_read_4 == 3'b011) || (right_read_4 == 3'b110);

//checking for white coloured pixels (food)
assign food_check_up = (up_read_0 == 3'b111) || (up_read_1 == 3'b111) || (up_read_2 == 3'b111) || (up_read_3 == 3'b111) || (up_read_4 == 3'b111);
assign food_check_down = (down_read_0 == 3'b111) || (down_read_1 == 3'b111) || (down_read_2 == 3'b111) || (down_read_3 == 3'b111) || (down_read_4 == 3'b111);
assign food_check_left = (left_read_0 == 3'b111) || (left_read_1 == 3'b111) || (left_read_2 == 3'b111) || (left_read_3 == 3'b111) || (left_read_4 == 3'b111);
assign food_check_right = (right_read_0 == 3'b111) || (right_read_1 == 3'b111) || (right_read_2 == 3'b111) || (right_read_3 == 3'b111) || (right_read_4 == 3'b111);

wire [2:0] wall_colour_up, wall_colour_down, wall_colour_left, wall_colour_right;
assign wall_colour_up = up_read_2;
assign wall_colour_down = down_read_2;
assign wall_colour_left = left_read_2;
assign wall_colour_right = right_read_2;

// states
parameter
IDLE = 5'd0,
MOVE_UP = 5'd1,
MOVE_DOWN =5'd2,
MOVE_LEFT=5'd3,
MOVE_RIGHT=5'd4,
CLEAR_UP=5'd5,
CLEAR_DOWN=5'd6,
CLEAR_LEFT=5'd7,
CLEAR_RIGHT= 5'd8,
DRAW=5'd9,
DELAY=5'd10,
COLLIDE_UP=5'd11,
COLLIDE_DOWN = 5'd12,
COLLIDE_RIGHT= 5'd13,
COLLIDE_LEFT = 5'd14,
ENDGAME      = 5'd15;

delay_counter d1(.clk(clk), .reset(reset), .begin_counter(draw_delay), .finish_counter(rate_enable));

//food coordinates, exact positions from ROM file since food positions will never change
parameter [8:0] food_1_x = 9'd26;  
parameter [7:0] food_1_y = 8'd24;
parameter [8:0] food_2_x = 9'd29;  
parameter [7:0] food_2_y = 8'd101;
parameter [8:0] food_3_x = 9'd70;  
parameter [7:0] food_3_y = 8'd17;
parameter [8:0] food_4_x = 9'd91; 
parameter [7:0] food_4_y = 8'd11;
parameter [8:0] food_5_x = 9'd123; 
parameter [7:0] food_5_y = 8'd72;
parameter [8:0] food_6_x = 9'd150;
parameter [7:0] food_6_y = 8'd39;

//flag for eaten (total of 6 positions)
reg food1_eaten, food2_eaten, food3_eaten, food4_eaten, food5_eaten, food6_eaten;

//we are adding the +- 3 and 2 because of pacman’s width
wire food1_hit = (pacman_x >= food_1_x - 2 && pacman_x <= food_1_x + 2) && (pacman_y >= food_1_y - 3 && pacman_y <= food_1_y + 3);
wire food2_hit = (pacman_x >= food_2_x - 2 && pacman_x <= food_2_x + 2) && (pacman_y >= food_2_y - 3 && pacman_y <= food_2_y + 3);
wire food3_hit = (pacman_x >= food_3_x - 2 && pacman_x <= food_3_x + 2) && (pacman_y >= food_3_y - 3 && pacman_y <= food_3_y + 3);
wire food4_hit = (pacman_x >= food_4_x - 2 && pacman_x <= food_4_x + 2) && (pacman_y >= food_4_y - 3 && pacman_y <= food_4_y + 3);
wire food5_hit = (pacman_x >= food_5_x - 2 && pacman_x <= food_5_x + 2) && (pacman_y >= food_5_y - 3 && pacman_y <= food_5_y + 3);
wire food6_hit = (pacman_x >= food_6_x - 2 && pacman_x <= food_6_x + 2) && (pacman_y >= food_6_y - 3 && pacman_y <= food_6_y + 3);

//score goes up by one when eat food
always @(posedge clk or negedge reset) begin
if (!reset || movement_reset) begin //initialize all to 0 if reset is pressed
score <= 4'd0;
food1_eaten <= 1'b0;
food2_eaten <= 1'b0;
food3_eaten <= 1'b0;
food4_eaten <= 1'b0;
food5_eaten <= 1'b0;
food6_eaten <= 1'b0;
end 
else begin
if (food1_hit && !food1_eaten) begin 
score <= score + 1; 
food1_eaten <= 1'b1;
 end
if (food2_hit && !food2_eaten) begin
score <= score + 1;
food2_eaten <= 1'b1; 
end
if (food3_hit && !food3_eaten) begin
score <= score + 1; 
food3_eaten <= 1'b1; 
end
if (food4_hit && !food4_eaten) begin 
score <= score + 1; 
food4_eaten <= 1'b1; 
end
if (food5_hit && !food5_eaten) begin 
score <= score + 1; 
food5_eaten <= 1'b1; 
end
if (food6_hit && !food6_eaten) begin 
score <= score + 1; 
food6_eaten <= 1'b1; end
end
end
end

//food eating logic
reg eating;
always @(*) begin
eating = food1_hit && !food1_eaten || food2_hit && !food2_eaten ||food3_hit && !food3_eaten ||food4_hit && !food4_eaten ||food5_hit && !food5_eaten ||food6_hit && !food6_eaten;
end

// next state logic
always @(*) begin
next_state = current_state;
case (current_state)
IDLE: begin
if (move_up)    
next_state = CLEAR_UP;
else if (move_down)  
next_state = CLEAR_DOWN;
else if (move_right) 
next_state = CLEAR_RIGHT;
else if (move_left)  
next_state = CLEAR_LEFT;
else next_state = IDLE;
end

CLEAR_UP: next_state = MOVE_UP;
CLEAR_DOWN: next_state = MOVE_DOWN;
CLEAR_LEFT:  next_state = MOVE_LEFT;
CLEAR_RIGHT: next_state = MOVE_RIGHT;

MOVE_UP: begin
if (wall_check_up)
next_state = COLLIDE_UP;
else if (ghost_check_up)
next_state = ENDGAME;
else if (!wall_check_up && !ghost_check_up)
next_state = DRAW;
else
next_state = ENDGAME;
end

MOVE_DOWN: begin
if (wall_check_down)
next_state = COLLIDE_DOWN;
else if (ghost_check_down)
next_state = ENDGAME;
else if (!wall_check_down && !ghost_check_down)
next_state = DRAW;
else
next_state = ENDGAME;
end

MOVE_RIGHT: begin
if (wall_check_right)
next_state = COLLIDE_RIGHT;
else if (ghost_check_right)
next_state = ENDGAME;
else if (!wall_check_right && !ghost_check_right)
next_state = DRAW;
else
next_state = ENDGAME;
end

MOVE_LEFT: begin
if (wall_check_left)
next_state = COLLIDE_LEFT;
else if (ghost_check_left)
next_state = ENDGAME;
else if (!wall_check_left && !ghost_check_left)
next_state = DRAW;
else
next_state = ENDGAME;
end

COLLIDE_UP: next_state = DRAW;
COLLIDE_DOWN: next_state = DRAW;
COLLIDE_RIGHT: next_state = DRAW;
COLLIDE_LEFT: next_state = DRAW;
DRAW: next_state = DELAY;
DELAY: next_state = (rate_enable) ? IDLE : DELAY;
ENDGAME: next_state = (movement_reset) ? IDLE : ENDGAME;
default: next_state = IDLE;
endcase
end

always @(*) begin
draw_idle  = 1'b0;
draw_up = 1'b0;
draw_down  = 1'b0;
draw_left  = 1'b0;
draw_right = 1'b0;
draw_pacman  = 1'b0;
clear_tracks = 1'b0;
draw_delay = 1'b0;
draw_collision_up = 1'b0;
draw_collision_down = 1'b0;
draw_collision_right = 1'b0;
draw_collision_left = 1'b0;
game_end = 1'b0;

case (current_state)
IDLE:      draw_idle  = 1'b1;
MOVE_UP:   draw_up    = 1'b1;
MOVE_DOWN: draw_down  = 1'b1;
MOVE_RIGHT:draw_right = 1'b1;
MOVE_LEFT: draw_left  = 1'b1;
CLEAR_UP:  clear_tracks = 1'b1;
CLEAR_DOWN:clear_tracks = 1'b1;
CLEAR_LEFT:clear_tracks = 1'b1;
CLEAR_RIGHT:clear_tracks= 1'b1;
DELAY:     draw_delay = 1'b1;
DRAW:      draw_pacman  = 1'b1;
COLLIDE_UP:    draw_collision_up = 1'b1;
COLLIDE_DOWN:  draw_collision_down = 1'b1;
COLLIDE_RIGHT: draw_collision_right = 1'b1;
COLLIDE_LEFT:  draw_collision_left = 1'b1;
ENDGAME:  game_end = 1'b1;
endcase
end

always @(posedge clk or negedge reset) begin
if (!reset)
current_state <= IDLE;
else
current_state <= next_state;
end
endmodule
