`timescale 1ns / 1ps

module tb_posit_maxpool2d;

    parameter N = 8;
    parameter CHANNELS = 2;
    parameter HEIGHT = 7;
    parameter WIDTH = 7;
    parameter POOL_SIZE = 2;
    parameter STRIDE = 2;
    parameter OUT_H = ((HEIGHT - POOL_SIZE) / STRIDE) + 1;
    parameter OUT_W = ((WIDTH  - POOL_SIZE) / STRIDE) + 1;

    reg  [CHANNELS*HEIGHT*WIDTH*N-1:0] feature_in;
    wire [CHANNELS*OUT_H*OUT_W*N-1:0]  pool_out;

    integer errors;
    integer y;
    integer x;

    localparam [N-1:0] POSIT_ZERO = 8'b00000000;
    localparam [N-1:0] POSIT_HALF = 8'b00110000;
    localparam [N-1:0] POSIT_ONE  = 8'b01000000;
    localparam [N-1:0] POSIT_TWO  = 8'b01010000;
    localparam [N-1:0] POSIT_FOUR = 8'b01100000;
    localparam [N-1:0] POSIT_NEG1 = 8'b11000000;
    localparam [N-1:0] POSIT_NEG2 = 8'b10110000;
    localparam [N-1:0] POSIT_NAR  = 8'b10000000;

    posit_maxpool2d #(
        .N(N),
        .CHANNELS(CHANNELS),
        .HEIGHT(HEIGHT),
        .WIDTH(WIDTH),
        .POOL_SIZE(POOL_SIZE),
        .STRIDE(STRIDE)
    ) DUT (
        .feature_in (feature_in),
        .pool_out   (pool_out)
    );

    task set_value;
        input integer c;
        input integer iy;
        input integer ix;
        input [N-1:0] value;
        integer idx;
        begin
            idx = ((c * HEIGHT * WIDTH + iy * WIDTH + ix) * N);
            feature_in[idx +: N] = value;
        end
    endtask

    task check_value;
        input integer c;
        input integer oy;
        input integer ox;
        input [N-1:0] expected;
        input [8*64-1:0] name;
        integer idx;
        begin
            idx = ((c * OUT_H * OUT_W + oy * OUT_W + ox) * N);
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
        feature_in = {CHANNELS*HEIGHT*WIDTH*N{1'b0}};

        // Fill both channels with zero. The final row/column should be ignored
        // by 2x2 stride-2 pooling, producing a 3x3 output.
        for (y = 0; y < HEIGHT; y = y + 1) begin
            for (x = 0; x < WIDTH; x = x + 1) begin
                set_value(0, y, x, POSIT_ZERO);
                set_value(1, y, x, POSIT_ZERO);
            end
        end

        // Output (0,0), input rows 0..1 cols 0..1 -> max 2
        set_value(0, 0, 0, POSIT_HALF);
        set_value(0, 0, 1, POSIT_ONE);
        set_value(0, 1, 0, POSIT_TWO);
        set_value(0, 1, 1, POSIT_HALF);

        // Output (1,1), input rows 2..3 cols 2..3 -> max 4
        set_value(0, 2, 2, POSIT_ONE);
        set_value(0, 2, 3, POSIT_FOUR);
        set_value(0, 3, 2, POSIT_TWO);
        set_value(0, 3, 3, POSIT_HALF);

        // Output (2,2), input rows 4..5 cols 4..5 -> NaR propagates
        set_value(0, 4, 4, POSIT_ONE);
        set_value(0, 4, 5, POSIT_NAR);
        set_value(0, 5, 4, POSIT_TWO);
        set_value(0, 5, 5, POSIT_ZERO);

        // Ignored by 7x7 -> 3x3 pooling.
        set_value(0, 6, 6, POSIT_FOUR);

        // Channel 1 checks channel-major addressing and signed posit ordering.
        // Output (0,0), input rows 0..1 cols 0..1 -> max -1
        set_value(1, 0, 0, POSIT_NEG2);
        set_value(1, 0, 1, POSIT_NEG1);
        set_value(1, 1, 0, POSIT_NEG2);
        set_value(1, 1, 1, POSIT_NEG1);

        // Output (0,1), input rows 0..1 cols 2..3 -> max 1
        set_value(1, 0, 2, POSIT_NEG1);
        set_value(1, 0, 3, POSIT_ONE);
        set_value(1, 1, 2, POSIT_ZERO);
        set_value(1, 1, 3, POSIT_HALF);

        #10;

        check_value(0, 0, 0, POSIT_TWO,  "7x7 pool output 0,0");
        check_value(0, 1, 1, POSIT_FOUR, "7x7 pool output 1,1");
        check_value(0, 2, 2, POSIT_NAR,  "7x7 pool output 2,2 NaR");
        check_value(0, 0, 2, POSIT_ZERO, "ignored last column does not affect output");
        check_value(1, 0, 0, POSIT_NEG1, "channel1 negative max ordering");
        check_value(1, 0, 1, POSIT_ONE,  "channel1 independent channel-major pool");

        if (OUT_H != 3 || OUT_W != 3) begin
            $display("FAIL output dimensions expected 3x3 got %0dx%0d", OUT_H, OUT_W);
            errors = errors + 1;
        end
        else begin
            $display("PASS output dimensions are 3x3");
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);

        $finish;
    end

endmodule
