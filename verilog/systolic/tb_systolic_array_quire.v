`timescale 1ns / 1ps

module tb_systolic_array_quire;

    parameter N = 8;
    parameter ES = 1;
    parameter ROWS = 6;
    parameter COLS = 6;
    parameter QW = 128;
    parameter QF = 64;

    reg                         clk;
    reg                         reset;
    reg                         pe_en;
    reg                         clear_acc;
    reg                         wshift;
    reg  [ROWS*N-1:0]           activation_in;
    reg  [ROWS*COLS*N-1:0]      weight_in;

    wire [ROWS*N-1:0]           activation_out;
    wire [ROWS*COLS*N-1:0]      weight_out;
    wire [ROWS*COLS*QW-1:0]     quire_out;
    wire [ROWS*COLS-1:0]        is_nar;
    wire [ROWS*COLS*N-1:0]      pe_output;

    integer errors;

    localparam [7:0] POSIT_ZERO  = 8'h00;
    localparam [7:0] POSIT_HALF  = 8'h30;
    localparam [7:0] POSIT_ONE   = 8'h40;
    localparam [7:0] POSIT_TWO   = 8'h50;
    localparam [7:0] POSIT_THREE = 8'h58;

    localparam signed [QW-1:0] QUIRE_ZERO  = {QW{1'b0}};
    localparam signed [QW-1:0] QUIRE_HALF  = $signed(128'd1 <<< (QF-1));
    localparam signed [QW-1:0] QUIRE_ONE   = $signed(128'd1 <<< QF);
    localparam signed [QW-1:0] QUIRE_TWO   = $signed(128'd2 <<< QF);
    localparam signed [QW-1:0] QUIRE_THREE = $signed(128'd3 <<< QF);

    systolic_array_quire #(
        .N(N),
        .ES(ES),
        .ROWS(ROWS),
        .COLS(COLS),
        .QW(QW),
        .QF(QF)
    ) DUT (
        .clk            (clk),
        .reset          (reset),
        .pe_en          (pe_en),
        .clear_acc      (clear_acc),
        .wshift         (wshift),
        .activation_in  (activation_in),
        .weight_in      (weight_in),
        .activation_out (activation_out),
        .weight_out     (weight_out),
        .quire_out      (quire_out),
        .is_nar         (is_nar),
        .pe_output      (pe_output)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task drive_activation;
        input [N-1:0] row0;
        input [N-1:0] row1;
        input [N-1:0] row2;
        input [N-1:0] row3;
        input [N-1:0] row4;
        input [N-1:0] row5;
        begin
            activation_in[0*N +: N] = row0;
            activation_in[1*N +: N] = row1;
            activation_in[2*N +: N] = row2;
            activation_in[3*N +: N] = row3;
            activation_in[4*N +: N] = row4;
            activation_in[5*N +: N] = row5;
        end
    endtask

    task set_all_weights;
        input [N-1:0] weight;
        integer i;
        begin
            for (i = 0; i < ROWS*COLS; i = i + 1)
                weight_in[i*N +: N] = weight;
        end
    endtask

    task load_stationary_weights;
        input [N-1:0] weight;
        begin
            set_all_weights(weight);
            wshift = 1'b1;
            @(posedge clk);
            #1;
            wshift = 1'b0;
            weight_in = {ROWS*COLS*N{1'b0}};
        end
    endtask

    task clear_array_accumulators;
        begin
            clear_acc = 1'b1;
            pe_en = 1'b0;
            drive_activation(POSIT_ZERO, POSIT_ZERO, POSIT_ZERO,
                             POSIT_ZERO, POSIT_ZERO, POSIT_ZERO);
            @(posedge clk);
            #1;
            clear_acc = 1'b0;
        end
    endtask

    task stream_vector_and_flush;
        input [N-1:0] row0;
        input [N-1:0] row1;
        input [N-1:0] row2;
        input [N-1:0] row3;
        input [N-1:0] row4;
        input [N-1:0] row5;
        begin
            pe_en = 1'b1;
            drive_activation(row0, row1, row2, row3, row4, row5);
            @(posedge clk);
            #1;

            drive_activation(POSIT_ZERO, POSIT_ZERO, POSIT_ZERO,
                             POSIT_ZERO, POSIT_ZERO, POSIT_ZERO);
            repeat (COLS + 1) @(posedge clk);
            #1;
        end
    endtask

    task check_reset_state;
        input [511:0] name;
        integer i;
        integer local_errors;
        begin
            local_errors = 0;

            $display("------------------------------------------");
            $display("%0s", name);

            if (activation_out !== {ROWS*N{1'b0}}) begin
                $display("FAIL activation_out = %h expected all zero", activation_out);
                local_errors = local_errors + 1;
                errors = errors + 1;
            end

            if (is_nar !== {ROWS*COLS{1'b0}}) begin
                $display("FAIL is_nar = %h expected all zero", is_nar);
                local_errors = local_errors + 1;
                errors = errors + 1;
            end

            for (i = 0; i < ROWS*COLS; i = i + 1) begin
                if (weight_out[i*N +: N] !== POSIT_ZERO ||
                    pe_output[i*N +: N] !== POSIT_ZERO ||
                    quire_out[i*QW +: QW] !== QUIRE_ZERO) begin
                    $display("FAIL PE[%0d] weight=%h output=%h quire=%0d expected zero",
                             i,
                             weight_out[i*N +: N],
                             pe_output[i*N +: N],
                             $signed(quire_out[i*QW +: QW]));
                    local_errors = local_errors + 1;
                    errors = errors + 1;
                end
            end

            if (local_errors == 0)
                $display("PASS");
        end
    endtask

    task check_all_weights;
        input [N-1:0] expected_weight;
        input [511:0] name;
        integer i;
        integer local_errors;
        begin
            local_errors = 0;

            $display("------------------------------------------");
            $display("%0s", name);

            for (i = 0; i < ROWS*COLS; i = i + 1) begin
                if (weight_out[i*N +: N] !== expected_weight) begin
                    $display("FAIL PE[%0d] weight=%h expected=%h",
                             i, weight_out[i*N +: N], expected_weight);
                    local_errors = local_errors + 1;
                    errors = errors + 1;
                end
            end

            if (local_errors == 0)
                $display("PASS");
        end
    endtask

    task check_outputs_by_row;
        input [N-1:0] exp0;
        input [N-1:0] exp1;
        input [N-1:0] exp2;
        input [N-1:0] exp3;
        input [N-1:0] exp4;
        input [N-1:0] exp5;
        input signed [QW-1:0] qexp0;
        input signed [QW-1:0] qexp1;
        input signed [QW-1:0] qexp2;
        input signed [QW-1:0] qexp3;
        input signed [QW-1:0] qexp4;
        input signed [QW-1:0] qexp5;
        input [511:0] name;
        integer r;
        integer c;
        integer idx;
        integer local_errors;
        reg [N-1:0] expected;
        reg signed [QW-1:0] expected_quire;
        begin
            local_errors = 0;

            $display("------------------------------------------");
            $display("%0s", name);

            for (r = 0; r < ROWS; r = r + 1) begin
                case (r)
                    0: begin expected = exp0; expected_quire = qexp0; end
                    1: begin expected = exp1; expected_quire = qexp1; end
                    2: begin expected = exp2; expected_quire = qexp2; end
                    3: begin expected = exp3; expected_quire = qexp3; end
                    4: begin expected = exp4; expected_quire = qexp4; end
                    default: begin expected = exp5; expected_quire = qexp5; end
                endcase

                for (c = 0; c < COLS; c = c + 1) begin
                    idx = r*COLS + c;
                    if (pe_output[idx*N +: N] !== expected ||
                        quire_out[idx*QW +: QW] !== expected_quire ||
                        is_nar[idx] !== 1'b0) begin
                        $display("FAIL PE[%0d,%0d] output=%h expected=%h quire=%0d qexp=%0d nar=%b",
                                 r, c,
                                 pe_output[idx*N +: N],
                                 expected,
                                 $signed(quire_out[idx*QW +: QW]),
                                 expected_quire,
                                 is_nar[idx]);
                        local_errors = local_errors + 1;
                        errors = errors + 1;
                    end
                end
            end

            if (activation_out !== {ROWS*N{1'b0}}) begin
                $display("FAIL activation_out = %h expected all zero after flush", activation_out);
                local_errors = local_errors + 1;
                errors = errors + 1;
            end

            if (local_errors == 0)
                $display("PASS");
        end
    endtask

    initial begin
        errors = 0;

        reset = 1'b1;
        pe_en = 1'b0;
        clear_acc = 1'b0;
        wshift = 1'b0;
        activation_in = {ROWS*N{1'b0}};
        weight_in = {ROWS*COLS*N{1'b0}};

        $dumpfile("tb_systolic_array_quire.vcd");
        $dumpvars(0, tb_systolic_array_quire);

        $display("==========================================");
        $display("     6x6 QUIRE SYSTOLIC ARRAY TESTBENCH");
        $display("==========================================");

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        check_reset_state("T1 : Reset clears quire array state");

        load_stationary_weights(POSIT_ONE);
        check_all_weights(POSIT_ONE, "T2 : All PE-quire weights loaded and held stationary");

        clear_array_accumulators();
        check_outputs_by_row(POSIT_ZERO, POSIT_ZERO, POSIT_ZERO,
                             POSIT_ZERO, POSIT_ZERO, POSIT_ZERO,
                             QUIRE_ZERO, QUIRE_ZERO, QUIRE_ZERO,
                             QUIRE_ZERO, QUIRE_ZERO, QUIRE_ZERO,
                             "T3 : Clear quire accumulators keeps stationary weights");
        check_all_weights(POSIT_ONE, "T4 : Weights still stationary after clear");

        stream_vector_and_flush(POSIT_ONE, POSIT_TWO, POSIT_HALF,
                                POSIT_ONE, POSIT_TWO, POSIT_HALF);
        check_outputs_by_row(POSIT_ONE, POSIT_TWO, POSIT_HALF,
                             POSIT_ONE, POSIT_TWO, POSIT_HALF,
                             QUIRE_ONE, QUIRE_TWO, QUIRE_HALF,
                             QUIRE_ONE, QUIRE_TWO, QUIRE_HALF,
                             "T5 : First activation vector reaches every PE-quire in its row");

        stream_vector_and_flush(POSIT_TWO, POSIT_ONE, POSIT_HALF,
                                POSIT_TWO, POSIT_ONE, POSIT_HALF);
        check_outputs_by_row(POSIT_THREE, POSIT_THREE, POSIT_ONE,
                             POSIT_THREE, POSIT_THREE, POSIT_ONE,
                             QUIRE_THREE, QUIRE_THREE, QUIRE_ONE,
                             QUIRE_THREE, QUIRE_THREE, QUIRE_ONE,
                             "T6 : Second activation vector accumulates in every quire");

        pe_en = 1'b0;
        drive_activation(POSIT_TWO, POSIT_TWO, POSIT_TWO,
                         POSIT_TWO, POSIT_TWO, POSIT_TWO);
        repeat (2) @(posedge clk);
        #1;
        check_outputs_by_row(POSIT_THREE, POSIT_THREE, POSIT_ONE,
                             POSIT_THREE, POSIT_THREE, POSIT_ONE,
                             QUIRE_THREE, QUIRE_THREE, QUIRE_ONE,
                             QUIRE_THREE, QUIRE_THREE, QUIRE_ONE,
                             "T7 : pe_en low holds activation movement and quire accumulators");

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;
    end

endmodule
