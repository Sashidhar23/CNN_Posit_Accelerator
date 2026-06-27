
//////////////////////////////////////////////////////////////////////////////////
// Module Name: pe_quire
// Description:
//   Processing element using posit_quire_mac.
//
//   Control and data movement match pe.v:
//     - pe_en captures/forwards activation and enables accumulation
//     - wshift loads the stationary weight
//     - clear_acc clears the accumulator
//
//   The MAC accumulation is held in a wide quire and rounded to posit at pe_output.
//////////////////////////////////////////////////////////////////////////////////

module pe_quire #(
    parameter N  = 8,
    parameter ES = 1,
    parameter QW = 128,
    parameter QF = QW / 2
)(
    input  wire                 clk,
    input  wire                 reset,

    // Main PE control
    input  wire                 pe_en,
    input  wire                 clear_acc,

    // Weight loading control
    input  wire                 wshift,

    // Data inputs
    input  wire [N-1:0]         input_in,
    input  wire [N-1:0]         weight_in,

    // Data outputs
    output wire [N-1:0]         input_out,
    output wire [N-1:0]         weight_out,
    output wire signed [QW-1:0] quire_out,
    output wire                 is_nar,
    output wire [N-1:0]         pe_output
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
    // Posit quire MAC core
    //
    // quire <= quire + input_reg * weight_reg
    //--------------------------------------------------
    posit_quire_mac #(
        .N(N),
        .ES(ES),
        .QW(QW),
        .QF(QF)
    ) QUIRE_MAC_CORE (
        .clk       (clk),
        .reset     (reset),
        .clear     (clear_acc),
        .enable    (pe_en),
        .posit_a   (input_reg),
        .posit_b   (weight_reg),
        .quire_out (quire_out),
        .posit_out (pe_output),
        .is_nar    (is_nar)
    );

    //--------------------------------------------------
    // Forwarded outputs
    //--------------------------------------------------
    assign input_out  = input_reg;
    assign weight_out = weight_reg;

endmodule
