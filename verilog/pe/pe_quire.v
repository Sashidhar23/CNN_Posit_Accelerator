`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: pe_quire
// Description:
//   Processing element with a local quire accumulation path.
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
    parameter QW = 48,
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
    input  wire signed [QW-1:0] psum_in,
    input  wire                 psum_nar_in,

    // Data outputs
    output wire [N-1:0]         input_out,
    output wire [N-1:0]         weight_out,
    output wire signed [QW-1:0] quire_out,
    output wire                 is_nar,
    output wire signed [QW-1:0] psum_out,
    output wire                 psum_nar_out,
    output wire [N-1:0]         pe_output
);

    //--------------------------------------------------
    // Internal registers
    //--------------------------------------------------
    reg [N-1:0] input_reg;
    reg [N-1:0] weight_reg;
    reg signed [QW-1:0] product_reg;
    reg signed [QW-1:0] psum_pipe_reg;
    reg                 nar_pipe_reg;
    reg signed [QW-1:0] psum_out_reg;
    reg                 nar_out_reg;

    //--------------------------------------------------
    // Input activation register
    // This forwards activation horizontally across row
    //--------------------------------------------------
    always @(posedge clk) begin
        if (reset || clear_acc) begin
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
    // Product-to-quire conversion
    //--------------------------------------------------
    localparam integer SCALE_W = $clog2(N) + ES + 4;
    localparam integer PROD_W  = 2*N + 2;

    wire sign_a, sign_b;
    wire zero_a, zero_b;
    wire nar_a, nar_b;
    wire signed [$clog2(N):0] k_a, k_b;
    wire [ES-1:0] exp_a, exp_b;
    wire [N-1:0] frac_a, frac_b;
    wire [$clog2(N):0] flen_a, flen_b;

    posit_decoder #(.N(N), .ES(ES)) DEC_A (
        .posit_in (input_reg),
        .sign     (sign_a),
        .is_zero  (zero_a),
        .is_nar   (nar_a),
        .k        (k_a),
        .exponent (exp_a),
        .fraction (frac_a),
        .frac_len (flen_a)
    );

    posit_decoder #(.N(N), .ES(ES)) DEC_B (
        .posit_in (weight_reg),
        .sign     (sign_b),
        .is_zero  (zero_b),
        .is_nar   (nar_b),
        .k        (k_b),
        .exponent (exp_b),
        .fraction (frac_b),
        .frac_len (flen_b)
    );

    reg [N:0] mant_a;
    reg [N:0] mant_b;
    (* use_dsp = "yes" *) reg [PROD_W-1:0] product_mag;
    reg signed [SCALE_W-1:0] scale_a;
    reg signed [SCALE_W-1:0] scale_b;
    reg signed [SCALE_W-1:0] product_scale;
    integer quire_shift;
    integer product_lead;
    reg [QW-1:0] aligned_product;
    reg signed [QW-1:0] product_term;

    function integer product_highest_one;
        input [PROD_W-1:0] value;
        integer j;
        begin
            product_highest_one = -1;
            for (j = 0; j < PROD_W; j = j + 1) begin
                if (value[j])
                    product_highest_one = j;
            end
        end
    endfunction

    always @(*) begin
        mant_a = {1'b1, frac_a};
        mant_b = {1'b1, frac_b};
        product_mag = mant_a * mant_b;

        scale_a = ($signed(k_a) * (1 << ES)) + $signed({1'b0, exp_a});
        scale_b = ($signed(k_b) * (1 << ES)) + $signed({1'b0, exp_b});
        product_scale = scale_a + scale_b;

        quire_shift = product_scale + QF - (2*N);
        product_lead = product_highest_one(product_mag);
        aligned_product = {QW{1'b0}};

        if (zero_a || zero_b || nar_a || nar_b) begin
            product_term = {QW{1'b0}};
        end
        else begin
            if (quire_shift >= 0) begin
                if ((product_lead + quire_shift) >= (QW-1))
                    aligned_product = {1'b0, {(QW-1){1'b1}}};
                else
                    aligned_product = {{(QW-PROD_W){1'b0}}, product_mag} << quire_shift;
            end
            else begin
                if ((-quire_shift) >= PROD_W)
                    aligned_product = {QW{1'b0}};
                else
                    aligned_product = {{(QW-PROD_W){1'b0}}, product_mag} >> (-quire_shift);
            end

            product_term = (sign_a ^ sign_b) ? -$signed(aligned_product)
                                             :  $signed(aligned_product);
        end
    end

    (* use_dsp = "yes" *) wire signed [QW-1:0] psum_sum_comb;

    assign psum_sum_comb = psum_pipe_reg + product_reg;

    always @(posedge clk) begin
        if (reset || clear_acc) begin
            product_reg   <= {QW{1'b0}};
            psum_pipe_reg <= {QW{1'b0}};
            nar_pipe_reg  <= 1'b0;
            psum_out_reg  <= {QW{1'b0}};
            nar_out_reg   <= 1'b0;
        end
        else if (pe_en) begin
            product_reg   <= product_term;
            psum_pipe_reg <= psum_in;
            nar_pipe_reg  <= psum_nar_in | nar_a | nar_b;
            psum_out_reg  <= psum_sum_comb;
            nar_out_reg   <= nar_pipe_reg;
        end
    end

    quire_to_posit #(
        .N(N), .ES(ES), .QW(QW), .QF(QF)
    ) OBSERVABLE_OUTPUT (
        .quire_in(psum_out_reg),
        .is_nar(nar_out_reg),
        .posit_out(pe_output)
    );

    //--------------------------------------------------
    // Forwarded outputs
    //--------------------------------------------------
    assign input_out  = input_reg;
    assign weight_out = weight_reg;
    assign quire_out = psum_out_reg;
    assign is_nar = nar_out_reg;
    assign psum_out = psum_out_reg;
    assign psum_nar_out = nar_out_reg;

endmodule
