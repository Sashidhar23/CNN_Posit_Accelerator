`timescale 1ns / 1ps

module tb_pe;

    //--------------------------------------------------
    // Parameters
    //--------------------------------------------------
    parameter N  = 8;
    parameter ES = 1;

    //--------------------------------------------------
    // DUT signals
    //--------------------------------------------------
    reg              clk;
    reg              reset;
    reg              pe_en;
    reg              clear_acc;
    reg              wshift;

    reg  [N-1:0]     input_in;
    reg  [N-1:0]     weight_in;
    wire [N-1:0]     psum_in;

    wire [N-1:0]     input_out;
    wire [N-1:0]     weight_out;
    wire [N-1:0]     product_out;
    wire [N-1:0]     mac_out;
    wire [N-1:0]     psum_out;
    wire [N-1:0]     pe_output;

    integer errors;

    //--------------------------------------------------
    // Posit constants for posit<8,1>
    //--------------------------------------------------
    localparam [7:0] POSIT_ZERO  = 8'h00;
    localparam [7:0] POSIT_HALF  = 8'h30;
    localparam [7:0] POSIT_ONE   = 8'h40;
    localparam [7:0] POSIT_TWO   = 8'h50;
    localparam [7:0] POSIT_THREE = 8'h58;
    localparam [7:0] POSIT_3P5   = 8'h5C;

    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
    pe #(
        .N(N),
        .ES(ES)
    ) DUT (
        .clk         (clk),
        .reset       (reset),
        .pe_en       (pe_en),
        .clear_acc   (clear_acc),
        .wshift      (wshift),
        .input_in    (input_in),
        .weight_in   (weight_in),
        .psum_in     (psum_in),
        .input_out   (input_out),
        .weight_out  (weight_out),
        .product_out (product_out),
        .mac_out     (mac_out),
        .psum_out    (psum_out),
        .pe_output   (pe_output)
    );

    assign psum_in = POSIT_ZERO;

    //--------------------------------------------------
    // Clock generation
    //--------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------------
    // State checker
    //--------------------------------------------------
    task check_state;
        input [N-1:0] expected_input_out;
        input [N-1:0] expected_weight_out;
        input [N-1:0] expected_product;
        input [N-1:0] expected_mac_out;
        input [N-1:0] expected_pe_output;
        input [511:0] name;
        begin
            $display("------------------------------------------");
            $display("%0s", name);
            $display("INPUT_IN  = %b", input_in);
            $display("INPUT_OUT = %b  EXP = %b", input_out, expected_input_out);
            $display("WEIGHT    = %b  EXP = %b", weight_out, expected_weight_out);
            $display("PRODUCT   = %b  EXP = %b", product_out, expected_product);
            $display("MAC_OUT   = %b  EXP = %b", mac_out, expected_mac_out);
            $display("PE_OUT    = %b  EXP = %b", pe_output, expected_pe_output);

            if (input_out  !== expected_input_out ||
                weight_out !== expected_weight_out ||
                product_out !== expected_product ||
                mac_out !== expected_mac_out ||
                pe_output !== expected_pe_output) begin
                $display("FAIL");
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
        end
    endtask

    //--------------------------------------------------
    // Load stationary weight
    //--------------------------------------------------
    task load_weight;
        input [N-1:0] weight;
        begin
            wshift   = 1'b1;
            weight_in = weight;
            @(posedge clk);
            #1;

            wshift   = 1'b0;
            weight_in = POSIT_ZERO;

            check_state(
                POSIT_ZERO,
                weight,
                POSIT_ZERO,
                POSIT_ZERO,
                POSIT_ZERO,
                "Load weight"
            );
        end
    endtask

    //--------------------------------------------------
    // Clear MAC accumulator only
    //--------------------------------------------------
    task clear_pe_acc;
        input [N-1:0] expected_weight;
        begin
            clear_acc = 1'b1;
            pe_en     = 1'b0;
            input_in  = POSIT_ZERO;
            @(posedge clk);
            #1;

            clear_acc = 1'b0;

            check_state(
                POSIT_ZERO,
                expected_weight,
                POSIT_ZERO,
                POSIT_ZERO,
                POSIT_ZERO,
                "Clear accumulator"
            );
        end
    endtask

    //--------------------------------------------------
    // Stream one activation through the PE.
    //
    // The PE MAC uses the registered activation. Therefore:
    //   cycle 1 captures activation and shows comb product/mac_out
    //   cycle 2 accumulates that captured activation
    //--------------------------------------------------
    task stream_activation;
        input [N-1:0] activation;
        input [N-1:0] expected_product;
        input [N-1:0] expected_mac_before_acc;
        input [N-1:0] expected_acc_before;
        input [N-1:0] expected_acc_after;
        input [511:0] name;
        begin
            pe_en    = 1'b1;
            input_in = activation;
            @(posedge clk);
            #1;

            input_in = POSIT_ZERO;

            check_state(
                activation,
                POSIT_ONE,
                expected_product,
                expected_mac_before_acc,
                expected_acc_before,
                name
            );

            @(posedge clk);
            #1;

            check_state(
                POSIT_ZERO,
                POSIT_ONE,
                POSIT_ZERO,
                expected_acc_after,
                expected_acc_after,
                "Flush registered activation into accumulator"
            );
        end
    endtask

    //--------------------------------------------------
    // Main stimulus
    //--------------------------------------------------
    initial begin
        errors = 0;

        reset     = 1'b1;
        pe_en     = 1'b0;
        clear_acc = 1'b0;
        wshift    = 1'b0;
        input_in  = POSIT_ZERO;
        weight_in = POSIT_ZERO;

        $dumpfile("tb_pe.vcd");
        $dumpvars(0, tb_pe);

        $display("==========================================");
        $display("              PE TESTBENCH");
        $display("==========================================");

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        check_state(
            POSIT_ZERO,
            POSIT_ZERO,
            POSIT_ZERO,
            POSIT_ZERO,
            POSIT_ZERO,
            "T1 : Reset clears PE state"
        );

        load_weight(POSIT_ONE);
        clear_pe_acc(POSIT_ONE);

        stream_activation(
            POSIT_ONE,
            POSIT_ONE,
            POSIT_ONE,
            POSIT_ZERO,
            POSIT_ONE,
            "T2 : Capture activation 1.0"
        );

        stream_activation(
            POSIT_TWO,
            POSIT_TWO,
            POSIT_THREE,
            POSIT_ONE,
            POSIT_THREE,
            "T3 : Capture activation 2.0"
        );

        stream_activation(
            POSIT_HALF,
            POSIT_HALF,
            POSIT_3P5,
            POSIT_THREE,
            POSIT_3P5,
            "T4 : Capture activation 0.5"
        );

        //--------------------------------------------------
        // pe_en low must hold input_out and accumulator.
        //--------------------------------------------------
        pe_en    = 1'b0;
        input_in = POSIT_TWO;
        @(posedge clk);
        #1;

        check_state(
            POSIT_ZERO,
            POSIT_ONE,
            POSIT_ZERO,
            POSIT_3P5,
            POSIT_3P5,
            "T5 : PE disabled holds activation register and accumulator"
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
