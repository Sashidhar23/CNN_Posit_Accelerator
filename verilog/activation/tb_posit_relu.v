`timescale 1ns / 1ps

module tb_posit_relu;

    parameter N = 8;
    parameter NUM_VALUES = 5;

    reg  [NUM_VALUES*N-1:0] data_in;
    wire [NUM_VALUES*N-1:0] data_out;

    integer errors;

    localparam [N-1:0] POSIT_ZERO = 8'b00000000;
    localparam [N-1:0] POSIT_ONE  = 8'b01000000;
    localparam [N-1:0] POSIT_TWO  = 8'b01010000;
    localparam [N-1:0] POSIT_NEG1 = 8'b11000000;
    localparam [N-1:0] POSIT_NAR  = 8'b10000000;

    posit_relu #(
        .N(N),
        .NUM_VALUES(NUM_VALUES)
    ) DUT (
        .data_in  (data_in),
        .data_out (data_out)
    );

    task check_value;
        input integer index;
        input [N-1:0] expected;
        input [255:0] name;
        begin
            if (data_out[index*N +: N] !== expected) begin
                $display("FAIL %0s: got %b expected %b",
                         name, data_out[index*N +: N], expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    initial begin
        errors = 0;

        data_in[0*N +: N] = POSIT_NEG1;
        data_in[1*N +: N] = POSIT_ZERO;
        data_in[2*N +: N] = POSIT_ONE;
        data_in[3*N +: N] = POSIT_TWO;
        data_in[4*N +: N] = POSIT_NAR;

        #10;

        check_value(0, POSIT_ZERO, "negative clamps to zero");
        check_value(1, POSIT_ZERO, "zero stays zero");
        check_value(2, POSIT_ONE,  "positive one passes");
        check_value(3, POSIT_TWO,  "positive two passes");
        check_value(4, POSIT_NAR,  "NaR propagates");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);

        $finish;
    end

endmodule
