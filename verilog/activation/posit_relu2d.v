`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: posit_relu2d
// Description:
//   Parametric ReLU for a flattened C x H x W posit feature map.
//
//   Tensor layout:
//     data_in[((c*HEIGHT*WIDTH + y*WIDTH + x)*N) +: N]
//
//   ReLU behavior:
//     positive/zero finite values pass through
//     negative finite values clamp to zero
//     NaR propagates unchanged
//////////////////////////////////////////////////////////////////////////////////

module posit_relu2d #(
    parameter N = 8,
    parameter CHANNELS = 1,
    parameter HEIGHT = 28,
    parameter WIDTH = 28,
    parameter NUM_VALUES = CHANNELS * HEIGHT * WIDTH
)(
    input  wire [NUM_VALUES*N-1:0] data_in,
    output wire [NUM_VALUES*N-1:0] data_out
);

    localparam [N-1:0] POSIT_ZERO = {N{1'b0}};
    localparam [N-1:0] POSIT_NAR  = {1'b1, {(N-1){1'b0}}};

    genvar i;

    generate
        for (i = 0; i < NUM_VALUES; i = i + 1) begin : RELU_GEN
            wire [N-1:0] value;

            assign value = data_in[i*N +: N];

            assign data_out[i*N +: N] =
                (value == POSIT_NAR) ? POSIT_NAR :
                (value[N-1])         ? POSIT_ZERO :
                                       value;
        end
    endgenerate

endmodule
