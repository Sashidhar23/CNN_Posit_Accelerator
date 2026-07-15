`timescale 1ns / 1ps

module posit_multiplier #(
    parameter N = 8,
    parameter ES = 1
)(
    input  wire [N-1:0] posit_a,
    input  wire [N-1:0] posit_b,
    output wire [N-1:0] posit_out
);

    localparam integer MANT_W = N + 1;
    localparam integer PROD_W = 2 * MANT_W;
    localparam integer SCALE_W = $clog2((8*N*(1 << ES)) + 16) + 1;
    localparam integer DSP_MANT_W = (MANT_W < 18) ? 18 : MANT_W;

    wire sign_a;
    wire zero_a;
    wire nar_a;
    wire signed [$clog2(N):0] k_a;
    wire [ES-1:0] exponent_a;
    wire [N-1:0] fraction_a;
    wire [$clog2(N):0] frac_len_a;

    wire sign_b;
    wire zero_b;
    wire nar_b;
    wire signed [$clog2(N):0] k_b;
    wire [ES-1:0] exponent_b;
    wire [N-1:0] fraction_b;
    wire [$clog2(N):0] frac_len_b;

    posit_decoder #(.N(N), .ES(ES)) DEC_A (
        .posit_in(posit_a), .sign(sign_a), .is_zero(zero_a), .is_nar(nar_a),
        .k(k_a), .exponent(exponent_a), .fraction(fraction_a),
        .frac_len(frac_len_a)
    );

    posit_decoder #(.N(N), .ES(ES)) DEC_B (
        .posit_in(posit_b), .sign(sign_b), .is_zero(zero_b), .is_nar(nar_b),
        .k(k_b), .exponent(exponent_b), .fraction(fraction_b),
        .frac_len(frac_len_b)
    );

    wire [MANT_W-1:0] mantissa_a = {1'b1, fraction_a};
    wire [MANT_W-1:0] mantissa_b = {1'b1, fraction_b};
    wire [DSP_MANT_W-1:0] dsp_mantissa_a =
        {{(DSP_MANT_W-MANT_W){1'b0}}, mantissa_a};
    wire [DSP_MANT_W-1:0] dsp_mantissa_b =
        {{(DSP_MANT_W-MANT_W){1'b0}}, mantissa_b};
    (* use_dsp = "yes" *) wire [(2*DSP_MANT_W)-1:0] dsp_product =
        dsp_mantissa_a * dsp_mantissa_b;

    reg [PROD_W-1:0] exact_product;
    reg [PROD_W-1:0] normalized_product;
    reg signed [SCALE_W-1:0] result_scale;

    always @(*) begin
        exact_product = dsp_product[PROD_W-1:0];
        result_scale = (k_a <<< ES) + $signed({1'b0, exponent_a}) +
                       (k_b <<< ES) + $signed({1'b0, exponent_b});

        if (exact_product[PROD_W-1]) begin
            normalized_product = exact_product;
            result_scale = result_scale + 1'b1;
        end
        else begin
            normalized_product = exact_product << 1;
        end
    end

    posit_round_pack #(
        .N(N), .ES(ES), .SIG_W(PROD_W), .SCALE_W(SCALE_W)
    ) PACK (
        .sign(sign_a ^ sign_b),
        .is_zero(zero_a || zero_b),
        .is_nar(nar_a || nar_b),
        .scale(result_scale),
        .normalized_significand(normalized_product),
        .posit_out(posit_out)
    );

endmodule
