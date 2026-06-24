`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 23:44:35
// Design Name: 
// Module Name: tb_posit_adder
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




module posit_adder_tb;

    parameter N  = 8;
    parameter ES = 1;

    reg  [N-1:0] posit_a;
    reg  [N-1:0] posit_b;

    wire [N-1:0] posit_out;

    integer errors;

    posit_adder #(
        .N(N),
        .ES(ES)
    ) DUT (
        .posit_a  (posit_a),
        .posit_b  (posit_b),
        .posit_out(posit_out)
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
        $display("       POSIT ADDER TESTBENCH");
        $display("==========================================");

        //--------------------------------------------------
        // Special Cases
        //--------------------------------------------------

        run_case(
            8'b00000000,
            8'b00000000,
            8'b00000000,
            "T1 : Zero + Zero"
        );

        run_case(
            8'b10000000,
            8'b01000000,
            8'b10000000,
            "T2 : NaR + 1"
        );

        run_case(
            8'b01000000,
            8'b00000000,
            8'b01000000,
            "T3 : 1 + 0"
        );

        //--------------------------------------------------
        // Basic Arithmetic
        //--------------------------------------------------

        run_case(
            8'b01000000,
            8'b01000000,
            8'b01010000,
            "T4 : 1 + 1"
        );

        run_case(
            8'b01000000,
            8'b11000000,
            8'b00000000,
            "T5 : 1 + (-1)"
        );

        run_case(
            8'b01010000,
            8'b01000000,
            8'b01011000,
            "T6 : 2 + 1"
        );

        run_case(
            8'b01010000,
            8'b01010000,
            8'b01100000,
            "T7 : 2 + 2"
        );

        //--------------------------------------------------
        // Negative Numbers
        //--------------------------------------------------

        run_case(
            8'b11000000,
            8'b01010000,
            8'b01000000,
            "T8 : (-1) + 2"
        );

        run_case(
            8'b10110000,
            8'b01010000,
            8'b00000000,
            "T9 : (-2) + 2"
        );

        run_case(
            8'b11000000,
            8'b11000000,
            8'b10110000,
            "T10 : (-1) + (-1)"
        );

        //--------------------------------------------------
        // Fraction Cases
        //--------------------------------------------------

        run_case(
            8'b01101010,
            8'b01101010,
            8'b01110001,
            "T11 : Fraction + Fraction"
        );

        run_case(
            8'b01101010,
            8'b10010110,
            8'b00000000,
            "T12 : Fraction + Negative Fraction"
        );

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;

    end

endmodule
