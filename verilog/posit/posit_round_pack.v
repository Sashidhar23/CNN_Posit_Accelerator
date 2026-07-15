`timescale 1ns / 1ps

// Round an exact normalized binary significand to a standard posit.  The
// Posit<8,1> branch is the accelerator datapath and is fully RNE-correct,
// including the tapered minpos/maxpos intervals.
module posit_round_pack #(
    parameter N = 8,
    parameter ES = 1,
    parameter SIG_W = 18,
    parameter SCALE_W = 8,
    parameter STREAM_W = (4*N) + SIG_W + (1 << ES) + 8
)(
    input  wire                         sign,
    input  wire                         is_zero,
    input  wire                         is_nar,
    input  wire signed [SCALE_W-1:0]    scale,
    input  wire [SIG_W-1:0]             normalized_significand,
    output wire [N-1:0]                 posit_out
);

    generate
        if ((N == 8) && (ES == 1)) begin : POSIT_8_1_RNE
            reg [7:0] packed_posit;
            reg [7:0] magnitude_code;
            reg [7:0] regime_base;
            reg [3:0] fraction_value;
            reg [SIG_W-1:0] hidden_one;
            reg [SIG_W-1:0] endpoint_boundary;
            reg guard_bit;
            reg sticky_bit;
            integer scale_value;
            integer k_value;
            integer exponent_value;
            integer fraction_count;
            integer i;

            always @(*) begin
                packed_posit = 8'h00;
                magnitude_code = 8'h00;
                regime_base = 8'h00;
                fraction_value = 4'h0;
                hidden_one = {1'b1, {(SIG_W-1){1'b0}}};
                endpoint_boundary = hidden_one |
                                    ({{(SIG_W-1){1'b0}}, 1'b1} << (SIG_W-3));
                guard_bit = 1'b0;
                sticky_bit = 1'b0;
                scale_value = $signed(scale);
                k_value = scale_value >>> 1;
                exponent_value = scale_value - (k_value <<< 1);
                fraction_count = 0;

                if (is_nar) begin
                    packed_posit = 8'h80;
                end
                else if (is_zero) begin
                    packed_posit = 8'h00;
                end
                else begin
                    // The endpoint gaps are useed-wide, so their numerical
                    // midpoints differ from a simple encoded-bit midpoint.
                    if (scale_value < -13) begin
                        magnitude_code = 8'h00;
                    end
                    else if (scale_value == -13) begin
                        magnitude_code =
                            (normalized_significand == hidden_one) ? 8'h00 : 8'h01;
                    end
                    else if (scale_value == -12) begin
                        magnitude_code = 8'h01;
                    end
                    else if (scale_value == -11) begin
                        magnitude_code =
                            (normalized_significand < endpoint_boundary) ? 8'h01 : 8'h02;
                    end
                    else if (scale_value == 10) begin
                        magnitude_code = 8'h7e;
                    end
                    else if (scale_value == 11) begin
                        magnitude_code =
                            (normalized_significand <= endpoint_boundary) ? 8'h7e : 8'h7f;
                    end
                    else if (scale_value >= 12) begin
                        magnitude_code = 8'h7f;
                    end
                    else begin
                        case (k_value)
                            -5: begin regime_base = 8'h02; fraction_count = 0; end
                            -4: begin regime_base = 8'h04; fraction_count = 1; end
                            -3: begin regime_base = 8'h08; fraction_count = 2; end
                            -2: begin regime_base = 8'h10; fraction_count = 3; end
                            -1: begin regime_base = 8'h20; fraction_count = 4; end
                             0: begin regime_base = 8'h40; fraction_count = 4; end
                             1: begin regime_base = 8'h60; fraction_count = 3; end
                             2: begin regime_base = 8'h70; fraction_count = 2; end
                             3: begin regime_base = 8'h78; fraction_count = 1; end
                             4: begin regime_base = 8'h7c; fraction_count = 0; end
                            default: begin regime_base = 8'h00; fraction_count = 0; end
                        endcase

                        fraction_value = 4'h0;
                        for (i = 0; i < 4; i = i + 1) begin
                            if (i < fraction_count)
                                fraction_value = (fraction_value << 1) |
                                                 normalized_significand[SIG_W-2-i];
                        end

                        magnitude_code = regime_base +
                                         (exponent_value << fraction_count) +
                                         fraction_value;
                        guard_bit = normalized_significand[
                            SIG_W-2-fraction_count
                        ];
                        sticky_bit = 1'b0;
                        for (i = 0; i < SIG_W; i = i + 1) begin
                            if (i < (SIG_W-2-fraction_count))
                                sticky_bit = sticky_bit |
                                             normalized_significand[i];
                        end

                        if (guard_bit && (sticky_bit || magnitude_code[0]))
                            magnitude_code = magnitude_code + 1'b1;
                    end

                    packed_posit = sign ? ((~magnitude_code) + 1'b1) :
                                           magnitude_code;
                end
            end

            assign posit_out = packed_posit;
        end
        else begin : GENERIC_TRUNCATING_FALLBACK
            reg signed [$clog2(N):0] encoder_k;
            reg [ES-1:0] encoder_exponent;
            reg [N-1:0] encoder_fraction;
            reg [$clog2(N):0] encoder_fraction_length;
            integer k_integer;
            integer exponent_integer;

            always @(*) begin
                k_integer = $signed(scale) >>> ES;
                exponent_integer = $signed(scale) - (k_integer <<< ES);
                encoder_k = k_integer;
                encoder_exponent = exponent_integer;
                encoder_fraction = normalized_significand[SIG_W-2 -: N];
                encoder_fraction_length = N;
            end

            posit_encoder #(.N(N), .ES(ES)) FALLBACK_ENCODER (
                .sign(sign), .is_zero(is_zero), .is_nar(is_nar),
                .k(encoder_k), .exponent(encoder_exponent),
                .fraction(encoder_fraction),
                .frac_len(encoder_fraction_length), .posit_out(posit_out)
            );
        end
    endgenerate

endmodule
