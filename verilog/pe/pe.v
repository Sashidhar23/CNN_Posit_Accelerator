
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

    // Data outputs
    output wire [N-1:0]     input_out,   // activation forwarded to right PE
    output wire [N-1:0]     weight_out,  // weight forwarded / observable
    output wire [N-1:0]     product_out, // current product
    output wire [N-1:0]     mac_out,     // combinational acc + product
    output wire [N-1:0]     pe_output    // accumulated PE output
);

    //--------------------------------------------------
    // Internal registers
    //--------------------------------------------------
    reg [N-1:0] input_reg;
    reg [N-1:0] weight_reg;

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
    // Posit MAC core
    //
    // acc <= acc + input_reg * weight_reg
    //--------------------------------------------------
    posit_mac #(
        .N(N),
        .ES(ES)
    ) MAC_CORE (
        .clk      (clk),
        .reset    (reset),
        .enable   (pe_en),
        .clear    (clear_acc),

        .a        (input_reg),
        .b        (weight_reg),

        .product  (product_out),
        .mac_out  (mac_out),
        .acc      (pe_output)
    );

    //--------------------------------------------------
    // Forwarded outputs
    //--------------------------------------------------
    assign input_out  = input_reg;
    assign weight_out = weight_reg;

endmodule
