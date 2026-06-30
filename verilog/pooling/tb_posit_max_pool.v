`timescale 1ns / 1ps

module tb_posit_max_pool;

    parameter N = 8;
    parameter CHANNELS = 2;
    parameter NUM_WINDOWS = 2;
    parameter POOL_SIZE = 2;
    parameter WINDOW_ELEMS = POOL_SIZE * POOL_SIZE;

    reg  [NUM_WINDOWS*CHANNELS*WINDOW_ELEMS*N-1:0] window_in;
    wire [NUM_WINDOWS*CHANNELS*N-1:0]              pool_out;

    integer errors;

    localparam [N-1:0] POSIT_ZERO = 8'b00000000;
    localparam [N-1:0] POSIT_HALF = 8'b00110000;
    localparam [N-1:0] POSIT_ONE  = 8'b01000000;
    localparam [N-1:0] POSIT_TWO  = 8'b01010000;
    localparam [N-1:0] POSIT_FOUR = 8'b01100000;
    localparam [N-1:0] POSIT_NEG1 = 8'b11000000;
    localparam [N-1:0] POSIT_NEG2 = 8'b10110000;
    localparam [N-1:0] POSIT_NAR  = 8'b10000000;

    posit_max_pool #(
        .N(N),
        .CHANNELS(CHANNELS),
        .NUM_WINDOWS(NUM_WINDOWS),
        .POOL_SIZE(POOL_SIZE),
        .WINDOW_ELEMS(WINDOW_ELEMS)
    ) DUT (
        .window_in (window_in),
        .pool_out  (pool_out)
    );

    task set_window_value;
        input integer w;
        input integer c;
        input integer e;
        input [N-1:0] value;
        integer idx;
        begin
            idx = (((w * CHANNELS + c) * WINDOW_ELEMS + e) * N);
            window_in[idx +: N] = value;
        end
    endtask

    task check_pool;
        input integer w;
        input integer c;
        input [N-1:0] expected;
        input [255:0] name;
        integer idx;
        begin
            idx = ((w * CHANNELS + c) * N);
            if (pool_out[idx +: N] !== expected) begin
                $display("FAIL %0s: got %b expected %b",
                         name, pool_out[idx +: N], expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    initial begin
        errors = 0;
        window_in = {NUM_WINDOWS*CHANNELS*WINDOW_ELEMS*N{1'b0}};

        // Window 0, channel 0: max(0, 1, 2, 0.5) = 2
        set_window_value(0, 0, 0, POSIT_ZERO);
        set_window_value(0, 0, 1, POSIT_ONE);
        set_window_value(0, 0, 2, POSIT_TWO);
        set_window_value(0, 0, 3, POSIT_HALF);

        // Window 0, channel 1: max(-2, -1, 0, -1) = 0
        set_window_value(0, 1, 0, POSIT_NEG2);
        set_window_value(0, 1, 1, POSIT_NEG1);
        set_window_value(0, 1, 2, POSIT_ZERO);
        set_window_value(0, 1, 3, POSIT_NEG1);

        // Window 1, channel 0: max(1, 4, 2, 0.5) = 4
        set_window_value(1, 0, 0, POSIT_ONE);
        set_window_value(1, 0, 1, POSIT_FOUR);
        set_window_value(1, 0, 2, POSIT_TWO);
        set_window_value(1, 0, 3, POSIT_HALF);

        // Window 1, channel 1: any NaR propagates NaR
        set_window_value(1, 1, 0, POSIT_ONE);
        set_window_value(1, 1, 1, POSIT_NAR);
        set_window_value(1, 1, 2, POSIT_TWO);
        set_window_value(1, 1, 3, POSIT_ZERO);

        #10;

        check_pool(0, 0, POSIT_TWO,  "window0 channel0 max is 2");
        check_pool(0, 1, POSIT_ZERO, "window0 channel1 max is 0");
        check_pool(1, 0, POSIT_FOUR, "window1 channel0 max is 4");
        check_pool(1, 1, POSIT_NAR,  "window1 channel1 NaR propagates");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);

        $finish;
    end

endmodule
