
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2026 17:41:38
// Design Name: 
// Module Name: pe
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


module pe #(
    parameter N  = 8,
    parameter ES = 1
)(
    input  wire             clk,
    input  wire             reset,

    // Main PE control
    input  wire             pe_en,       // enables activation movement + MAC accumulation
    input  wire             clear_acc,   // clears MAC accumulator

    // Weight loading control
    input  wire             wshift,      // load/shift weight into this PE

    // Data inputs
    input  wire [N-1:0]     input_in,    // activation input from left
    input  wire [N-1:0]     weight_in,   // weight input during loading phase
    input  wire [N-1:0]     psum_in,     // partial sum input from PE above

    // Data outputs
    output wire [N-1:0]     input_out,   // activation forwarded to right PE
    output wire [N-1:0]     weight_out,  // weight forwarded / observable
    output wire [N-1:0]     product_out, // current product
    output wire [N-1:0]     mac_out,     // current psum_in + registered product
    output wire [N-1:0]     psum_out,    // partial sum forwarded to PE below
    output wire [N-1:0]     pe_output    // observable PE partial sum output
);

    //--------------------------------------------------
    // Internal registers
    //--------------------------------------------------
    reg [N-1:0] input_reg;
    reg [N-1:0] weight_reg;
    reg [N-1:0] product_reg;
    reg [N-1:0] psum_pipe_reg;
    reg [N-1:0] psum_out_reg;

    wire [N-1:0] product_comb;
    wire [N-1:0] psum_comb;

    //--------------------------------------------------
    // Input activation register
    // This forwards activation horizontally across row
    //--------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            input_reg <= {N{1'b0}};
        end
        else if (pe_en) begin
            input_reg <= input_in;
        end
    end

    //--------------------------------------------------
    // Weight register
    // Weight-stationary storage
    //--------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            weight_reg <= {N{1'b0}};
        end
        else if (wshift) begin
            weight_reg <= weight_in;
        end
    end

    //--------------------------------------------------
    // Two-stage WS MAC datapath.
    //
    // Stage 1 registers product and matching incoming psum.
    // Stage 2 registers product + psum and forwards it downward.
    //--------------------------------------------------
    posit_multiplier #(
        .N(N),
        .ES(ES)
    ) MUL (
        .posit_a   (input_reg),
        .posit_b   (weight_reg),
        .posit_out (product_comb)
    );

    posit_adder #(
        .N(N),
        .ES(ES)
    ) ADD (
        .posit_a   (product_reg),
        .posit_b   (psum_pipe_reg),
        .posit_out (psum_comb)
    );

    always @(posedge clk) begin
        if (reset || clear_acc) begin
            product_reg   <= {N{1'b0}};
            psum_pipe_reg <= {N{1'b0}};
            psum_out_reg  <= {N{1'b0}};
        end
        else if (pe_en) begin
            product_reg   <= product_comb;
            psum_pipe_reg <= psum_in;
            psum_out_reg  <= psum_comb;
        end
    end

    //--------------------------------------------------
    // Forwarded outputs
    //--------------------------------------------------
    assign input_out  = input_reg;
    assign weight_out = weight_reg;
    assign product_out = product_reg;
    assign mac_out = psum_comb;
    assign psum_out = psum_out_reg;
    assign pe_output = psum_out_reg;

endmodule
