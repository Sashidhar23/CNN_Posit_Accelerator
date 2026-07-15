`timescale 1ns / 1ps

module posit_to_quire #(
    parameter N = 8,
    parameter ES = 1,
    parameter QW = 48,
    parameter QF = QW / 2
)(
    input  wire [N-1:0]         posit_in,
    output reg signed [QW-1:0]  quire_out,
    output wire                 is_nar
);

    wire sign;
    wire is_zero;
    wire nar;
    wire signed [$clog2(N):0] k;
    wire [ES-1:0] exponent;
    wire [N-1:0] fraction;
    wire [$clog2(N):0] frac_len;

    posit_decoder #(.N(N), .ES(ES)) DECODER (
        .posit_in(posit_in), .sign(sign), .is_zero(is_zero), .is_nar(nar),
        .k(k), .exponent(exponent), .fraction(fraction), .frac_len(frac_len)
    );

    reg [QW-1:0] magnitude;
    integer scale;
    integer shift_amount;

    always @(*) begin
        magnitude = {QW{1'b0}};
        quire_out = {QW{1'b0}};
        scale = ($signed(k) * (1 << ES)) + $signed({1'b0, exponent});
        shift_amount = scale + QF - N;

        if (!is_zero && !nar) begin
            if (shift_amount >= 0) begin
                if (shift_amount < QW)
                    magnitude = {{(QW-(N+1)){1'b0}}, 1'b1, fraction}
                                << shift_amount;
            end
            else if ((-shift_amount) < (N+1)) begin
                magnitude = {{(QW-(N+1)){1'b0}}, 1'b1, fraction}
                            >> (-shift_amount);
            end
            quire_out = sign ? -$signed(magnitude) : $signed(magnitude);
        end
    end

    assign is_nar = nar;

endmodule
