`timescale 1ns / 1ps

module posit_adder #(
    parameter N = 8,
    parameter ES = 1
)(
    input  wire [N-1:0] posit_a,
    input  wire [N-1:0] posit_b,
    output wire [N-1:0] posit_out
);

    localparam integer MAX_SCALE = (N-2) * (1 << ES);
    localparam integer EXACT_W = (2*MAX_SCALE) + N + 3;
    localparam integer SCALE_W = $clog2((4*MAX_SCALE) + (4*N) + 16) + 1;

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

    reg signed [SCALE_W-1:0] scale_a;
    reg signed [SCALE_W-1:0] scale_b;
    reg [EXACT_W-1:0] magnitude_a;
    reg [EXACT_W-1:0] magnitude_b;
    reg signed [EXACT_W-1:0] operand_a;
    reg signed [EXACT_W-1:0] operand_b;
    (* use_dsp = "yes" *) reg signed [EXACT_W-1:0] exact_sum;
    reg [EXACT_W-1:0] absolute_sum;
    reg [EXACT_W-1:0] normalized_sum;
    reg result_sign;
    reg result_zero;
    reg signed [SCALE_W-1:0] result_scale;
    integer shift_a;
    integer shift_b;
    integer leading_position;
    integer i;

    always @(*) begin
        scale_a = (k_a <<< ES) + $signed({1'b0, exponent_a});
        scale_b = (k_b <<< ES) + $signed({1'b0, exponent_b});
        shift_a = scale_a + MAX_SCALE;
        shift_b = scale_b + MAX_SCALE;

        magnitude_a = {EXACT_W{1'b0}};
        magnitude_b = {EXACT_W{1'b0}};
        if (!zero_a && !nar_a)
            magnitude_a = {{(EXACT_W-(N+1)){1'b0}}, 1'b1, fraction_a} << shift_a;
        if (!zero_b && !nar_b)
            magnitude_b = {{(EXACT_W-(N+1)){1'b0}}, 1'b1, fraction_b} << shift_b;

        operand_a = sign_a ? -$signed(magnitude_a) : $signed(magnitude_a);
        operand_b = sign_b ? -$signed(magnitude_b) : $signed(magnitude_b);
        exact_sum = operand_a + operand_b;
        result_sign = exact_sum[EXACT_W-1];
        absolute_sum = result_sign ? -exact_sum : exact_sum;
        result_zero = (exact_sum == 0);
        leading_position = -1;
        for (i = 0; i < EXACT_W; i = i + 1) begin
            if (absolute_sum[i])
                leading_position = i;
        end

        normalized_sum = {EXACT_W{1'b0}};
        result_scale = {SCALE_W{1'b0}};
        if (leading_position >= 0) begin
            normalized_sum = absolute_sum << (EXACT_W-1-leading_position);
            result_scale = leading_position - (N + MAX_SCALE);
        end
    end

    posit_round_pack #(
        .N(N), .ES(ES), .SIG_W(EXACT_W), .SCALE_W(SCALE_W)
    ) PACK (
        .sign(result_sign),
        .is_zero(result_zero),
        .is_nar(nar_a || nar_b),
        .scale(result_scale),
        .normalized_significand(normalized_sum),
        .posit_out(posit_out)
    );

endmodule
