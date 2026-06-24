`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2026 14:31:02
// Design Name: 
// Module Name: posit_mac
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module posit_mac #(
    parameter N  = 8,
    parameter ES = 1
)(
    input  wire             clk,
    input  wire             reset,
    input  wire             enable,
    input  wire             clear,

    input  wire [N-1:0]     a,
    input  wire [N-1:0]     b,

    output wire [N-1:0]     product,
    output wire [N-1:0]     mac_out,
    output reg  [N-1:0]     acc
);

    //--------------------------------------------------
    // product = a * b
    //--------------------------------------------------
    posit_multiplier #(
        .N(N),
        .ES(ES)
    ) MUL (
        .posit_a   (a),
        .posit_b   (b),
        .posit_out (product)
    );

    //--------------------------------------------------
    // mac_out = acc + product
    //--------------------------------------------------
    posit_adder #(
        .N(N),
        .ES(ES)
    ) ADD (
        .posit_a   (product),
        .posit_b   (acc),
        .posit_out (mac_out)
    );

    //--------------------------------------------------
    // Accumulator register
    //--------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            acc <= {N{1'b0}};
        end
        else if (clear) begin
            acc <= {N{1'b0}};
        end
        else if (enable) begin
            acc <= mac_out;
        end
    end

endmodule
