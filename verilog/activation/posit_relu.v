`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: posit_relu
// Description:
//   Parametric ReLU layer for flattened posit tensors.
//
//   Input/output layout:
//     data_in[(i*N) +: N]  = value i
//     data_out[(i*N) +: N] = max(value i, 0)
//
//   NaR is propagated unchanged.
//////////////////////////////////////////////////////////////////////////////////

module posit_relu #(
    parameter N = 8,
    parameter NUM_VALUES = 1
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
