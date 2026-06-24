`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: posit_multiplier
// Description:
//   Parametric posit multiplier for posit<N, ES>.
//
//   Algorithm:
//     1.  Decode both inputs via posit_decoder instances.
//     2.  Special-case: zero * anything = 0,  NaR * anything = NaR.
//     3.  Sign   : sign_out = sign_a ^ sign_b
//     4.  Regime + Exponent:
//           total_exp_a = k_a * 2^ES + exp_a
//           total_exp_b = k_b * 2^ES + exp_b
//           total_exp   = total_exp_a + total_exp_b   (added *before* fraction carry)
//     5.  Fraction:
//           Represent each operand as a 1.fraction fixed-point value with
//           (N+1) integer+fraction bits:  {1, fraction[N-1 : N-frac_len]}  left-justified.
//           Product is (N+2) bits wide; the implicit leading 1s multiply to give
//           a result that is either 1x.xxx... or 1.xxx...
//           If the product MSB (bit 2N+1) is set the result is >= 2, so we
//           normalise by shifting right one and incrementing total_exp.
//     6.  Split normalised total_exp back into k_out and exp_out.
//     7.  Encode via posit_encoder.
//
//   Rounding: truncation (round toward zero) on the fraction product.
//////////////////////////////////////////////////////////////////////////////////

module posit_multiplier #(
    parameter N  = 8,
    parameter ES = 1
)(
    input  wire [N-1:0] posit_a,
    input  wire [N-1:0] posit_b,
    output wire [N-1:0] posit_out
);

    // -----------------------------------------------------------------------
    // Decoder A
    // -----------------------------------------------------------------------
    wire        sign_a;
    wire        zero_a, nar_a;
    wire signed [$clog2(N):0] k_a;
    wire [ES-1:0]             exp_a;
    wire [N-1:0]              frac_a;
    wire [$clog2(N):0]        flen_a;

    posit_decoder #(.N(N), .ES(ES)) DEC_A (
        .posit_in  (posit_a),
        .sign      (sign_a),
        .is_zero   (zero_a),
        .is_nar    (nar_a),
        .k         (k_a),
        .exponent  (exp_a),
        .fraction  (frac_a),
        .frac_len  (flen_a)
    );

    // -----------------------------------------------------------------------
    // Decoder B
    // -----------------------------------------------------------------------
    wire        sign_b;
    wire        zero_b, nar_b;
    wire signed [$clog2(N):0] k_b;
    wire [ES-1:0]             exp_b;
    wire [N-1:0]              frac_b;
    wire [$clog2(N):0]        flen_b;

    posit_decoder #(.N(N), .ES(ES)) DEC_B (
        .posit_in  (posit_b),
        .sign      (sign_b),
        .is_zero   (zero_b),
        .is_nar    (nar_b),
        .k         (k_b),
        .exponent  (exp_b),
        .fraction  (frac_b),
        .frac_len  (flen_b)
    );

    // -----------------------------------------------------------------------
    // Encoder
    // -----------------------------------------------------------------------
    reg        enc_sign;
    reg        enc_zero;
    reg        enc_nar;
    reg signed [$clog2(N):0] enc_k;
    reg [ES-1:0]             enc_exp;
    reg [N-1:0]              enc_frac;
    reg [$clog2(N):0]        enc_flen;

    posit_encoder #(.N(N), .ES(ES)) ENC (
        .sign      (enc_sign),
        .is_zero   (enc_zero),
        .is_nar    (enc_nar),
        .k         (enc_k),
        .exponent  (enc_exp),
        .fraction  (enc_frac),
        .frac_len  (enc_flen),
        .posit_out (posit_out)
    );

    // -----------------------------------------------------------------------
    // Multiply logic
    // -----------------------------------------------------------------------
    // We need enough bits for the signed total exponent sum.
    // Maximum k magnitude for posit<N> is N-2, so total_exp fits in
    // ceil(log2((N-2)*2^ES * 2 + 2^ES)) bits – 8 bits is comfortable for N<=32.
    localparam TE_BITS = $clog2(N) + ES + 3; // signed total-exponent width

    integer i;

    // 1.fraction representation: bit N is the hidden '1', bits N-1..0 are the
    // fraction field (left-justified as stored by the decoder).
    // We use (N+1)-bit operands.
    reg [N:0] mant_a;
    reg [N:0] mant_b;

    // Product is (2N+2) bits wide.
    reg [2*N+1:0] product;

    // Normalised fraction (upper N bits of the product fraction part).
    reg [N-1:0]        frac_out;
    reg [$clog2(N):0]  flen_out;

    reg signed [TE_BITS-1:0] total_exp;
    reg signed [TE_BITS-1:0] total_exp_a;
    reg signed [TE_BITS-1:0] total_exp_b;

    // Temporaries for k/exp split
    reg signed [TE_BITS-1:0] te_norm;
    integer                   k_int;
    integer                   e_int;

    always @(*) begin
        // Defaults
        enc_sign = 1'b0;
        enc_zero = 1'b0;
        enc_nar  = 1'b0;
        enc_k    = 0;
        enc_exp  = 0;
        enc_frac = 0;
        enc_flen = 0;

        mant_a    = 0;
        mant_b    = 0;
        product   = 0;
        frac_out  = 0;
        flen_out  = 0;
        total_exp = 0;
        total_exp_a = 0;
        total_exp_b = 0;
        te_norm   = 0;
        k_int     = 0;
        e_int     = 0;

        // ------------------------------------------------------------------
        // Special cases
        // ------------------------------------------------------------------
        if (nar_a || nar_b) begin
            enc_nar = 1'b1;
        end
        else if (zero_a || zero_b) begin
            enc_zero = 1'b1;
        end
        else begin
            // ----------------------------------------------------------------
            // Sign
            // ----------------------------------------------------------------
            enc_sign = sign_a ^ sign_b;

            // ----------------------------------------------------------------
            // Build 1.fraction mantissas  (hidden bit = 1 at position N)
            // ----------------------------------------------------------------
            mant_a = {1'b1, frac_a};   // 1.fraction_a  (N+1 bits)
            mant_b = {1'b1, frac_b};   // 1.fraction_b  (N+1 bits)

            // ----------------------------------------------------------------
            // (2N+2)-bit product
            // ----------------------------------------------------------------
            product = mant_a * mant_b;

            // ----------------------------------------------------------------
            // Total exponent = k*2^ES + exp  for each operand
            // ----------------------------------------------------------------
            total_exp_a = ($signed({{(TE_BITS - $clog2(N) - 1){k_a[$clog2(N)]}}, k_a}) <<< ES)
                          + {{(TE_BITS - ES){1'b0}}, exp_a};

            total_exp_b = ($signed({{(TE_BITS - $clog2(N) - 1){k_b[$clog2(N)]}}, k_b}) <<< ES)
                          + {{(TE_BITS - ES){1'b0}}, exp_b};

            total_exp = total_exp_a + total_exp_b;

            // ----------------------------------------------------------------
            // Normalise product
            //   mant_a and mant_b are both in [1.0, 2.0)
            //   so product is in [1.0, 4.0)
            //   MSB of product is at bit 2N+1.
            //   The integer part of the product occupies the top 2 bits:
            //     product[2N+1:2N]
            //   If product[2N+1] == 1  → result >= 2, shift right, inc total_exp
            //   If product[2N]   == 1  → result in [1,2), no shift needed
            //   (product is always >= 1 since both mantissas >= 1)
            // ----------------------------------------------------------------
            if (product[2*N+1]) begin
                // Result >= 2: normalise by shifting right 1
                total_exp = total_exp + 1;
                // Fraction bits are product[2N-1 : N]  (top N bits after hidden 1 at 2N)
                frac_out = product[2*N-1 -: N];
            end
            else begin
                // Result in [1, 2): fraction bits are product[2N-1 : N]
                // Hidden 1 is at bit 2N, fraction starts at bit 2N-1
                frac_out = product[2*N-1 -: N];
            end

            // ----------------------------------------------------------------
            // Compute frac_len: trim trailing zeros from frac_out
            // ----------------------------------------------------------------
            flen_out = 0;
            for (i = 0; i < N; i = i + 1) begin
                if (frac_out[N-1-i])
                    flen_out = i + 1;
            end

            // ----------------------------------------------------------------
            // Split total_exp back into k and exp
            //   total_exp = k * 2^ES + exp,  0 <= exp < 2^ES
            //   Use floor division so that exp is always non-negative.
            // ----------------------------------------------------------------
            if (ES == 0) begin
                k_int = total_exp;
                e_int = 0;
            end
            else begin
                // Arithmetic (floor) divide by 2^ES
                // For negative total_exp we need floor, not truncation.
                te_norm = total_exp;
                if (te_norm[TE_BITS-1] && (te_norm[ES-1:0] != 0)) begin
                    // Negative and not exactly divisible → floor = trunc - 1
                    k_int = (te_norm >>> ES) - 1;
                end
                else begin
                    k_int = te_norm >>> ES;
                end
                e_int = total_exp - (k_int <<< ES);
            end

            // ----------------------------------------------------------------
            // Saturate k to valid posit range  [-(N-2), N-2]
            // ----------------------------------------------------------------
            if (k_int > (N-2))
                k_int = N-2;
            else if (k_int < -(N-2))
                k_int = -(N-2);

            enc_k   = k_int[$clog2(N):0];
            enc_exp = e_int[ES-1:0];
            enc_frac = frac_out;
            enc_flen = flen_out;
        end
    end

endmodule