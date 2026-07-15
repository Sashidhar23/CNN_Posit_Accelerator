`timescale 1ns / 1ps

module tb_pe_quire_product_exhaustive;
    reg clk;
    reg reset;
    reg pe_en;
    reg clear_acc;
    reg wshift;
    reg [7:0] input_in;
    reg [7:0] weight_in;
    wire [7:0] pe_output;
    reg [7:0] mul_expected [0:65535];
    integer a;
    integer b;
    integer address;
    integer errors;

    pe_quire #(.N(8), .ES(1), .QW(48), .QF(24)) DUT (
        .clk(clk), .reset(reset), .pe_en(pe_en), .clear_acc(clear_acc),
        .wshift(wshift), .input_in(input_in), .weight_in(weight_in),
        .psum_in(48'sd0), .psum_nar_in(1'b0), .input_out(),
        .weight_out(), .quire_out(), .is_nar(), .psum_out(),
        .psum_nar_out(), .pe_output(pe_output)
    );

    always #1 clk = ~clk;

    initial begin
        $readmemh("verification/posit8_mul_expected.mem", mul_expected);
        clk = 0;
        reset = 1;
        pe_en = 0;
        clear_acc = 0;
        wshift = 0;
        input_in = 0;
        weight_in = 0;
        errors = 0;
        repeat (2) @(negedge clk);
        reset = 0;

        for (a = 0; a < 256; a = a + 1) begin
            for (b = 0; b < 256; b = b + 1) begin
                input_in = a[7:0];
                weight_in = b[7:0];
                clear_acc = 1;
                wshift = 1;
                pe_en = 0;
                @(negedge clk);
                clear_acc = 0;
                wshift = 0;
                pe_en = 1;
                repeat (3) @(negedge clk);

                address = (a * 256) + b;
                if (pe_output !== mul_expected[address]) begin
                    if (errors < 20)
                        $display("QUIRE product mismatch a=%h b=%h got=%h expected=%h",
                                 input_in, weight_in, pe_output,
                                 mul_expected[address]);
                    errors = errors + 1;
                end
            end
        end

        if (errors == 0)
            $display("PASS tb_pe_quire_product_exhaustive: 65536 products");
        else
            $display("FAIL tb_pe_quire_product_exhaustive errors=%0d", errors);
        $finish;
    end
endmodule
