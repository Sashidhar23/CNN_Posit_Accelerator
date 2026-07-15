`timescale 1ns / 1ps

module tb_posit_quire_conversion;
    reg [7:0] posit_in;
    wire signed [47:0] quire_value;
    wire input_is_nar;
    wire [7:0] posit_out;
    integer code;
    integer errors;

    posit_to_quire #(.N(8), .ES(1), .QW(48), .QF(24)) TO_QUIRE (
        .posit_in(posit_in), .quire_out(quire_value), .is_nar(input_is_nar)
    );

    quire_to_posit #(.N(8), .ES(1), .QW(48), .QF(24)) TO_POSIT (
        .quire_in(quire_value), .is_nar(input_is_nar), .posit_out(posit_out)
    );

    initial begin
        posit_in = 0;
        errors = 0;
        for (code = 0; code < 256; code = code + 1) begin
            posit_in = code[7:0];
            #1;
            if (posit_out !== posit_in) begin
                $display("QUIRE round-trip mismatch in=%h quire=%h out=%h",
                         posit_in, quire_value, posit_out);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("PASS tb_posit_quire_conversion: all 256 codes");
        else
            $display("FAIL tb_posit_quire_conversion errors=%0d", errors);
        $finish;
    end
endmodule
