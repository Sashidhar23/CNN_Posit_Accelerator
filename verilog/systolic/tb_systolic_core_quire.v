`timescale 1ns / 1ps

module tb_systolic_core_quire;

    parameter N = 8;
    parameter ES = 1;
    parameter ROWS = 6;
    parameter COLS = 6;
    parameter QW = 128;
    parameter QF = 64;
    parameter IN_COUNT_W = $clog2(ROWS + 1);
    parameter OUT_COUNT_W = $clog2(COLS + 1);

    reg clk;
    reg reset;
    reg pe_en;
    reg clear_acc;
    reg wshift;
    reg [ROWS*N-1:0] activation_in;
    reg [ROWS*COLS*N-1:0] weight_in;
    reg input_clear;
    reg input_write_en;
    reg input_read_en;
    reg output_clear;
    reg output_write_en;
    reg output_read_en;

    wire [ROWS*N-1:0] fifo_activation;
    wire [ROWS*N-1:0] skewed_activation;
    wire [ROWS*N-1:0] activation_out;
    wire [ROWS*COLS*N-1:0] weight_out;
    wire [ROWS*COLS*QW-1:0] quire_out;
    wire [ROWS*COLS-1:0] is_nar;
    wire [ROWS*COLS*N-1:0] pe_output;
    wire [COLS*QW-1:0] column_quire_out;
    wire [COLS-1:0] column_is_nar;
    wire [COLS*N-1:0] column_psum_out;
    wire [COLS*N-1:0] buffered_pe_output;
    wire [ROWS-1:0] input_full;
    wire [ROWS-1:0] input_empty;
    wire [ROWS*IN_COUNT_W-1:0] input_count;
    wire [COLS-1:0] output_full;
    wire [COLS-1:0] output_empty;
    wire [COLS*OUT_COUNT_W-1:0] output_count;

    integer errors;

    localparam [7:0] POSIT_ZERO = 8'h00;
    localparam [7:0] POSIT_ONE  = 8'h40;
    localparam signed [QW-1:0] QUIRE_ZERO = {QW{1'b0}};
    localparam signed [QW-1:0] QUIRE_ONE  = $signed(128'd1 <<< QF);

    systolic_core_quire #(
        .N(N),
        .ES(ES),
        .ROWS(ROWS),
        .COLS(COLS),
        .QW(QW),
        .QF(QF),
        .IN_COUNT_W(IN_COUNT_W),
        .OUT_COUNT_W(OUT_COUNT_W)
    ) DUT (
        .clk                (clk),
        .reset              (reset),
        .pe_en              (pe_en),
        .clear_acc          (clear_acc),
        .wshift             (wshift),
        .activation_in      (activation_in),
        .weight_in          (weight_in),
        .input_clear        (input_clear),
        .input_write_en     (input_write_en),
        .input_read_en      (input_read_en),
        .output_clear       (output_clear),
        .output_write_en    (output_write_en),
        .output_read_en     (output_read_en),
        .fifo_activation    (fifo_activation),
        .skewed_activation  (skewed_activation),
        .activation_out     (activation_out),
        .weight_out         (weight_out),
        .quire_out          (quire_out),
        .is_nar             (is_nar),
        .pe_output          (pe_output),
        .column_quire_out   (column_quire_out),
        .column_is_nar      (column_is_nar),
        .column_psum_out    (column_psum_out),
        .buffered_pe_output (buffered_pe_output),
        .input_full         (input_full),
        .input_empty        (input_empty),
        .input_count        (input_count),
        .output_full        (output_full),
        .output_empty       (output_empty),
        .output_count       (output_count)
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

    task check_col_vector;
        input [COLS*N-1:0] actual;
        input [N-1:0] expected;
        input [511:0] name;
        integer c;
        integer local_errors;
        begin
            local_errors = 0;
            $display("------------------------------------------");
            $display("%0s", name);

            for (c = 0; c < COLS; c = c + 1) begin
                if (actual[c*N +: N] !== expected) begin
                    $display("FAIL col%0d actual=%h expected=%h",
                             c, actual[c*N +: N], expected);
                    local_errors = local_errors + 1;
                    errors = errors + 1;
                end
            end

            if (local_errors == 0)
                $display("PASS");
        end
    endtask

    task check_col_quire;
        input signed [QW-1:0] expected;
        input [511:0] name;
        integer c;
        integer local_errors;
        begin
            local_errors = 0;
            $display("------------------------------------------");
            $display("%0s", name);

            for (c = 0; c < COLS; c = c + 1) begin
                if (column_quire_out[c*QW +: QW] !== expected ||
                    column_is_nar[c] !== 1'b0) begin
                    $display("FAIL col%0d quire=%0d expected=%0d nar=%b",
                             c, $signed(column_quire_out[c*QW +: QW]),
                             expected, column_is_nar[c]);
                    local_errors = local_errors + 1;
                    errors = errors + 1;
                end
            end

            if (local_errors == 0)
                $display("PASS");
        end
    endtask

    task check_row_vector;
        input [ROWS*N-1:0] actual;
        input [N-1:0] exp0;
        input [N-1:0] exp1;
        input [N-1:0] exp2;
        input [N-1:0] exp3;
        input [N-1:0] exp4;
        input [N-1:0] exp5;
        input [511:0] name;
        reg [ROWS*N-1:0] expected;
        begin
            expected = {ROWS*N{1'b0}};
            expected[0*N +: N] = exp0;
            expected[1*N +: N] = exp1;
            expected[2*N +: N] = exp2;
            expected[3*N +: N] = exp3;
            expected[4*N +: N] = exp4;
            expected[5*N +: N] = exp5;

            $display("------------------------------------------");
            $display("%0s", name);

            if (actual !== expected) begin
                $display("FAIL actual=%h expected=%h", actual, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
        end
    endtask

    task check_weights;
        integer i;
        integer local_errors;
        begin
            local_errors = 0;
            $display("------------------------------------------");
            $display("Stationary weights loaded");

            for (i = 0; i < ROWS*COLS; i = i + 1) begin
                if (weight_out[i*N +: N] !== POSIT_ONE) begin
                    $display("FAIL weight[%0d]=%h", i, weight_out[i*N +: N]);
                    local_errors = local_errors + 1;
                    errors = errors + 1;
                end
            end

            if (local_errors == 0)
                $display("PASS");
        end
    endtask

    task load_weights;
        begin
            set_all_weights(POSIT_ONE);
            wshift = 1'b1;
            @(posedge clk);
            #1;
            wshift = 1'b0;
            weight_in = {ROWS*COLS*N{1'b0}};
        end
    endtask

    task enqueue_row0_one;
        begin
            drive_activation(POSIT_ONE, POSIT_ZERO, POSIT_ZERO,
                             POSIT_ZERO, POSIT_ZERO, POSIT_ZERO);
            input_write_en = 1'b1;
            @(posedge clk);
            #1;
            input_write_en = 1'b0;
            drive_activation(POSIT_ZERO, POSIT_ZERO, POSIT_ZERO,
                             POSIT_ZERO, POSIT_ZERO, POSIT_ZERO);
        end
    endtask

    task prefetch_inputs;
        begin
            input_read_en = 1'b1;
            @(posedge clk);
            #1;
            input_read_en = 1'b0;
        end
    endtask

    task run_until_buffered_one;
        integer cycle;
        integer seen;
        begin
            seen = 0;
            pe_en = 1'b1;
            output_write_en = 1'b1;
            output_read_en = 1'b1;

            for (cycle = 0; cycle < 80 && !seen; cycle = cycle + 1) begin
                @(posedge clk);
                #1;
                if (buffered_pe_output === {COLS{POSIT_ONE}})
                    seen = 1;
            end

            output_write_en = 1'b0;
            output_read_en = 1'b0;
            pe_en = 1'b0;
            #1;

            $display("------------------------------------------");
            $display("Output FIFO group produces synchronized rounded column psums");
            if (!seen) begin
                $display("FAIL buffered output never became all 1.0, final=%h", buffered_pe_output);
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
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
        input_clear = 1'b0;
        input_write_en = 1'b0;
        input_read_en = 1'b0;
        output_clear = 1'b0;
        output_write_en = 1'b0;
        output_read_en = 1'b0;

        $display("==========================================");
        $display("      WS SYSTOLIC CORE QUIRE TESTBENCH");
        $display("==========================================");

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        check_col_vector(column_psum_out, POSIT_ZERO, "Reset clears rounded column psums");
        check_col_quire(QUIRE_ZERO, "Reset clears column quires");

        load_weights();
        check_weights();

        clear_acc = 1'b1;
        @(posedge clk);
        #1;
        clear_acc = 1'b0;

        enqueue_row0_one();
        prefetch_inputs();
        check_row_vector(fifo_activation, POSIT_ONE, POSIT_ZERO, POSIT_ZERO,
                         POSIT_ZERO, POSIT_ZERO, POSIT_ZERO,
                         "Input FIFO prefetch presents one activation vector");
        check_row_vector(skewed_activation, POSIT_ONE, POSIT_ZERO, POSIT_ZERO,
                         POSIT_ZERO, POSIT_ZERO, POSIT_ZERO,
                         "Valid-gated FIFO drives row0 once");

        run_until_buffered_one();

        pe_en = 1'b0;
        repeat (4) @(posedge clk);
        #1;
        check_col_vector(buffered_pe_output, POSIT_ONE,
                         "pe_en low holds last synchronized buffered output");

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;
    end

endmodule
