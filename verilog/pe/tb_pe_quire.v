`timescale 1ns / 1ps

module tb_pe_quire;
    parameter N = 8;
    parameter ES = 1;
    parameter QW = 48;
    parameter QF = QW / 2;

    reg clk;
    reg reset;
    reg pe_en;
    reg clear_acc;
    reg wshift;
    reg [N-1:0] input_in;
    reg [N-1:0] weight_in;
    reg signed [QW-1:0] psum_in;
    reg psum_nar_in;

    wire [N-1:0] input_out;
    wire [N-1:0] weight_out;
    wire signed [QW-1:0] quire_out;
    wire is_nar;
    wire signed [QW-1:0] psum_out;
    wire psum_nar_out;
    wire [N-1:0] pe_output;

    integer errors;

    localparam [N-1:0] POSIT_ZERO = 8'h00;
    localparam [N-1:0] POSIT_ONE  = 8'h40;
    localparam [N-1:0] POSIT_TWO  = 8'h50;
    localparam [N-1:0] POSIT_NAR  = 8'h80;
    localparam signed [QW-1:0] QUIRE_ZERO = {QW{1'b0}};
    localparam signed [QW-1:0] QUIRE_ONE  = $signed({{(QW-1){1'b0}}, 1'b1} <<< QF);
    localparam signed [QW-1:0] QUIRE_TWO  = $signed({{(QW-2){1'b0}}, 2'b10} <<< QF);

    pe_quire #(.N(N), .ES(ES), .QW(QW), .QF(QF)) DUT (
        .clk(clk),
        .reset(reset),
        .pe_en(pe_en),
        .clear_acc(clear_acc),
        .wshift(wshift),
        .input_in(input_in),
        .weight_in(weight_in),
        .psum_in(psum_in),
        .psum_nar_in(psum_nar_in),
        .input_out(input_out),
        .weight_out(weight_out),
        .quire_out(quire_out),
        .is_nar(is_nar),
        .psum_out(psum_out),
        .psum_nar_out(psum_nar_out),
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

    task check_posit;
        input [N-1:0] actual;
        input [N-1:0] expected;
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

    task check_quire;
        input signed [QW-1:0] actual;
        input signed [QW-1:0] expected;
        input [255:0] name;
        begin
            if (actual !== expected) begin
                $display("FAIL %0s actual=%0d expected=%0d", name, actual, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    task run_product_case;
        input [N-1:0] activation;
        input signed [QW-1:0] incoming_psum;
        input signed [QW-1:0] expected_quire;
        input [N-1:0] expected_posit;
        input [255:0] name;
        begin
            input_in = activation;
            psum_in = incoming_psum;
            psum_nar_in = 1'b0;
            pe_en = 1'b1;
            step();
            check_posit(input_out, activation, {name, " activation forwarded"});

            input_in = POSIT_ZERO;
            psum_in = QUIRE_ZERO;
            step();
            step();
            check_quire(quire_out, expected_quire, {name, " quire"});
            check_posit(pe_output, expected_posit, {name, " rounded posit"});
        end
    endtask

    initial begin
        errors = 0;
        reset = 1'b1;
        pe_en = 1'b0;
        clear_acc = 1'b0;
        wshift = 1'b0;
        input_in = POSIT_ZERO;
        weight_in = POSIT_ZERO;
        psum_in = QUIRE_ZERO;
        psum_nar_in = 1'b0;

        repeat (2) step();
        reset = 1'b0;
        step();
        check_quire(quire_out, QUIRE_ZERO, "reset clears quire");

        weight_in = POSIT_ONE;
        wshift = 1'b1;
        step();
        wshift = 1'b0;
        weight_in = POSIT_ZERO;
        check_posit(weight_out, POSIT_ONE, "stationary weight load");

        clear_acc = 1'b1;
        step();
        clear_acc = 1'b0;
        check_quire(quire_out, QUIRE_ZERO, "clear_acc clears quire pipeline");

        run_product_case(POSIT_ONE, QUIRE_ZERO, QUIRE_ONE, POSIT_ONE, "1.0 * 1.0");
        run_product_case(POSIT_TWO, QUIRE_ZERO, QUIRE_TWO, POSIT_TWO, "2.0 * 1.0");

        input_in = POSIT_NAR;
        pe_en = 1'b1;
        step();
        input_in = POSIT_ZERO;
        step();
        step();
        if (is_nar !== 1'b1 || pe_output !== POSIT_NAR) begin
            $display("FAIL NaR propagation is_nar=%b pe_output=%h", is_nar, pe_output);
            errors = errors + 1;
        end
        else begin
            $display("PASS NaR propagation");
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED = %0d", errors);

        $finish;
    end
endmodule
