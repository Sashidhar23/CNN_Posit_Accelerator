`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2026 14:33:22
// Design Name: 
// Module Name: tb_posit_mac
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




module tb_posit_mac;

    parameter N  = 8;
    parameter ES = 1;

    //--------------------------------------------------
    // DUT signals
    //--------------------------------------------------
    reg              clk;
    reg              reset;
    reg              enable;
    reg              clear;

    reg  [N-1:0]     a;
    reg  [N-1:0]     b;

    wire [N-1:0]     product;
    wire [N-1:0]     mac_out;
    wire [N-1:0]     acc;

    integer errors;

    //--------------------------------------------------
    // DUT instance
    //--------------------------------------------------
    posit_mac #(
        .N(N),
        .ES(ES)
    ) DUT (
        .clk     (clk),
        .reset   (reset),
        .enable  (enable),
        .clear   (clear),
        .a       (a),
        .b       (b),
        .product (product),
        .mac_out (mac_out),
        .acc     (acc)
    );

    //--------------------------------------------------
    // Clock generation
    //--------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 10 ns clock period
    end

    //--------------------------------------------------
    // One MAC operation
    //--------------------------------------------------
    task mac_step;
        input [N-1:0] a_in;
        input [N-1:0] b_in;
        input [N-1:0] expected_product;
        input [N-1:0] expected_mac_out;
        input [N-1:0] expected_acc;
        input [511:0] name;

        begin
            a      = a_in;
            b      = b_in;
            enable = 1'b1;
            clear  = 1'b0;

            #1;

            $display("------------------------------------------");
            $display("%0s", name);
            $display("A       = %b", a);
            $display("B       = %b", b);
            $display("PRODUCT = %b  EXP = %b", product, expected_product);
            $display("MAC_OUT = %b  EXP = %b", mac_out, expected_mac_out);

            if (product !== expected_product) begin
                $display("PRODUCT FAIL");
                errors = errors + 1;
            end
            else if (mac_out !== expected_mac_out) begin
                $display("MAC_OUT FAIL");
                errors = errors + 1;
            end
            else begin
                $display("COMB PASS");
            end

            @(posedge clk);
            #1;

            $display("ACC     = %b  EXP = %b", acc, expected_acc);

            if (acc !== expected_acc) begin
                $display("ACC FAIL");
                errors = errors + 1;
            end
            else begin
                $display("ACC PASS");
            end

            enable = 1'b0;
        end
    endtask

    //--------------------------------------------------
    // Check visible MAC state
    //--------------------------------------------------
    task check_state;
        input [N-1:0] expected_product;
        input [N-1:0] expected_mac_out;
        input [N-1:0] expected_acc;
        input [511:0] name;

        begin
            #1;

            $display("------------------------------------------");
            $display("%0s", name);
            $display("A       = %b", a);
            $display("B       = %b", b);
            $display("PRODUCT = %b  EXP = %b", product, expected_product);
            $display("MAC_OUT = %b  EXP = %b", mac_out, expected_mac_out);
            $display("ACC     = %b  EXP = %b", acc, expected_acc);

            if (product !== expected_product || mac_out !== expected_mac_out || acc !== expected_acc) begin
                $display("FAIL");
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
        end
    endtask

    //--------------------------------------------------
    // Clear accumulator
    //--------------------------------------------------
    task clear_acc;
        begin
            clear  = 1'b1;
            enable = 1'b0;
            a      = {N{1'b0}};
            b      = {N{1'b0}};

            @(posedge clk);
            #1;

            clear = 1'b0;

            check_state(8'b00000000, 8'b00000000, 8'b00000000, "clear gives zero");
        end
    endtask

    //--------------------------------------------------
    // Test sequence
    //--------------------------------------------------
    initial begin
        errors = 0;

        reset  = 1'b1;
        clear  = 1'b0;
        enable = 1'b0;
        a      = {N{1'b0}};
        b      = {N{1'b0}};

        $display("==========================================");
        $display("          POSIT MAC TESTBENCH");
        $display("==========================================");

        //--------------------------------------------------
        // Reset
        //--------------------------------------------------
        @(posedge clk);
        #1;
        reset = 1'b0;

        check_state(
            8'b00000000,
            8'b00000000,
            8'b00000000,
            "T1 : After Reset"
        );

        //--------------------------------------------------
        // Test 2:
        // acc = 0 + (1 * 1) = 1
        //--------------------------------------------------
        clear_acc();

        mac_step(
            8'b01000000,   // +1
            8'b01000000,   // +1
            8'b01000000,   // product = +1
            8'b01000000,   // mac_out = 0 + 1
            8'b01000000,   // acc = +1
            "T2 Step : 1 * 1"
        );

        //--------------------------------------------------
        // Test 3:
        // acc = 1 + (1 * 1) = 2
        //--------------------------------------------------
        mac_step(
            8'b01000000,   // +1
            8'b01000000,   // +1
            8'b01000000,   // product = +1
            8'b01010000,   // mac_out = 1 + 1
            8'b01010000,   // acc = +2
            "T3 Step : ACC + 1*1"
        );

        //--------------------------------------------------
        // Test 4:
        // enable low should hold acc, even if inputs change
        //--------------------------------------------------
        enable = 1'b0;
        clear  = 1'b0;
        a      = 8'b01010000;   // +2
        b      = 8'b01010000;   // +2

        @(posedge clk);
        check_state(
            8'b01100000,   // product = +4
            8'b01100100,   // mac_out = held acc 2 + product 4 = 6
            8'b01010000,   // acc still +2
            "T4 : Enable low holds ACC"
        );

        //--------------------------------------------------
        // Test 5:
        // Clear, then acc = 0 + (2 * 2) = 4
        //--------------------------------------------------
        clear_acc();

        mac_step(
            8'b01010000,   // +2
            8'b01010000,   // +2
            8'b01100000,   // product = +4
            8'b01100000,   // mac_out = 0 + 4
            8'b01100000,   // acc = +4
            "T5 Step : 2 * 2"
        );

        //--------------------------------------------------
        // Test 6:
        // acc = 4 + (1 * -1) = 3
        //--------------------------------------------------
        mac_step(
            8'b01000000,   // +1
            8'b11000000,   // -1
            8'b11000000,   // product = -1
            8'b01011000,   // mac_out = 4 + (-1)
            8'b01011000,   // acc = +3
            "T6 Step : ACC + 1*(-1)"
        );

        //--------------------------------------------------
        // Test 7:
        // Clear, then acc = 0 + (-1 * -1) = +1
        //--------------------------------------------------
        clear_acc();

        mac_step(
            8'b11000000,   // -1
            8'b11000000,   // -1
            8'b01000000,   // product = +1
            8'b01000000,   // mac_out = 0 + 1
            8'b01000000,   // acc = +1
            "T7 Step : (-1) * (-1)"
        );

        //--------------------------------------------------
        // Test 8:
        // acc = 1 + (0.5 * 2) = 2
        //
        // 0.5 = 00110000
        // 2   = 01010000
        //--------------------------------------------------
        mac_step(
            8'b00110000,   // +0.5
            8'b01010000,   // +2
            8'b01000000,   // product = +1
            8'b01010000,   // mac_out = 1 + 1
            8'b01010000,   // acc = +2
            "T8 Step : ACC + 0.5*2"
        );

        //--------------------------------------------------
        // Test 9:
        // NaR should poison result
        //--------------------------------------------------
        clear_acc();

        mac_step(
            8'b10000000,   // NaR
            8'b01000000,   // +1
            8'b10000000,   // product = NaR
            8'b10000000,   // mac_out = NaR
            8'b10000000,   // acc = NaR
            "T9 Step : NaR * 1"
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
