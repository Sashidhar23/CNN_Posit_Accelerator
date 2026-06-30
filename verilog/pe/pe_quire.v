
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
    reg [PROD_W-1:0] product_mag;
    reg signed [SCALE_W-1:0] scale_a;
    reg signed [SCALE_W-1:0] scale_b;
    reg signed [SCALE_W-1:0] product_scale;
    integer quire_shift;
    reg [QW-1:0] aligned_product;
    reg signed [QW-1:0] product_term;

    always @(*) begin
        mant_a = {1'b1, frac_a};
        mant_b = {1'b1, frac_b};
        product_mag = mant_a * mant_b;

        scale_a = (k_a <<< ES) + $signed({1'b0, exp_a});
        scale_b = (k_b <<< ES) + $signed({1'b0, exp_b});
        product_scale = scale_a + scale_b;

        quire_shift = product_scale + QF - (2*N);
        aligned_product = {QW{1'b0}};

        if (zero_a || zero_b || nar_a || nar_b) begin
            product_term = {QW{1'b0}};
        end
        else begin
            if (quire_shift >= 0) begin
                if (quire_shift >= QW)
                    aligned_product = {QW{1'b0}};
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
            psum_out_reg  <= psum_pipe_reg + product_reg;
            nar_out_reg   <= nar_pipe_reg;
        end
    end

    //--------------------------------------------------
    // Quire-to-posit conversion for observable PE output
    //--------------------------------------------------
    reg enc_sign;
    reg enc_zero;
    reg enc_nar;
    reg signed [$clog2(N):0] enc_k;
    reg [ES-1:0] enc_exp;
    reg [N-1:0] enc_frac;
    reg [$clog2(N):0] enc_flen;

    posit_encoder #(.N(N), .ES(ES)) ENC (
        .sign      (enc_sign),
        .is_zero   (enc_zero),
        .is_nar    (enc_nar),
        .k         (enc_k),
        .exponent  (enc_exp),
        .fraction  (enc_frac),
        .frac_len  (enc_flen),
        .posit_out (pe_output)
    );

    reg [QW-1:0] abs_quire;
    reg [QW-1:0] norm_quire;
    reg signed [SCALE_W-1:0] result_scale;
    integer lead_pos;
    integer norm_shift;
    integer k_int;
    integer e_int;
    integer i;

    function integer highest_one_pos;
        input [QW-1:0] value;
        integer j;
        begin
            highest_one_pos = -1;
            for (j = 0; j < QW; j = j + 1) begin
                if (value[j])
                    highest_one_pos = j;
            end
        end
    endfunction

    always @(*) begin
        enc_sign = 1'b0;
        enc_zero = 1'b0;
        enc_nar  = nar_out_reg;
        enc_k    = 0;
        enc_exp  = 0;
        enc_frac = 0;
        enc_flen = 0;

        abs_quire = 0;
        norm_quire = 0;
        result_scale = 0;
        lead_pos = -1;
        norm_shift = 0;
        k_int = 0;
        e_int = 0;

        if (!nar_out_reg) begin
            if (psum_out_reg == 0) begin
                enc_zero = 1'b1;
            end
            else begin
                enc_sign = psum_out_reg[QW-1];
                abs_quire = enc_sign ? -psum_out_reg : psum_out_reg;

                lead_pos = highest_one_pos(abs_quire);
                result_scale = lead_pos - QF;

                norm_shift = N - lead_pos;
                if (norm_shift >= 0)
                    norm_quire = abs_quire << norm_shift;
                else
                    norm_quire = abs_quire >> (-norm_shift);

                if (ES == 0) begin
                    k_int = result_scale;
                    e_int = 0;
                end
                else begin
                    k_int = result_scale >>> ES;
                    e_int = result_scale - (k_int <<< ES);
                end

                if (k_int > (N-2))
                    k_int = N-2;
                else if (k_int < -(N-2))
                    k_int = -(N-2);

                enc_k = k_int[$clog2(N):0];
                enc_exp = e_int[ES-1:0];
                enc_frac = norm_quire[N-1:0];

                for (i = 0; i < N; i = i + 1) begin
                    if (enc_frac[N-1-i])
                        enc_flen = i + 1;
                end
            end
        end
    end

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
