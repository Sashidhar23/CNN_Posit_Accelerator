`timescale 1ns / 1ps

module tb_posit_relu2d;

    parameter N = 8;
    parameter CHANNELS = 2;
    parameter HEIGHT = 2;
    parameter WIDTH = 2;
    parameter NUM_VALUES = CHANNELS * HEIGHT * WIDTH;

    reg  [NUM_VALUES*N-1:0] data_in;
    wire [NUM_VALUES*N-1:0] data_out;

    integer errors;

    localparam [N-1:0] POSIT_ZERO = 8'b00000000;
    localparam [N-1:0] POSIT_ONE  = 8'b01000000;
    localparam [N-1:0] POSIT_TWO  = 8'b01010000;
    localparam [N-1:0] POSIT_NEG1 = 8'b11000000;
    localparam [N-1:0] POSIT_NEG2 = 8'b10110000;
    localparam [N-1:0] POSIT_NAR  = 8'b10000000;

    posit_relu2d #(
        .N(N),
        .CHANNELS(CHANNELS),
        .HEIGHT(HEIGHT),
        .WIDTH(WIDTH)
    ) DUT (
        .data_in  (data_in),
        .data_out (data_out)
    );

    task set_value;
        input integer c;
        input integer y;
        input integer x;
        input [N-1:0] value;
        integer idx;
        begin
            idx = ((c * HEIGHT * WIDTH + y * WIDTH + x) * N);
            data_in[idx +: N] = value;
        end
    endtask

    task check_value;
        input integer c;
        input integer y;
        input integer x;
        input [N-1:0] expected;
        input [255:0] name;
        integer idx;
        begin
            idx = ((c * HEIGHT * WIDTH + y * WIDTH + x) * N);
            if (data_out[idx +: N] !== expected) begin
                $display("FAIL %0s: got %b expected %b",
                         name, data_out[idx +: N], expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    initial begin
        errors = 0;
        data_in = {NUM_VALUES*N{1'b0}};

        set_value(0, 0, 0, POSIT_NEG1);
        set_value(0, 0, 1, POSIT_ZERO);
        set_value(0, 1, 0, POSIT_ONE);
        set_value(0, 1, 1, POSIT_TWO);

        set_value(1, 0, 0, POSIT_NEG2);
        set_value(1, 0, 1, POSIT_NAR);
        set_value(1, 1, 0, POSIT_ONE);
        set_value(1, 1, 1, POSIT_ZERO);

        #10;

        check_value(0, 0, 0, POSIT_ZERO, "channel0 negative clamps");
        check_value(0, 0, 1, POSIT_ZERO, "channel0 zero passes");
        check_value(0, 1, 0, POSIT_ONE,  "channel0 one passes");
        check_value(0, 1, 1, POSIT_TWO,  "channel0 two passes");
        check_value(1, 0, 0, POSIT_ZERO, "channel1 negative clamps");
        check_value(1, 0, 1, POSIT_NAR,  "channel1 NaR propagates");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);

        $finish;
    end

endmodule
