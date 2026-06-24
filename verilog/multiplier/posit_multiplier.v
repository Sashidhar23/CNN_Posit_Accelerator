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

    // --------------------------------------------------
    // Decoder A outputs
    // --------------------------------------------------
    wire sign_a;
    wire zero_a;
    wire nar_a;

    wire signed [$clog2(N):0] k_a;
    wire [ES-1:0] exponent_a;

    wire [N-1:0] fraction_a;
    wire [$clog2(N):0] frac_len_a;

    // --------------------------------------------------
    // Decoder B outputs
    // --------------------------------------------------
    wire sign_b;
    wire zero_b;
    wire nar_b;

    wire signed [$clog2(N):0] k_b;
    wire [ES-1:0] exponent_b;

    wire [N-1:0] fraction_b;
    wire [$clog2(N):0] frac_len_b;

    // --------------------------------------------------
    // Encoder input regs
    // --------------------------------------------------
    reg enc_sign;
    reg enc_zero;
    reg enc_nar;

    reg signed [$clog2(N):0] enc_k;
    reg [ES-1:0] enc_exponent;

    reg [N-1:0] enc_fraction;
    reg [$clog2(N):0] enc_frac_len;

    // --------------------------------------------------
    // Decoder instances
    // --------------------------------------------------
    posit_decoder #(
        .N(N),
        .ES(ES)
    ) DEC_A (
        .posit_in (posit_a),
        .sign     (sign_a),
        .is_zero  (zero_a),
        .is_nar   (nar_a),
        .k        (k_a),
        .exponent (exponent_a),
        .fraction (fraction_a),
        .frac_len (frac_len_a)
    );

    posit_decoder #(
        .N(N),
        .ES(ES)
    ) DEC_B (
        .posit_in (posit_b),
        .sign     (sign_b),
        .is_zero  (zero_b),
        .is_nar   (nar_b),
        .k        (k_b),
        .exponent (exponent_b),
        .fraction (fraction_b),
        .frac_len (frac_len_b)
    );

    // --------------------------------------------------
    // Encoder instance
    // --------------------------------------------------
    posit_encoder #(
        .N(N),
        .ES(ES)
    ) ENC (
        .sign      (enc_sign),
        .is_zero   (enc_zero),
        .is_nar    (enc_nar),
        .k         (enc_k),
        .exponent  (enc_exponent),
        .fraction  (enc_fraction),
        .frac_len  (enc_frac_len),
        .posit_out (posit_out)
    );

    // --------------------------------------------------
    // Internal widths
    // --------------------------------------------------
    localparam integer MANT_W  = N + 1;              // hidden 1 + N fraction bits
    localparam integer PROD_W  = 2 * MANT_W;         // product width = 2N + 2
    localparam integer TE_BITS = $clog2(N) + ES + 4; // total exponent width

    // --------------------------------------------------
    // Internal signals
    // --------------------------------------------------
    reg [MANT_W-1:0] mant_a;
    reg [MANT_W-1:0] mant_b;

    reg [PROD_W-1:0] product;

    reg signed [TE_BITS-1:0] scale_a;
    reg signed [TE_BITS-1:0] scale_b;
    reg signed [TE_BITS-1:0] total_scale;

    reg [N-1:0] fraction_out;
    reg [$clog2(N):0] frac_len_out;

    integer i;
    integer k_int;
    integer exp_int;

    // sign-extended k values
    reg signed [TE_BITS-1:0] k_a_ext;
    reg signed [TE_BITS-1:0] k_b_ext;

    // --------------------------------------------------
    // Main combinational logic
    // --------------------------------------------------
    always @(*) begin

        //--------------------------------------------------
        // Defaults
        //--------------------------------------------------
        enc_sign      = 1'b0;
        enc_zero      = 1'b0;
        enc_nar       = 1'b0;
        enc_k         = 0;
        enc_exponent  = 0;
        enc_fraction  = 0;
        enc_frac_len  = 0;

        mant_a        = 0;
        mant_b        = 0;
        product       = 0;

        scale_a       = 0;
        scale_b       = 0;
        total_scale   = 0;

        fraction_out  = 0;
        frac_len_out  = 0;

        k_int         = 0;
        exp_int       = 0;

        k_a_ext       = 0;
        k_b_ext       = 0;

        //--------------------------------------------------
        // Special cases
        //--------------------------------------------------
        if (nar_a || nar_b) begin
            enc_nar = 1'b1;
        end
        else if (zero_a || zero_b) begin
            enc_zero = 1'b1;
        end
        else begin

            //--------------------------------------------------
            // Result sign
            //--------------------------------------------------
            enc_sign = sign_a ^ sign_b;

            //--------------------------------------------------
            // Build mantissas
            //
            // Decoder gives:
            // fraction = 10100000
            //
            // So mantissa becomes:
            // 1.10100000
            //--------------------------------------------------
            mant_a = {1'b1, fraction_a};
            mant_b = {1'b1, fraction_b};

            //--------------------------------------------------
            // Multiply mantissas
            //
            // mant_a and mant_b are Q1.N style:
            // 1.xxxxx
            //
            // product is Q2.2N style:
            // [2N+1 : 0]
            //--------------------------------------------------
            product = mant_a * mant_b;

            //--------------------------------------------------
            // Compute scale
            //
            // scale = k * 2^ES + exponent
            //--------------------------------------------------
            k_a_ext = {{(TE_BITS-($clog2(N)+1)){k_a[$clog2(N)]}}, k_a};
            k_b_ext = {{(TE_BITS-($clog2(N)+1)){k_b[$clog2(N)]}}, k_b};

            scale_a = (k_a_ext <<< ES) + {{(TE_BITS-ES){1'b0}}, exponent_a};
            scale_b = (k_b_ext <<< ES) + {{(TE_BITS-ES){1'b0}}, exponent_b};

            total_scale = scale_a + scale_b;

            //--------------------------------------------------
            // Normalize product
            //
            // product range:
            // mant_a in [1,2)
            // mant_b in [1,2)
            //
            // product in [1,4)
            //
            // If product[2N+1] = 1:
            //     product is in [2,4)
            //     normalize by shifting right 1
            //     total_scale += 1
            //
            // Else:
            //     product is in [1,2)
            //--------------------------------------------------

            if (product[2*N+1]) begin
                // product >= 2
                total_scale = total_scale + 1;

                // After normalization, hidden 1 is effectively at bit 2N.
                // Fraction starts at original product[2N].
                fraction_out = product[2*N -: N];
            end
            else begin
                // product in [1,2)
                // Hidden 1 is already at bit 2N.
                // Fraction starts at product[2N-1].
                fraction_out = product[2*N-1 -: N];
            end

            //--------------------------------------------------
            // Compute fraction length by trimming trailing zeros
            //
            // fraction_out = 10100000 -> frac_len = 3
            //--------------------------------------------------
            frac_len_out = 0;

            for (i = 0; i < N; i = i + 1) begin
                if (fraction_out[N-1-i])
                    frac_len_out = i + 1;
            end

            //--------------------------------------------------
            // Split total_scale back into k and exponent
            //
            // total_scale = k * 2^ES + exponent
            //
            // For ES=1:
            // total_scale = 2k + exponent
            //
            // Need floor division for negative total_scale.
            //--------------------------------------------------
            if (ES == 0) begin
                k_int   = total_scale;
                exp_int = 0;
            end
            else begin
                // Arithmetic shift gives floor division by 2^ES
                // for two's-complement signed values.
                k_int = total_scale >>> ES;

                exp_int = total_scale - (k_int <<< ES);
            end

            //--------------------------------------------------
            // Saturate k to approximate valid posit range
            //--------------------------------------------------
            if (k_int > (N-2))
                k_int = N-2;
            else if (k_int < -(N-2))
                k_int = -(N-2);

            //--------------------------------------------------
            // Feed encoder
            //--------------------------------------------------
            enc_k        = k_int[$clog2(N):0];
            enc_exponent = exp_int[ES-1:0];
            enc_fraction = fraction_out;
            enc_frac_len = frac_len_out;
        end
    end

endmodule
