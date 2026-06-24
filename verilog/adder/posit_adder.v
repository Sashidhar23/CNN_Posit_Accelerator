`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 23:17:31
// Design Name: 
// Module Name: posit_adder
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


module posit_adder #(
    parameter N  = 8,
    parameter ES = 1
)(
    input  wire [N-1:0] posit_a,
    input  wire [N-1:0] posit_b,
    output wire [N-1:0] posit_out
);

    // --------------------------------------------------
    // Decoder outputs
    // --------------------------------------------------
    wire sign_a, sign_b;
    wire is_zero_a, is_zero_b;
    wire is_nar_a,  is_nar_b;

    wire signed [$clog2(N):0] k_a, k_b;
    wire [ES-1:0] exponent_a, exponent_b;

    wire [N-1:0] fraction_a, fraction_b;
    wire [$clog2(N):0] frac_len_a, frac_len_b;

    // --------------------------------------------------
    // Encoder inputs
    // --------------------------------------------------
    reg enc_sign;
    reg enc_is_zero;
    reg enc_is_nar;
    reg signed [$clog2(N):0] enc_k;
    reg [ES-1:0] enc_exponent;
    reg [N-1:0] enc_fraction;
    reg [$clog2(N):0] enc_frac_len;

    // --------------------------------------------------
    // Internal arithmetic widths
    // --------------------------------------------------
    localparam integer SIG_W   = N + 1;          // hidden 1 + N fraction bits
    localparam integer WORK_W  = (4*N) + 16;     // enough headroom for add/normalize
    localparam integer SCALE_W = $clog2(N) + ES + 4;

    // --------------------------------------------------
    // Decoder instances
    // --------------------------------------------------
    posit_decoder #(
        .N(N),
        .ES(ES)
    ) DEC_A (
        .posit_in (posit_a),
        .sign     (sign_a),
        .is_zero   (is_zero_a),
        .is_nar    (is_nar_a),
        .k         (k_a),
        .exponent  (exponent_a),
        .fraction  (fraction_a),
        .frac_len  (frac_len_a)
    );

    posit_decoder #(
        .N(N),
        .ES(ES)
    ) DEC_B (
        .posit_in (posit_b),
        .sign     (sign_b),
        .is_zero   (is_zero_b),
        .is_nar    (is_nar_b),
        .k         (k_b),
        .exponent  (exponent_b),
        .fraction  (fraction_b),
        .frac_len  (frac_len_b)
    );

    // --------------------------------------------------
    // Encoder instance
    // --------------------------------------------------
    posit_encoder #(
        .N(N),
        .ES(ES)
    ) ENC (
        .sign     (enc_sign),
        .is_zero   (enc_is_zero),
        .is_nar    (enc_is_nar),
        .k         (enc_k),
        .exponent  (enc_exponent),
        .fraction  (enc_fraction),
        .frac_len  (enc_frac_len),
        .posit_out (posit_out)
    );

    // --------------------------------------------------
    // Working registers
    // --------------------------------------------------
    reg signed [SCALE_W-1:0] scale_a;
    reg signed [SCALE_W-1:0] scale_b;
    reg signed [SCALE_W-1:0] common_scale;
    reg signed [SCALE_W-1:0] result_scale;

    reg [SIG_W-1:0] sig_a;
    reg [SIG_W-1:0] sig_b;

    reg [WORK_W-1:0] aligned_a;
    reg [WORK_W-1:0] aligned_b;

    reg signed [WORK_W-1:0] signed_a;
    reg signed [WORK_W-1:0] signed_b;
    reg signed [WORK_W-1:0] sum_signed;

    reg [WORK_W-1:0] abs_sum;
    reg [WORK_W-1:0] norm_sum;

    integer shift_a;
    integer shift_b;
    integer norm_shift;
    integer lead_pos;
    integer i;
    integer last_one;

    // --------------------------------------------------
    // Helper function: highest set bit position
    // Returns -1 if value is zero
    // --------------------------------------------------
    function integer highest_one_pos;
        input [WORK_W-1:0] value;
        integer j;
        begin
            highest_one_pos = -1;
            for (j = 0; j < WORK_W; j = j + 1) begin
                if (value[j])
                    highest_one_pos = j;
            end
        end
    endfunction

    // --------------------------------------------------
    // Main combinational datapath
    // --------------------------------------------------
    always @(*) begin

        // Defaults
        enc_sign     = 1'b0;
        enc_is_zero  = 1'b0;
        enc_is_nar   = 1'b0;
        enc_k        = 0;
        enc_exponent = 0;
        enc_fraction = 0;
        enc_frac_len = 0;

        scale_a      = 0;
        scale_b      = 0;
        common_scale = 0;
        result_scale = 0;

        sig_a        = 0;
        sig_b        = 0;
        aligned_a    = 0;
        aligned_b    = 0;
        signed_a     = 0;
        signed_b     = 0;
        sum_signed   = 0;
        abs_sum      = 0;
        norm_sum     = 0;

        shift_a      = 0;
        shift_b      = 0;
        norm_shift   = 0;
        lead_pos     = -1;
        last_one     = -1;

        // --------------------------------------------------
        // Special cases
        // --------------------------------------------------
        if (is_nar_a || is_nar_b) begin
            enc_is_nar = 1'b1;
        end
        else if (is_zero_a && is_zero_b) begin
            enc_is_zero = 1'b1;
        end
        else if (is_zero_a) begin
            // Pass through B
            enc_sign     = sign_b;
            enc_k        = k_b;
            enc_exponent = exponent_b;
            enc_fraction = fraction_b;
            enc_frac_len = frac_len_b;
        end
        else if (is_zero_b) begin
            // Pass through A
            enc_sign     = sign_a;
            enc_k        = k_a;
            enc_exponent = exponent_a;
            enc_fraction = fraction_a;
            enc_frac_len = frac_len_a;
        end
        else begin
            // --------------------------------------------------
            // Convert decode fields to a common scale
            // scale = k * 2^ES + exponent
            // --------------------------------------------------
            scale_a = (k_a <<< ES) + exponent_a;
            scale_b = (k_b <<< ES) + exponent_b;

            // Significand with hidden bit:
            // 1.fraction, stored as an integer with binary point after bit N
            sig_a = {1'b1, fraction_a};
            sig_b = {1'b1, fraction_b};

            // Use the larger scale as the reference
            common_scale = (scale_a >= scale_b) ? scale_a : scale_b;

            // Align smaller operand by right-shifting its significand
            if (common_scale > scale_a)
                shift_a = common_scale - scale_a;
            else
                shift_a = 0;

            if (common_scale > scale_b)
                shift_b = common_scale - scale_b;
            else
                shift_b = 0;

            aligned_a = (shift_a >= SIG_W) ? {WORK_W{1'b0}} : ({ {(WORK_W-SIG_W){1'b0}}, sig_a } >> shift_a);
            aligned_b = (shift_b >= SIG_W) ? {WORK_W{1'b0}} : ({ {(WORK_W-SIG_W){1'b0}}, sig_b } >> shift_b);

            // Apply signs
            signed_a = sign_a ? -$signed(aligned_a) : $signed(aligned_a);
            signed_b = sign_b ? -$signed(aligned_b) : $signed(aligned_b);

            // Add
            sum_signed = signed_a + signed_b;

            // Zero result
            if (sum_signed == 0) begin
                enc_is_zero = 1'b1;
            end
            else begin
                // Sign of result
                enc_sign = sum_signed[WORK_W-1];

                // Magnitude
                abs_sum = enc_sign ? -sum_signed : sum_signed;

                // Leading-one position
                lead_pos = highest_one_pos(abs_sum);

                if (lead_pos < 0) begin
                    enc_is_zero = 1'b1;
                end
                else begin
                    // Normalize so that the hidden 1 lands at bit N
                    // new_scale = common_scale + lead_pos - N
                    result_scale = common_scale + lead_pos - N;

                    norm_shift = N - lead_pos;

                    if (norm_shift >= 0)
                        norm_sum = abs_sum << norm_shift;
                    else
                        norm_sum = abs_sum >> (-norm_shift);

                    // Decompose result_scale back into k and exponent
                    enc_k = result_scale >>> ES;
                    enc_exponent = result_scale - (enc_k <<< ES);

                    // Fraction field = bits below the hidden 1
                    enc_fraction = norm_sum[N-1:0];

                    // frac_len = last nonzero fraction bit + 1
                    enc_frac_len = 0;
                    for (i = 0; i < N; i = i + 1) begin
                        if (enc_fraction[N-1-i])
                            enc_frac_len = i + 1;
                    end

                    // If fraction is exactly zero after normalization, that is fine:
                    // it represents a power of two.
                    // enc_frac_len stays 0 in that case.
                end
            end
        end
    end

endmodule
