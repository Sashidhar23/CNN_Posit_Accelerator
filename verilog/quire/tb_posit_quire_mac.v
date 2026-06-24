`timescale 1ns / 1ps

module tb_posit_quire_mac;

    parameter N  = 8;
    parameter ES = 1;
    parameter QW = 128;
    parameter QF = 64;

    reg clk;
    reg rst;
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
        .rst       (rst),
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
        begin
            posit_a = a;
            posit_b = b;
            enable = 1'b1;
            @(posedge clk);
            #1;
            enable = 1'b0;
        end
    endtask

    task check_out;
        input [N-1:0] expected;
        input [511:0] name;
        begin
            $display("------------------------------------------");
            $display("%0s", name);
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
        clk = 1'b0;
        rst = 1'b1;
        clear = 1'b0;
        enable = 1'b0;
        posit_a = 0;
        posit_b = 0;
        errors = 0;

        $display("==========================================");
        $display("       POSIT QUIRE MAC TESTBENCH");
        $display("==========================================");

        repeat (2) @(posedge clk);
        rst = 1'b0;
        #1;
        check_out(8'b00000000, "T1 : Reset gives zero");

        mac_once(8'b01000000, 8'b01000000);
        check_out(8'b01000000, "T2 : 1 * 1 accumulated = 1");

        mac_once(8'b01000000, 8'b01000000);
        check_out(8'b01010000, "T3 : 1 + 1 accumulated = 2");

        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;

        mac_once(8'b01010000, 8'b01010000);
        check_out(8'b01100000, "T4 : 2 * 2 accumulated = 4");

        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;

        mac_once(8'b11000000, 8'b01000000);
        check_out(8'b11000000, "T5 : -1 * 1 accumulated = -1");

        mac_once(8'b10000000, 8'b01000000);
        check_out(8'b10000000, "T6 : NaR input makes output NaR");

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;
    end

endmodule
