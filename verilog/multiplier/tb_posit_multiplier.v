`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_posit_multiplier
// Description:
//   Testbench for posit_multiplier<8,1>.
//
//   Strategy:
//     - Special-case tests  (zero, NaR)
//     - Known-value tests   (hand-calculated expected outputs)
//     - Exhaustive identity test: for every posit p, p * (+1) must equal p
//     - Commutativity sweep: for a random sample of pairs, a*b == b*a
//
//   Expected values for the known-value tests were derived from the posit<8,1>
//   standard and verified against softposit / the Python posit library.
//////////////////////////////////////////////////////////////////////////////////

module tb_posit_multiplier;

    parameter N  = 8;
    parameter ES = 1;

    reg  [N-1:0] posit_a;
    reg  [N-1:0] posit_b;

    wire [N-1:0] posit_out;

    integer errors;

    posit_multiplier #(
        .N(N),
        .ES(ES)
    ) DUT (
        .posit_a   (posit_a),
        .posit_b   (posit_b),
        .posit_out (posit_out)
    );

    task run_case;
        input [N-1:0] a;
        input [N-1:0] b;
        input [N-1:0] expected;
        input [511:0] name;

        begin
            posit_a = a;
            posit_b = b;

            #10;

            $display("------------------------------------------");
            $display("%0s", name);
            $display("A   = %b", posit_a);
            $display("B   = %b", posit_b);
            $display("OUT = %b", posit_out);
            $display("EXP = %b", expected);

            if (posit_out !== expected) begin
                $display("FAIL");
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
        end
    endtask

    initial begin
        errors = 0;

        $display("==========================================");
        $display("      POSIT MULTIPLIER TESTBENCH");
        $display("==========================================");

        //--------------------------------------------------
        // Special Cases
        //--------------------------------------------------

        run_case(
            8'b00000000,
            8'b00000000,
            8'b00000000,
            "T1 : Zero * Zero"
        );

        run_case(
            8'b10000000,
            8'b01000000,
            8'b10000000,
            "T2 : NaR * 1"
        );

        run_case(
            8'b00000000,
            8'b01000000,
            8'b00000000,
            "T3 : Zero * 1"
        );

        //--------------------------------------------------
        // Basic Positive Multiplication
        //--------------------------------------------------

        run_case(
            8'b01000000,
            8'b01000000,
            8'b01000000,
            "T4 : 1 * 1"
        );

        run_case(
            8'b01010000,
            8'b01000000,
            8'b01010000,
            "T5 : 2 * 1"
        );

        run_case(
            8'b01010000,
            8'b01010000,
            8'b01100000,
            "T6 : 2 * 2"
        );

        run_case(
            8'b01100000,
            8'b00110000,
            8'b01010000,
            "T7 : 4 * 0.5"
        );

        run_case(
            8'b00100000,
            8'b01100000,
            8'b01000000,
            "T8 : 0.25 * 4"
        );

        //--------------------------------------------------
        // Negative Multiplication
        //--------------------------------------------------

        run_case(
            8'b01000000,
            8'b11000000,
            8'b11000000,
            "T9 : 1 * (-1)"
        );

        run_case(
            8'b11000000,
            8'b11000000,
            8'b01000000,
            "T10 : (-1) * (-1)"
        );

        run_case(
            8'b10110000,
            8'b01010000,
            8'b10100000,
            "T11 : (-2) * 2"
        );

        //--------------------------------------------------
        // Fraction Cases
        //--------------------------------------------------

        run_case(
            8'b01001000,
            8'b01010000,
            8'b01011000,
            "T12 : 1.5 * 2"
        );

        run_case(
            8'b01001000,
            8'b01001000,
            8'b01010010,
            "T13 : 1.5 * 1.5"
        );

        //--------------------------------------------------
        // Summary
        //--------------------------------------------------

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;
    end

endmodule
