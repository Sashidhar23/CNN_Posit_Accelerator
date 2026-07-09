`timescale 1ns / 1ps

module quire_to_posit #(
    parameter N = 8,
    parameter ES = 1,
    parameter QW = 48,
    parameter QF = QW / 2
)(
    input  wire signed [QW-1:0] quire_in,
    input  wire                 is_nar,
    output wire [N-1:0]         posit_out
);

    localparam integer SCALE_W = $clog2(N) + ES + 4;

    reg enc_sign;
    reg enc_zero;
    reg enc_nar;
    reg signed [$clog2(N):0] enc_k;
    reg [ES-1:0] enc_exp;
    reg [N-1:0] enc_frac;
    reg [$clog2(N):0] enc_flen;

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

    posit_encoder #(
        .N(N),
        .ES(ES)
    ) ENC (
        .sign      (enc_sign),
        .is_zero   (enc_zero),
        .is_nar    (enc_nar),
        .k         (enc_k),
        .exponent  (enc_exp),
        .fraction  (enc_frac),
        .frac_len  (enc_flen),
        .posit_out (posit_out)
    );

    always @(*) begin
        enc_sign = 1'b0;
        enc_zero = 1'b0;
        enc_nar  = is_nar;
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

        if (!is_nar) begin
            if (quire_in == 0) begin
                enc_zero = 1'b1;
            end
            else begin
                enc_sign = quire_in[QW-1];
                abs_quire = enc_sign ? -quire_in : quire_in;

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

endmodule
