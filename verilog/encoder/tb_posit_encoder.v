`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 13:01:38
// Design Name: 
// Module Name: tb_posit_encoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////




module posit_encoder_tb;

    parameter N  = 8;
    parameter ES = 1;

    reg sign;
    reg is_zero;
    reg is_nar;

    reg signed [$clog2(N):0] k;
    reg [ES-1:0] exponent;

    reg [N-1:0] fraction;
    reg [$clog2(N):0] frac_len;

    wire [N-1:0] posit_out;

    // Decoder outputs for loopback check
    wire dec_sign;
    wire dec_is_zero;
    wire dec_is_nar;
    wire signed [$clog2(N):0] dec_k;
    wire [ES-1:0] dec_exponent;
    wire [N-1:0] dec_fraction;
    wire [$clog2(N):0] dec_frac_len;

    integer errors;

    function loopback_ok;
        input unused;
        begin
            loopback_ok =
                (dec_sign     === sign)     &&
                (dec_is_zero  === is_zero)  &&
                (dec_is_nar   === is_nar)   &&
                (dec_k        === k)        &&
                (dec_exponent === exponent) &&
                (dec_fraction === fraction) &&
                (dec_frac_len === frac_len);
        end
    endfunction

    task show_loopback;
        begin
            $display("  in : sign=%b zero=%b nar=%b k=%0d exp=%b frac=%b frac_len=%0d",
                     sign, is_zero, is_nar, k, exponent, fraction, frac_len);
            $display("  dec: sign=%b zero=%b nar=%b k=%0d exp=%b frac=%b frac_len=%0d",
                     dec_sign, dec_is_zero, dec_is_nar, dec_k, dec_exponent, dec_fraction, dec_frac_len);
        end
    endtask

    posit_encoder #(
        .N(N),
        .ES(ES)
    ) DUT (
        .sign(sign),
        .is_zero(is_zero),
        .is_nar(is_nar),
        .k(k),
        .exponent(exponent),
        .fraction(fraction),
        .frac_len(frac_len),
        .posit_out(posit_out)
    );

    posit_decoder #(
        .N(N),
        .ES(ES)
    ) DEC (
        .posit_in(posit_out),
        .sign(dec_sign),
        .is_zero(dec_is_zero),
        .is_nar(dec_is_nar),
        .k(dec_k),
        .exponent(dec_exponent),
        .fraction(dec_fraction),
        .frac_len(dec_frac_len)
    );

    initial begin
        errors = 0;

        $display("------------------------------------------");
        $display(" Posit Encoder Testbench ");
        $display("------------------------------------------");

        //--------------------------------------------------
        // Test 1 : Zero
        //--------------------------------------------------
        sign     = 0;
        is_zero  = 1;
        is_nar   = 0;
        k        = 0;
        exponent = 0;
        fraction = 0;
        frac_len = 0;

        #10;
        $display("T1 ZERO");
        $display("posit_out = %b", posit_out);

        #1;
        if (!loopback_ok(1'b0) || posit_out !== 8'b00000000) begin
            $display("T1 FAIL");
            show_loopback;
            errors = errors + 1;
        end else begin
            $display("T1 PASS");
        end

        //--------------------------------------------------
        // Test 2 : NaR
        //--------------------------------------------------
        sign     = 0;
        is_zero  = 0;
        is_nar   = 1;
        k        = 0;
        exponent = 0;
        fraction = 0;
        frac_len = 0;

        #10;
        $display("T2 NaR");
        $display("posit_out = %b", posit_out);

        #1;
        if (!loopback_ok(1'b0) || posit_out !== 8'b10000000) begin
            $display("T2 FAIL");
            show_loopback;
            errors = errors + 1;
        end else begin
            $display("T2 PASS");
        end

        //--------------------------------------------------
        // Test 3 : +1
        // k=0 => regime 10
        // exp=0
        // no fraction
        //--------------------------------------------------
        sign     = 0;
        is_zero  = 0;
        is_nar   = 0;
        k        = 0;
        exponent = 0;
        fraction = 8'b00000000;
        frac_len = 0;

        #10;
        $display("T3 +1");
        $display("posit_out = %b", posit_out);

        #1;
        if (!loopback_ok(1'b0) || posit_out !== 8'b01000000) begin
            $display("T3 FAIL");
            show_loopback;
            errors = errors + 1;
        end else begin
            $display("T3 PASS");
        end

        //--------------------------------------------------
        // Test 4 : positive fraction
        // fraction bits = 101
        //--------------------------------------------------
        sign     = 0;
        is_zero  = 0;
        is_nar   = 0;
        k        = 0;
        exponent = 1'b1;

        fraction = 8'b10100000;
        frac_len = 3;

        #10;
        $display("T4 Positive Fraction");
        $display("posit_out = %b", posit_out);

        #1;
        if (!loopback_ok(1'b0) || posit_out !== 8'b01011010) begin
            $display("T4 FAIL");
            show_loopback;
            errors = errors + 1;
        end else begin
            $display("T4 PASS");
        end

        //--------------------------------------------------
        // Test 5 : negative version
        //--------------------------------------------------
        sign     = 1;
        is_zero  = 0;
        is_nar   = 0;
        k        = 0;
        exponent = 1'b1;

        fraction = 8'b10100000;
        frac_len = 3;

        #10;
        $display("T5 Negative Fraction");
        $display("posit_out = %b", posit_out);

        #1;
        if (!loopback_ok(1'b0) || posit_out !== 8'b10100110) begin
            $display("T5 FAIL");
            show_loopback;
            errors = errors + 1;
        end else begin
            $display("T5 PASS");
        end

        //--------------------------------------------------
        // Test 6 : k = +1
        //--------------------------------------------------
        sign     = 0;
        is_zero  = 0;
        is_nar   = 0;
        k        = 1;
        exponent = 0;

        fraction = 8'b11000000;
        frac_len = 2;

        #10;
        $display("T6 Positive Regime");
        $display("posit_out = %b", posit_out);

        #1;
        if (!loopback_ok(1'b0) || posit_out !== 8'b01100110) begin
            $display("T6 FAIL");
            show_loopback;
            errors = errors + 1;
        end else begin
            $display("T6 PASS");
        end

        //--------------------------------------------------
        // Test 7 : k = -2
        //--------------------------------------------------
        sign     = 0;
        is_zero  = 0;
        is_nar   = 0;
        k        = -2;
        exponent = 1;

        fraction = 8'b01000000;
        frac_len = 2;

        #10;
        $display("T7 Negative Regime");
        $display("posit_out = %b", posit_out);

        #1;
        if (!loopback_ok(1'b0) || posit_out !== 8'b00011010) begin
            $display("T7 FAIL");
            show_loopback;
            errors = errors + 1;
        end else begin
            $display("T7 PASS");
        end

        //--------------------------------------------------
        // Final loopback summary
        //--------------------------------------------------
        $display("------------------------------------------");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("------------------------------------------");

        $finish;
    end

endmodule
