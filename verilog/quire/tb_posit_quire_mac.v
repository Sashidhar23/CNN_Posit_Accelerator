`timescale 1ns / 1ps

module tb_posit_quire_mac;

    parameter N  = 8;
    parameter ES = 1;
    parameter QW = 128;
    parameter QF = 64;

    reg clk;
    reg reset;
    reg clear;
    reg enable;
    reg [N-1:0] posit_a;
    reg [N-1:0] posit_b;

    wire signed [QW-1:0] quire_out;
    wire [N-1:0] posit_out;
    wire is_nar;

    integer errors;

    posit_quire_mac #(
        .N(N),
        .ES(ES),
        .QW(QW),
        .QF(QF)
    ) DUT (
        .clk       (clk),
        .reset     (reset),
        .clear     (clear),
        .enable    (enable),
        .posit_a   (posit_a),
        .posit_b   (posit_b),
        .quire_out (quire_out),
        .posit_out (posit_out),
        .is_nar    (is_nar)
    );

    always #5 clk = ~clk;

    task mac_once;
        input [N-1:0] a;
        input [N-1:0] b;
        input signed [QW-1:0] expected_quire;
        input [N-1:0] expected_posit;
        input expected_nar;
        input [511:0] name;
        begin
            posit_a = a;
            posit_b = b;
            enable = 1'b1;

            $display("------------------------------------------");
            $display("%0s", name);
            $display("A      = %b", posit_a);
            $display("B      = %b", posit_b);

            @(posedge clk);
            #1;
            enable = 1'b0;

            check_state(expected_quire, expected_posit, expected_nar, "after enabled MAC");
        end
    endtask

    task check_state;
        input signed [QW-1:0] expected_quire;
        input [N-1:0] expected;
        input expected_nar;
        input [511:0] name;
        begin
            $display("------------------------------------------");
            $display("%0s", name);
            $display("QUIRE = %0d", quire_out);
            $display("QEXP  = %0d", expected_quire);
            $display("OUT   = %b", posit_out);
            $display("EXP   = %b", expected);
            $display("NAR   = %b", is_nar);
            $display("NEXP  = %b", expected_nar);

            if (quire_out !== expected_quire || posit_out !== expected || is_nar !== expected_nar) begin
                $display("FAIL");
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
        end
    endtask

    task clear_acc;
        begin
            clear = 1'b1;
            enable = 1'b0;
            posit_a = 0;
            posit_b = 0;
            @(posedge clk);
            #1;
            clear = 1'b0;
            check_state({QW{1'b0}}, 8'b00000000, 1'b0, "clear gives zero");
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        clear = 1'b0;
        enable = 1'b0;
        posit_a = 0;
        posit_b = 0;
        errors = 0;

        $display("==========================================");
        $display("       POSIT QUIRE MAC TESTBENCH");
        $display("==========================================");

        repeat (2) @(posedge clk);
        reset = 1'b0;
        #1;
        check_state({QW{1'b0}}, 8'b00000000, 1'b0, "T1 : Reset gives zero");

        mac_once(8'b01000000, 8'b01000000, $signed(128'd1 <<< QF), 8'b01000000, 1'b0,
                 "T2 : 1 * 1 accumulated = 1");

        mac_once(8'b01000000, 8'b01000000, $signed(128'd2 <<< QF), 8'b01010000, 1'b0,
                 "T3 : 1 + 1 accumulated = 2");

        enable = 1'b0;
        posit_a = 8'b01010000;
        posit_b = 8'b01010000;
        @(posedge clk);
        #1;
        check_state($signed(128'd2 <<< QF), 8'b01010000, 1'b0,
                    "T4 : enable low holds accumulator");

        clear_acc();

        mac_once(8'b01010000, 8'b01010000, $signed(128'd4 <<< QF), 8'b01100000, 1'b0,
                 "T5 : 2 * 2 accumulated = 4");

        clear_acc();

        mac_once(8'b11000000, 8'b01000000, -$signed(128'd1 <<< QF), 8'b11000000, 1'b0,
                 "T6 : -1 * 1 accumulated = -1");

        mac_once(8'b10000000, 8'b01000000, -$signed(128'd1 <<< QF), 8'b10000000, 1'b1,
                 "T7 : NaR input makes output NaR");

        clear_acc();

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;
    end

endmodule
