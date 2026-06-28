`timescale 1ns / 1ps

module tb_pe_quire;

    //--------------------------------------------------
    // Parameters
    //--------------------------------------------------
    parameter N  = 8;
    parameter ES = 1;
    parameter QW = 128;
    parameter QF = 64;

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
    wire signed [QW-1:0] psum_in;
    wire             psum_nar_in;

    wire [N-1:0]     input_out;
    wire [N-1:0]     weight_out;
    wire signed [QW-1:0] quire_out;
    wire             is_nar;
    wire signed [QW-1:0] psum_out;
    wire             psum_nar_out;
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
    localparam [7:0] POSIT_NAR   = 8'h80;

    //--------------------------------------------------
    // Exact quire constants for QF=64
    //--------------------------------------------------
    localparam signed [QW-1:0] QUIRE_ZERO  = {QW{1'b0}};
    localparam signed [QW-1:0] QUIRE_HALF  = $signed(128'd1 <<< (QF-1));
    localparam signed [QW-1:0] QUIRE_ONE   = $signed(128'd1 <<< QF);
    localparam signed [QW-1:0] QUIRE_TWO   = $signed(128'd2 <<< QF);
    localparam signed [QW-1:0] QUIRE_THREE = $signed(128'd3 <<< QF);
    localparam signed [QW-1:0] QUIRE_3P5   = $signed(128'd7 <<< (QF-1));

    //--------------------------------------------------
    // DUT
    //--------------------------------------------------
    pe_quire #(
        .N(N),
        .ES(ES),
        .QW(QW),
        .QF(QF)
    ) DUT (
        .clk       (clk),
        .reset     (reset),
        .pe_en     (pe_en),
        .clear_acc (clear_acc),
        .wshift    (wshift),
        .input_in  (input_in),
        .weight_in (weight_in),
        .psum_in   (psum_in),
        .psum_nar_in(psum_nar_in),
        .input_out (input_out),
        .weight_out(weight_out),
        .quire_out (quire_out),
        .is_nar    (is_nar),
        .psum_out  (psum_out),
        .psum_nar_out(psum_nar_out),
        .pe_output (pe_output)
    );

    assign psum_in = QUIRE_ZERO;
    assign psum_nar_in = 1'b0;

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
        input signed [QW-1:0] expected_quire;
        input [N-1:0] expected_pe_output;
        input expected_nar;
        input [511:0] name;
        begin
            $display("------------------------------------------");
            $display("%0s", name);
            $display("INPUT_IN  = %b", input_in);
            $display("INPUT_OUT = %b  EXP = %b", input_out, expected_input_out);
            $display("WEIGHT    = %b  EXP = %b", weight_out, expected_weight_out);
            $display("QUIRE     = %0d", quire_out);
            $display("QEXP      = %0d", expected_quire);
            $display("PE_OUT    = %b  EXP = %b", pe_output, expected_pe_output);
            $display("NAR       = %b  EXP = %b", is_nar, expected_nar);

            if (input_out  !== expected_input_out ||
                weight_out !== expected_weight_out ||
                quire_out !== expected_quire ||
                pe_output !== expected_pe_output ||
                is_nar !== expected_nar) begin
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
            wshift    = 1'b1;
            weight_in = weight;
            @(posedge clk);
            #1;

            wshift    = 1'b0;
            weight_in = POSIT_ZERO;

            check_state(
                POSIT_ZERO,
                weight,
                QUIRE_ZERO,
                POSIT_ZERO,
                1'b0,
                "Load weight"
            );
        end
    endtask

    //--------------------------------------------------
    // Clear quire accumulator only
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
                QUIRE_ZERO,
                POSIT_ZERO,
                1'b0,
                "Clear accumulator"
            );
        end
    endtask

    //--------------------------------------------------
    // Stream one activation through the PE.
    //
    // The quire MAC uses the registered activation. Therefore:
    //   cycle 1 captures activation and shows held quire
    //   cycle 2 accumulates that captured activation
    //--------------------------------------------------
    task stream_activation;
        input [N-1:0] activation;
        input signed [QW-1:0] expected_quire_before;
        input [N-1:0] expected_output_before;
        input signed [QW-1:0] expected_quire_after;
        input [N-1:0] expected_output_after;
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
                expected_quire_before,
                expected_output_before,
                1'b0,
                name
            );

            @(posedge clk);
            #1;

            check_state(
                POSIT_ZERO,
                POSIT_ONE,
                expected_quire_after,
                expected_output_after,
                1'b0,
                "Flush registered activation into quire"
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

        $dumpfile("tb_pe_quire.vcd");
        $dumpvars(0, tb_pe_quire);

        $display("==========================================");
        $display("          PE QUIRE TESTBENCH");
        $display("==========================================");

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        check_state(
            POSIT_ZERO,
            POSIT_ZERO,
            QUIRE_ZERO,
            POSIT_ZERO,
            1'b0,
            "T1 : Reset clears PE-quire state"
        );

        load_weight(POSIT_ONE);
        clear_pe_acc(POSIT_ONE);

        stream_activation(
            POSIT_ONE,
            QUIRE_ZERO,
            POSIT_ZERO,
            QUIRE_ONE,
            POSIT_ONE,
            "T2 : Capture activation 1.0"
        );

        stream_activation(
            POSIT_TWO,
            QUIRE_ONE,
            POSIT_ONE,
            QUIRE_THREE,
            POSIT_THREE,
            "T3 : Capture activation 2.0"
        );

        stream_activation(
            POSIT_HALF,
            QUIRE_THREE,
            POSIT_THREE,
            QUIRE_3P5,
            POSIT_3P5,
            "T4 : Capture activation 0.5"
        );

        //--------------------------------------------------
        // pe_en low must hold input_out and quire accumulator.
        //--------------------------------------------------
        pe_en    = 1'b0;
        input_in = POSIT_TWO;
        @(posedge clk);
        #1;

        check_state(
            POSIT_ZERO,
            POSIT_ONE,
            QUIRE_3P5,
            POSIT_3P5,
            1'b0,
            "T5 : PE disabled holds activation register and quire"
        );

        //--------------------------------------------------
        // NaR should poison rounded output until clear.
        //--------------------------------------------------
        pe_en    = 1'b1;
        input_in = POSIT_NAR;
        @(posedge clk);
        #1;
        input_in = POSIT_ZERO;

        check_state(
            POSIT_NAR,
            POSIT_ONE,
            QUIRE_3P5,
            POSIT_3P5,
            1'b0,
            "T6 : Capture NaR activation"
        );

        @(posedge clk);
        #1;

        check_state(
            POSIT_ZERO,
            POSIT_ONE,
            QUIRE_3P5,
            POSIT_NAR,
            1'b1,
            "T7 : NaR poisons quire output"
        );

        clear_pe_acc(POSIT_ONE);

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;
    end

endmodule
