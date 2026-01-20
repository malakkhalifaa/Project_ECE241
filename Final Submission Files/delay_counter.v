module delay_counter (clk, reset, begin_count, finish_counter);

input clk;
input reset;
input begin_count;
output reg finish_counter;

parameter MAX_COUNT = 2000000;
reg [23:0] current_count;

always @(posedge clk or negedge reset) begin
if (!reset) begin
current_count <= MAX_COUNT - 1;
finish_counter <= 1'b0;
end
else begin
if (current_count == 24'd0) begin
current_count <= MAX_COUNT - 1;
finish_counter <= 1'b1;
end
else if (begin_count) begin
current_count <= current_count - 1'b1;
finish_counter <= 1'b0;
end
else begin
finish_counter <= 1'b0;
end
end
end
endmodule
