`timescale 1ns / 1ps

module posit_to_quire #(
    parameter N = 8,
    parameter ES = 1,
    parameter QW = 48,
    parameter QF = QW / 2
)(
    input  wire [N-1:0]         posit_in,
    output reg  signed [QW-1:0] quire_out,
    output wire                 is_nar
);

    localparam integer SCALE_W = $clog2(N) + ES + 4;
    localparam integer MANT_W  = N + 1;

    wire sign;
    wire is_zero;
    wire signed [$clog2(N):0] k;
    wire [ES-1:0] exponent;
    wire [N-1:0] fraction;
    wire [$clog2(N):0] frac_len;

    reg [MANT_W-1:0] mantissa;
    reg signed [SCALE_W-1:0] scale;
    integer quire_shift;
    reg [QW-1:0] aligned_value;

    posit_decoder #(
        .N(N),
        .ES(ES)
    ) DEC (
        .posit_in (posit_in),
        .sign     (sign),
        .is_zero  (is_zero),
        .is_nar   (is_nar),
        .k        (k),
        .exponent (exponent),
        .fraction (fraction),
        .frac_len (frac_len)
    );

    always @(*) begin
        mantissa = {1'b1, fraction};
        scale = (k <<< ES) + $signed({1'b0, exponent});
        quire_shift = scale + QF - N;
        aligned_value = {QW{1'b0}};
        quire_out = {QW{1'b0}};

        if (!is_zero && !is_nar) begin
            if (quire_shift >= 0) begin
                if (quire_shift < QW)
                    aligned_value = {{(QW-MANT_W){1'b0}}, mantissa} << quire_shift;
            end
            else begin
                if ((-quire_shift) < MANT_W)
                    aligned_value = {{(QW-MANT_W){1'b0}}, mantissa} >> (-quire_shift);
            end

            quire_out = sign ? -$signed(aligned_value) : $signed(aligned_value);
        end
    end

endmodule
