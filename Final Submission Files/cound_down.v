module count_down (clk, reset, HEX2, HEX3, time_out);

    input  wire clk;
    input  wire reset;
    output wire [6:0] HEX2;
    output wire [6:0] HEX3;
    output wire time_out;

    //changing 50 MHz to 1 Hz divider
    reg [25:0] div = 26'd0;
    wire new_tic = (div == 26'd49_999_999);

    always @(posedge clk or negedge reset) begin
        if (!reset)
            div <= 26'd0;
        else if (new_tic)
            div <= 26'd0;
        else
            div <= div + 1'b1;
    end

    // BCD countdown (starts at 60)
    reg [3:0] tens = 4'd6;
    reg [3:0] ones = 4'd0;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            tens <= 4'd6;
            ones <= 4'd0;
        end
        else if (new_tic) begin
            if (tens == 4'd0 && ones == 4'd0) begin
                tens <= 4'd0;
                ones <= 4'd0; //stop and remain at 00
            end
            else if (ones == 4'd0) begin
                ones <= 4'd9;
                tens <= tens - 1'b1;
            end
            else begin
                ones <= ones - 1'b1;
            end
        end
    end

    assign time_out = (tens == 4'd0 && ones == 4'd0);

    seg7_decoder d1s  (.digit(ones), .seg(HEX2));
    seg7_decoder d10s (.digit(tens), .seg(HEX3));

endmodule
