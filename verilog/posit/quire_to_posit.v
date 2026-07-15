`timescale 1ns / 1ps

module quire_to_posit #(
    parameter N = 8,
    parameter ES = 1,
    parameter QW = 48,
    parameter QF = QW / 2,
    parameter SCALE_W = $clog2((4*QW) + (4*N) + 16) + 1
)(
    input  wire signed [QW-1:0] quire_in,
    input  wire                 is_nar,
    output wire [N-1:0]         posit_out
);

    reg sign;
    reg is_zero;
    reg [QW-1:0] magnitude;
    reg [QW-1:0] normalized_magnitude;
    reg signed [SCALE_W-1:0] scale;
    integer leading_position;
    integer i;

    always @(*) begin
        sign = quire_in[QW-1];
        is_zero = (quire_in == 0);
        magnitude = sign ? -quire_in : quire_in;
        normalized_magnitude = {QW{1'b0}};
        scale = {SCALE_W{1'b0}};
        leading_position = -1;

        for (i = 0; i < QW; i = i + 1) begin
            if (magnitude[i])
                leading_position = i;
        end

        if (leading_position >= 0) begin
            normalized_magnitude = magnitude << (QW-1-leading_position);
            scale = leading_position - QF;
        end
    end

    posit_round_pack #(
        .N(N), .ES(ES), .SIG_W(QW), .SCALE_W(SCALE_W)
    ) PACK (
        .sign(sign), .is_zero(is_zero), .is_nar(is_nar), .scale(scale),
        .normalized_significand(normalized_magnitude), .posit_out(posit_out)
    );

endmodule
