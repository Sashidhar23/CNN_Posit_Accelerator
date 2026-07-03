`timescale 1ns / 1ps

module tb_pe;
    parameter N = 8;
    parameter ES = 1;

    reg clk;
    reg reset;
    reg pe_en;
    reg clear_acc;
    reg wshift;
    reg [N-1:0] input_in;
    reg [N-1:0] weight_in;
    reg [N-1:0] psum_in;

    wire [N-1:0] input_out;
    wire [N-1:0] weight_out;
    wire [N-1:0] product_out;
    wire [N-1:0] mac_out;
    wire [N-1:0] psum_out;
    wire [N-1:0] pe_output;

    integer errors;

    localparam [N-1:0] POSIT_ZERO = 8'h00;
    localparam [N-1:0] POSIT_HALF = 8'h30;
    localparam [N-1:0] POSIT_ONE  = 8'h40;
    localparam [N-1:0] POSIT_TWO  = 8'h50;

    pe #(.N(N), .ES(ES)) DUT (
        .clk(clk),
        .reset(reset),
        .pe_en(pe_en),
        .clear_acc(clear_acc),
        .wshift(wshift),
        .input_in(input_in),
        .weight_in(weight_in),
        .psum_in(psum_in),
        .input_out(input_out),
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

    initial begin
        errors = 0;
        reset = 1'b1;
        pe_en = 1'b0;
        clear_acc = 1'b0;
        wshift = 1'b0;
        input_in = POSIT_ZERO;
        weight_in = POSIT_ZERO;
        psum_in = POSIT_ZERO;

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;
        @(posedge clk);
        #1;
        if (pe_output !== POSIT_ZERO) begin
            $display("FAIL reset clears output actual=%h", pe_output);
            errors = errors + 1;
        end
        else begin
            $display("PASS reset clears output");
        end

        weight_in = POSIT_ONE;
        wshift = 1'b1;
        @(posedge clk);
        #1;
        wshift = 1'b0;
        weight_in = POSIT_ZERO;
        if (weight_out !== POSIT_ONE) begin
            $display("FAIL stationary weight load actual=%h expected=%h", weight_out, POSIT_ONE);
            errors = errors + 1;
        end
        else begin
            $display("PASS stationary weight load");
        end

        clear_acc = 1'b1;
        @(posedge clk);
        #1;
        clear_acc = 1'b0;
        if (pe_output !== POSIT_ZERO) begin
            $display("FAIL clear_acc clears pipeline actual=%h", pe_output);
            errors = errors + 1;
        end
        else begin
            $display("PASS clear_acc clears pipeline");
        end

        input_in = POSIT_ONE;
        psum_in = POSIT_ZERO;
        pe_en = 1'b1;
        @(posedge clk);
        #1;
        if (input_out !== POSIT_ONE) begin
            $display("FAIL 1.0 activation forwarded actual=%h", input_out);
            errors = errors + 1;
        end
        input_in = POSIT_ZERO;
        @(posedge clk);
        @(posedge clk);
        #1;
        if (pe_output !== POSIT_ONE) begin
            $display("FAIL 1.0 * 1.0 actual=%h expected=%h", pe_output, POSIT_ONE);
            errors = errors + 1;
        end
        else begin
            $display("PASS 1.0 * 1.0");
        end

        input_in = POSIT_TWO;
        @(posedge clk);
        #1;
        input_in = POSIT_ZERO;
        @(posedge clk);
        @(posedge clk);
        #1;
        if (pe_output !== POSIT_TWO) begin
            $display("FAIL 2.0 * 1.0 actual=%h expected=%h", pe_output, POSIT_TWO);
            errors = errors + 1;
        end
        else begin
            $display("PASS 2.0 * 1.0");
        end

        input_in = POSIT_HALF;
        @(posedge clk);
        #1;
        input_in = POSIT_ZERO;
        @(posedge clk);
        @(posedge clk);
        #1;
        if (pe_output !== POSIT_HALF) begin
            $display("FAIL 0.5 * 1.0 actual=%h expected=%h", pe_output, POSIT_HALF);
            errors = errors + 1;
        end
        else begin
            $display("PASS 0.5 * 1.0");
        end

        pe_en = 1'b0;
        input_in = POSIT_TWO;
        @(posedge clk);
        #1;
        if (input_out !== POSIT_ZERO) begin
            $display("FAIL pe_en low holds activation register actual=%h", input_out);
            errors = errors + 1;
        end
        else begin
            $display("PASS pe_en low holds activation register");
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);

        $finish;
    end
endmodule
