`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: posit_maxpool2d
// Description:
//   Parametric 2D max-pooling for flattened C x H x W posit feature maps.
//
//   This is intended to match PyTorch nn.MaxPool2d(2) for the VGG16_MNIST
//   feature blocks when POOL_SIZE=2 and STRIDE=2.
//
//   Input tensor layout:
//     feature_in[((c*HEIGHT*WIDTH + y*WIDTH + x)*N) +: N]
//
//   Output tensor layout:
//     pool_out[((c*OUT_H*OUT_W + oy*OUT_W + ox)*N) +: N]
//
//   Default output size uses floor division:
//     OUT_H = ((HEIGHT - POOL_SIZE) / STRIDE) + 1
//     OUT_W = ((WIDTH  - POOL_SIZE) / STRIDE) + 1
//
//   For your MNIST VGG path with MaxPool2d(2):
//     28x28 -> 14x14
//     14x14 -> 7x7
//      7x7  -> 3x3
//      3x3  -> 1x1
//
//   NaR handling:
//     If any value in a pooling window is NaR, output is NaR.
//////////////////////////////////////////////////////////////////////////////////

module posit_maxpool2d #(
    parameter N = 8,
    parameter CHANNELS = 1,
    parameter HEIGHT = 28,
    parameter WIDTH = 28,
    parameter POOL_SIZE = 2,
    parameter STRIDE = 2,
    parameter OUT_H = ((HEIGHT - POOL_SIZE) / STRIDE) + 1,
    parameter OUT_W = ((WIDTH  - POOL_SIZE) / STRIDE) + 1
)(
    input  wire [CHANNELS*HEIGHT*WIDTH*N-1:0] feature_in,
    output reg  [CHANNELS*OUT_H*OUT_W*N-1:0]  pool_out
);

    localparam [N-1:0] POSIT_NAR = {1'b1, {(N-1){1'b0}}};

    integer c;
    integer oy;
    integer ox;
    integer ky;
    integer kx;
    integer in_y;
    integer in_x;
    integer in_index;
    integer out_index;
    integer elem_count;

    reg [N-1:0] current_value;
    reg [N-1:0] max_value;
    reg         has_nar;

    // For finite posit values, signed integer ordering follows numeric order.
    // NaR is handled before comparison.
    function [0:0] is_greater_posit;
        input [N-1:0] a;
        input [N-1:0] b;
        begin
            is_greater_posit = ($signed(a) > $signed(b));
        end
    endfunction

    always @(*) begin
        pool_out = {CHANNELS*OUT_H*OUT_W*N{1'b0}};

        for (c = 0; c < CHANNELS; c = c + 1) begin
            for (oy = 0; oy < OUT_H; oy = oy + 1) begin
                for (ox = 0; ox < OUT_W; ox = ox + 1) begin
                    max_value = {N{1'b0}};
                    has_nar = 1'b0;
                    elem_count = 0;

                    for (ky = 0; ky < POOL_SIZE; ky = ky + 1) begin
                        for (kx = 0; kx < POOL_SIZE; kx = kx + 1) begin
                            in_y = oy * STRIDE + ky;
                            in_x = ox * STRIDE + kx;
                            in_index = ((c * HEIGHT * WIDTH + in_y * WIDTH + in_x) * N);
                            current_value = feature_in[in_index +: N];

                            if (current_value == POSIT_NAR) begin
                                has_nar = 1'b1;
                            end
                            else if (elem_count == 0) begin
                                max_value = current_value;
                            end
                            else if (is_greater_posit(current_value, max_value)) begin
                                max_value = current_value;
                            end

                            elem_count = elem_count + 1;
                        end
                    end

                    out_index = ((c * OUT_H * OUT_W + oy * OUT_W + ox) * N);
                    pool_out[out_index +: N] = has_nar ? POSIT_NAR : max_value;
                end
            end
        end
    end

endmodule
