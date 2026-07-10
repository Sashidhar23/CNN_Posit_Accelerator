`timescale 1ns / 1ps

module tb_conv2D_quire_stream;
    localparam N = 8;
    localparam ES = 1;
    localparam IN_CH = 1;
    localparam IN_H = 1;
    localparam IN_W = 3;
    localparam OUT_CH = 6;
    localparam K = 3;
    localparam PADDING = 1;
    localparam STRIDE = 1;
    localparam OUT_H = 1;
    localparam OUT_W = 3;

    localparam [N-1:0] POSIT_ZERO = 8'h00;
    localparam [N-1:0] POSIT_ONE  = 8'h40;
    localparam [N-1:0] POSIT_TWO  = 8'h50;

    reg clk;
    reg reset;
    reg start;
    wire busy;
    wire done;

    integer i;
    integer oc;
    integer pix;
    integer errors;
    integer timeout;
    reg [N-1:0] expected [0:OUT_W-1];

    conv2D_quire #(
        .N(N),
        .ES(ES),
        .IN_CH(IN_CH),
        .IN_H(IN_H),
        .IN_W(IN_W),
        .OUT_CH(OUT_CH),
        .K(K),
        .PADDING(PADDING),
        .STRIDE(STRIDE),
        .OUT_H(OUT_H),
        .OUT_W(OUT_W)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .ext_input_write_en(1'b0),
        .ext_input_addr(32'd0),
        .ext_input_data({N{1'b0}}),
        .ext_weight_write_en(1'b0),
        .ext_weight_addr(32'd0),
        .ext_weight_data({N{1'b0}}),
        .ext_bias_write_en(1'b0),
        .ext_bias_addr(32'd0),
        .ext_bias_data({N{1'b0}}),
        .ext_output_addr(32'd0),
        .ext_output_data(),
        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    task check_output;
        input integer index;
        input [N-1:0] exp;
        begin
            if (DUT.output_mem[index] !== exp) begin
                $display("FAIL output_mem[%0d] expected=%h got=%h",
                         index, exp, DUT.output_mem[index]);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        start = 1'b0;
        errors = 0;
        timeout = 0;

        expected[0] = POSIT_ONE;
        expected[1] = POSIT_TWO;
        expected[2] = POSIT_ONE;

        DUT.input_mem[0] = POSIT_ONE;
        DUT.input_mem[1] = POSIT_ZERO;
        DUT.input_mem[2] = POSIT_ONE;

        for (i = 0; i < OUT_CH*IN_CH*K*K; i = i + 1)
            DUT.weight_mem[i] = POSIT_ZERO;

        for (i = 0; i < OUT_CH; i = i + 1)
            DUT.bias_mem[i] = POSIT_ZERO;

        for (i = 0; i < OUT_CH*OUT_H*OUT_W; i = i + 1)
            DUT.output_mem[i] = POSIT_ZERO;

        for (oc = 0; oc < OUT_CH; oc = oc + 1) begin
            DUT.weight_mem[(oc * IN_CH * K * K) + 3] = POSIT_ONE;
            DUT.weight_mem[(oc * IN_CH * K * K) + 4] = POSIT_ONE;
            DUT.weight_mem[(oc * IN_CH * K * K) + 5] = POSIT_ONE;
        end

        repeat (5) @(posedge clk);
        reset = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        while (!done && timeout < 4000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (!done) begin
            $display("FAIL timeout waiting for streamed conv2D_quire done");
            errors = errors + 1;
        end

        for (oc = 0; oc < OUT_CH; oc = oc + 1) begin
            for (pix = 0; pix < OUT_W; pix = pix + 1)
                check_output((oc * OUT_W) + pix, expected[pix]);
        end

        if (errors == 0)
            $display("tb_conv2D_quire_stream PASS");
        else
            $display("tb_conv2D_quire_stream FAIL errors=%0d", errors);

        $finish;
    end
endmodule
