`timescale 1ns / 1ps

module tb_systolic_array;
    parameter N = 8;
    parameter ES = 1;
    parameter ROWS = 3;
    parameter COLS = 3;

    reg clk;
    reg reset;
    reg pe_en;
    reg clear_acc;
    reg wshift;
    reg [ROWS*N-1:0] activation_in;
    reg [ROWS*COLS*N-1:0] weight_in;

    wire [ROWS*N-1:0] activation_out;
    wire [ROWS*COLS*N-1:0] weight_out;
    wire [ROWS*COLS*N-1:0] product_out;
    wire [ROWS*COLS*N-1:0] mac_out;
    wire [COLS*N-1:0] psum_out;
    wire [ROWS*COLS*N-1:0] pe_output;

    integer errors;
    integer i;
    integer cycle;
    reg [COLS-1:0] seen_cols;

    localparam [N-1:0] POSIT_ZERO = 8'h00;
    localparam [N-1:0] POSIT_ONE  = 8'h40;

    systolic_array #(.N(N), .ES(ES), .ROWS(ROWS), .COLS(COLS)) DUT (
        .clk(clk),
        .reset(reset),
        .pe_en(pe_en),
        .clear_acc(clear_acc),
        .wshift(wshift),
        .activation_in(activation_in),
        .weight_in(weight_in),
        .activation_out(activation_out),
        .weight_out(weight_out),
        .product_out(product_out),
        .mac_out(mac_out),
        .psum_out(psum_out),
        .pe_output(pe_output)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task step;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check_vector;
        input [COLS*N-1:0] actual;
        input [COLS*N-1:0] expected;
        input [255:0] name;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%h expected=%h", name, actual, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %0s", name);
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

        repeat (2) step();
        reset = 1'b0;
        step();
        check_vector(psum_out, {COLS{POSIT_ZERO}}, "reset clears column psums");

        for (i = 0; i < ROWS*COLS; i = i + 1)
            weight_in[i*N +: N] = POSIT_ONE;
        wshift = 1'b1;
        step();
        wshift = 1'b0;
        weight_in = {ROWS*COLS*N{1'b0}};

        for (i = 0; i < ROWS*COLS; i = i + 1) begin
            if (weight_out[i*N +: N] !== POSIT_ONE) begin
                $display("FAIL weight[%0d]=%h expected=%h", i, weight_out[i*N +: N], POSIT_ONE);
                errors = errors + 1;
            end
        end

        clear_acc = 1'b1;
        step();
        clear_acc = 1'b0;

        seen_cols = {COLS{1'b0}};
        pe_en = 1'b1;
        activation_in[0*N +: N] = POSIT_ONE;
        for (cycle = 0; cycle < 40 && seen_cols !== {COLS{1'b1}}; cycle = cycle + 1) begin
            step();
            activation_in = {ROWS*N{1'b0}};
            for (i = 0; i < COLS; i = i + 1) begin
                if (psum_out[i*N +: N] === POSIT_ONE)
                    seen_cols[i] = 1'b1;
            end
        end
        pe_en = 1'b0;

        if (seen_cols !== {COLS{1'b1}}) begin
            $display("FAIL row0 activation did not reach every column seen=%b final=%h",
                     seen_cols, psum_out);
            errors = errors + 1;
        end
        else begin
            $display("PASS row0 activation reaches each raw bottom column psum");
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);

        $finish;
    end
endmodule
