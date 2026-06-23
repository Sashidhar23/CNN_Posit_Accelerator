`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 15:44:00
// Design Name: 
// Module Name: tb_posit_decoder
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



module posit_decoder_tb;

    parameter N  = 8;
    parameter ES = 1;

    reg  [N-1:0] posit_in;

    wire sign;
    wire is_zero;
    wire is_nar;
    wire signed [$clog2(N):0] k;
    wire [ES-1:0] exponent;
    wire [N-1:0] fraction;
    wire [$clog2(N):0] frac_len;

    posit_decoder #(
        .N(N),
        .ES(ES)
    ) DUT (
        .posit_in(posit_in),
        .sign(sign),
        .is_zero(is_zero),
        .is_nar(is_nar),
        .k(k),
        .exponent(exponent),
        .fraction(fraction),
        .frac_len(frac_len)
    );

    task show_result;
    begin
        $display(
            "%b | s=%0d z=%0d nar=%0d k=%0d exp=%0d frac=%b len=%0d",
            posit_in,
            sign,
            is_zero,
            is_nar,
            k,
            exponent,
            fraction,
            frac_len
        );
    end
    endtask

    initial begin
        $display("------------------------------------------------------------");
        $display("Posit      | s z nar k exp fraction len");
        $display("------------------------------------------------------------");

        posit_in = 8'b00000000; #10; show_result();
        posit_in = 8'b10000000; #10; show_result();

        posit_in = 8'b01000000; #10; show_result(); // +1
        posit_in = 8'b01010000; #10; show_result();
        posit_in = 8'b01100000; #10; show_result();
        posit_in = 8'b01110000; #10; show_result();

        posit_in = 8'b00110000; #10; show_result();
        posit_in = 8'b00100000; #10; show_result();
        posit_in = 8'b00010000; #10; show_result();

        $display("------------------------------------------------------------");
        $finish;
    end

endmodule
