module pacman_logic
(clk, reset, restart_game, x_coordinate, y_coordinate, pixel_colour, erase, draw_pacman, countdown, score, collision_flag, endgame, PS2_CLK, PS2_DAT, HEX4, HEX5);

input  wire clk, reset;
input  wire restart_game;
output wire [6:0] countdown;

// connect wires to VGA
output wire [8:0]  x_coordinate;
output wire [7:0]  y_coordinate;
output wire [2:0]  pixel_colour;
output wire endgame;
output erase;
output draw_pacman;
output wire [3:0] score;
output [6:0] HEX4, HEX5;
output wire collision_flag;

//keyboard links
inout PS2_CLK;
inout PS2_DAT;

//movement control and position handling
wire upwards, downwards, leftwards, rightwards;
wire move_up;
wire move_down;
wire move_left;
wire move_right;
wire idle;
wire delay;
wire up_collision;
wire down_collision;
wire right_collision;
wire left_collision;
wire game_end;
wire [15:0] user_intake;
wire [6:0] timer;

// connect to the PS2 keyboard
PS2_Demo ps2_instantiation (.CLOCK_50(clk),.KEY(reset),.PS2_CLK(PS2_CLK),.PS2_DAT(PS2_DAT),.last_data_received(user_intake),.HEX0(HEX4),.HEX1(HEX5));

count_down cd1 (.clk(clk), .reset(reset), .HEX2(HEX2_wire), .HEX3(HEX3_wire), .time_out(timeout_wire));

assign countdown = timer;

pacman_movement pm1 (.clk(clk), .reset(reset), .pacman_x(x_coordinate), .pacman_y(y_coordinate), .timer(timer), .draw_up(move_up), .draw_down(move_down), .draw_left(move_left), .draw_right(move_right), .draw_idle(idle), .draw_delay(delay), .draw_collision_up(up_collision), .draw_collision_down(down_collision), .draw_collision_right(right_collision), .draw_collision_left(left_collision), .game_end(game_end), .move_up(upwards), .move_down(downwards), .move_left(leftwards), .move_right(rightwards), .movement_reset(restart_game), .draw_pacman(draw_pacman), .clear_tracks(erase), .score(score));

connect_vga vga_instantiation (.clk(clk), .reset(reset), .timer(timer), .user_intake(user_intake), .draw_idle(idle), .draw_down(move_down), .draw_up(move_up), .draw_right(move_right), .draw_left(move_left), .draw_collision_up(up_collision), .draw_collision_down(down_collision), .draw_collision_right(right_collision), .draw_collision_left(left_collision), .draw_end(game_end), .move_up(upwards), .move_down(downwards), .move_left(leftwards), .move_right(rightwards), .pacman_x(x_coordinate), .pacman_y(y_coordinate), .pixel_colour(pixel_colour), .collision_detected(collision_flag));

assign endgame = game_end;

endmodule

module countdown_clock (input sys_clock,input reset_active_high,output reg [6:0] timer_value,input hit_input);

parameter FREQUENCY = 5000000; 
wire tick_pulse;
clock_prescaler prescaler_inst(
.clk_in(sys_clock), 
.reset_low(~reset_active_high), 
.tick(tick_pulse)
);

always @(posedge sys_clock) begin
if (reset_active_high) begin
timer_value <= 7'd90; // start at 90
end
else if (tick_pulse) begin
timer_value <= timer_value - 1'b1;
end
else if (timer_value == 7'd0) begin
timer_value <= 7'd0; // hold at zero
end
end

endmodule

// make 1Hz tick
module clock_prescaler (input clk_in,input reset_low,output reg tick);

parameter DIVISOR=5000000;
reg [23:0] divider_count;

always @(posedge clk_in) begin
if (!reset_low) begin
divider_count <= DIVISOR - 1;
tick <= 1'b0;
end
else if (divider_count == 24'd0) begin
divider_count <= DIVISOR - 1;
tick <= 1'b1;
end
else begin
divider_count <= divider_count - 1'b1;
tick <= 1'b0;
end
end
endmodule


