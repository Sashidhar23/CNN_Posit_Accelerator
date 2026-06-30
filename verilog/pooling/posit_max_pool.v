`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: posit_max_pool
// Description:
//   Parametric max-pooling layer for flattened posit tensors.
//
//   This block expects the CNN/window-control layer to provide each pooling
//   window already flattened. It computes one max value per channel per window.
//
//   Input layout:
//     window_in[(((w*CHANNELS + c)*WINDOW_ELEMS + e)*N) +: N]
//
//   Output layout:
//     pool_out[((w*CHANNELS + c)*N) +: N]
//
//   where:
//     w = output pooling-window index
//     c = channel index
//     e = element index inside POOL_SIZE x POOL_SIZE window
//
//   NaR handling:
//     If any value in a pooling window is NaR, the pooled output is NaR.
//////////////////////////////////////////////////////////////////////////////////

module posit_max_pool #(
    parameter N = 8,
    parameter CHANNELS = 1,
    parameter NUM_WINDOWS = 1,
    parameter POOL_SIZE = 2,
    parameter WINDOW_ELEMS = POOL_SIZE * POOL_SIZE
)(
    input  wire [NUM_WINDOWS*CHANNELS*WINDOW_ELEMS*N-1:0] window_in,
    output reg  [NUM_WINDOWS*CHANNELS*N-1:0]              pool_out
);

    localparam [N-1:0] POSIT_ZERO = {N{1'b0}};
    localparam [N-1:0] POSIT_NAR  = {1'b1, {(N-1){1'b0}}};

    integer w;
    integer c;
    integer e;
    integer in_index;
    integer out_index;

    reg [N-1:0] current_value;
    reg [N-1:0] max_value;
    reg         has_nar;

    // For standard posit encodings, signed integer ordering matches numeric
    // ordering for every finite value. NaR is handled separately above.
    function is_greater_posit;
        input [N-1:0] a;
        input [N-1:0] b;
        begin
            is_greater_posit = ($signed(a) > $signed(b));
        end
    endfunction

    always @(*) begin
        pool_out = {NUM_WINDOWS*CHANNELS*N{1'b0}};

        for (w = 0; w < NUM_WINDOWS; w = w + 1) begin
            for (c = 0; c < CHANNELS; c = c + 1) begin
                max_value = POSIT_ZERO;
                has_nar = 1'b0;

                for (e = 0; e < WINDOW_ELEMS; e = e + 1) begin
                    in_index = (((w * CHANNELS + c) * WINDOW_ELEMS + e) * N);
                    current_value = window_in[in_index +: N];

                    if (current_value == POSIT_NAR) begin
                        has_nar = 1'b1;
                    end
                    else if (e == 0) begin
                        max_value = current_value;
                    end
                    else if (is_greater_posit(current_value, max_value)) begin
                        max_value = current_value;
                    end
                end

                out_index = ((w * CHANNELS + c) * N);
                pool_out[out_index +: N] = has_nar ? POSIT_NAR : max_value;
            end
        end
    end

endmodule
