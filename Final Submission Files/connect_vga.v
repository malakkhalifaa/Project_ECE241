module connect_vga (clk, reset, timer, user_intake, draw_idle, draw_down, draw_up, draw_right, draw_left, draw_collision_up, draw_collision_down, draw_collision_right, draw_collision_left, draw_end, move_up, move_down, move_left, move_right, pacman_x, pacman_y, pixel_colour, collision_detected);

input clk;
input reset;
input [6:0] timer;
input [15:0] user_intake;
input draw_idle, draw_down, draw_up, draw_right, draw_left;
input draw_collision_up, draw_collision_down, draw_collision_right, draw_collision_left;
input draw_end;

output reg move_up, move_down, move_left, move_right;
output reg [8:0] pacman_x;
output reg [7:0] pacman_y;
output reg [2:0] pixel_colour;
output reg collision_detected;

// Initialization / reset
always @(posedge clk or negedge reset) begin
    if (!reset) begin
        pacman_x      <= 9'd10;
        pacman_y      <= 8'd10;
        pacman_colour <= 3'b000;
        move_up       <= 1'b0;
        move_down     <= 1'b0;
        move_left     <= 1'b0;
        move_right    <= 1'b0;
        collision_detected  <= 1'b0;
    end
    else begin
        // Default values
        move_up       <= 1'b0;
        move_down     <= 1'b0;
        move_left     <= 1'b0;
        move_right    <= 1'b0;
        collision_detected  <= 1'b0;

        // Movement signals
        if (draw_up)    move_up    <= 1'b1;
        if (draw_down)  move_down  <= 1'b1;
        if (draw_left)  move_left  <= 1'b1;
        if (draw_right) move_right <= 1'b1;

        // Collisions
        if (draw_collision_up)    begin collision_detected <= 1'b1; pacman_y <= pacman_y + 1; end
        if (draw_collision_down)  begin collision_detected <= 1'b1; pacman_y <= pacman_y - 1; end
        if (draw_collision_left)  begin collision_detected <= 1'b1; pacman_x <= pacman_x + 1; end
        if (draw_collision_right) begin collision_detected <= 1'b1; pacman_x <= pacman_x - 1; end

        // Movement updates
        if (draw_up)    pacman_y <= pacman_y - 1;
        if (draw_down)  pacman_y <= pacman_y + 1;
        if (draw_left)  pacman_x <= pacman_x - 1;
        if (draw_right) pacman_x <= pacman_x + 1;

        // Pacman color logic
        if (draw_up || draw_down || draw_left || draw_right ||
            draw_collision_up || draw_collision_down || draw_collision_left || draw_collision_right)
            pacman_colour <= 3'b110; // yellow
        else if (draw_idle || draw_delay || game_end)
            pacman_colour <= 3'b000; // black
    end
end

endmodule



