`timescale 1ns / 1ps

module tb_posit_arithmetic_exhaustive;
    reg [7:0] posit_a;
    reg [7:0] posit_b;
    wire [7:0] add_out;
    wire [7:0] mul_out;
    reg [7:0] add_expected [0:65535];
    reg [7:0] mul_expected [0:65535];
    integer a;
    integer b;
    integer address;
    integer errors;

    posit_adder #(.N(8), .ES(1)) ADDER (
        .posit_a(posit_a), .posit_b(posit_b), .posit_out(add_out)
    );

    posit_multiplier #(.N(8), .ES(1)) MULTIPLIER (
        .posit_a(posit_a), .posit_b(posit_b), .posit_out(mul_out)
    );

    initial begin
        $readmemh("verification/posit8_add_expected.mem", add_expected);
        $readmemh("verification/posit8_mul_expected.mem", mul_expected);
        posit_a = 0;
        posit_b = 0;
        errors = 0;

        for (a = 0; a < 256; a = a + 1) begin
            for (b = 0; b < 256; b = b + 1) begin
                posit_a = a[7:0];
                posit_b = b[7:0];
                address = (a * 256) + b;
                #1;
                if (add_out !== add_expected[address]) begin
                    if (errors < 20)
                        $display("ADD mismatch a=%h b=%h got=%h expected=%h",
                                 posit_a, posit_b, add_out, add_expected[address]);
                    errors = errors + 1;
                end
                if (mul_out !== mul_expected[address]) begin
                    if (errors < 20)
                        $display("MUL mismatch a=%h b=%h got=%h expected=%h",
                                 posit_a, posit_b, mul_out, mul_expected[address]);
                    errors = errors + 1;
                end
            end
        end

        if (errors == 0)
            $display("PASS tb_posit_arithmetic_exhaustive: 131072 checks");
        else
            $display("FAIL tb_posit_arithmetic_exhaustive errors=%0d", errors);
        $finish;
    end
endmodule
