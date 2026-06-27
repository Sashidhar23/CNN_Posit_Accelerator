`timescale 1ns / 1ps

module tb_input_fifo;

    parameter WIDTH = 8;
    parameter DEPTH = 4;
    parameter COUNT_W = $clog2(DEPTH + 1);

    reg clk;
    reg reset;
    reg clear;
    reg write_en;
    reg read_en;
    reg [WIDTH-1:0] data_in;

    wire [WIDTH-1:0] data_out;
    wire full;
    wire empty;
    wire [COUNT_W-1:0] count;

    integer errors;

    input_fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) DUT (
        .clk      (clk),
        .reset    (reset),
        .clear    (clear),
        .write_en (write_en),
        .read_en  (read_en),
        .data_in  (data_in),
        .data_out (data_out),
        .full     (full),
        .empty    (empty),
        .count    (count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_flags;
        input expected_empty;
        input expected_full;
        input [COUNT_W-1:0] expected_count;
        input [255:0] name;
        begin
            $display("------------------------------------------");
            $display("%0s", name);
            $display("empty=%b exp=%b full=%b exp=%b count=%0d exp=%0d",
                     empty, expected_empty, full, expected_full, count, expected_count);

            if (empty !== expected_empty || full !== expected_full || count !== expected_count) begin
                $display("FAIL");
                errors = errors + 1;
            end
            else begin
                $display("PASS");
            end
        end
    endtask

    task write_word;
        input [WIDTH-1:0] value;
        begin
            data_in = value;
            write_en = 1'b1;
            read_en = 1'b0;
            @(posedge clk);
            #1;
            write_en = 1'b0;
        end
    endtask

    task read_word;
        input [WIDTH-1:0] expected;
        input [255:0] name;
        begin
            write_en = 1'b0;
            read_en = 1'b1;
            @(posedge clk);
            #1;
            read_en = 1'b0;

            $display("------------------------------------------");
            $display("%0s", name);
            $display("data_out=%h exp=%h", data_out, expected);

            if (data_out !== expected) begin
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
        reset = 1'b1;
        clear = 1'b0;
        write_en = 1'b0;
        read_en = 1'b0;
        data_in = 0;

        $display("==========================================");
        $display("          INPUT FIFO TESTBENCH");
        $display("==========================================");

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;
        check_flags(1'b1, 1'b0, 0, "T1 : reset gives empty FIFO");

        write_word(8'h11);
        write_word(8'h22);
        write_word(8'h33);
        check_flags(1'b0, 1'b0, 3, "T2 : three writes");

        read_word(8'h11, "T3 : first read");
        read_word(8'h22, "T4 : second read");
        check_flags(1'b0, 1'b0, 1, "T5 : one word left");

        write_word(8'h44);
        write_word(8'h55);
        write_word(8'h66);
        check_flags(1'b0, 1'b1, 4, "T6 : FIFO full");

        read_word(8'h33, "T7 : third original read");
        read_word(8'h44, "T8 : wrap read 1");
        read_word(8'h55, "T9 : wrap read 2");
        read_word(8'h66, "T10 : wrap read 3");
        check_flags(1'b1, 1'b0, 0, "T11 : FIFO empty");

        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;
        check_flags(1'b1, 1'b0, 0, "T12 : clear keeps FIFO empty");

        $display("==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);
        $display("==========================================");

        $finish;
    end

endmodule
