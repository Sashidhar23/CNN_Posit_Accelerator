`timescale 1ns / 1ps

module tb_conv2D;
    localparam N = 8;
    localparam ES = 1;
    localparam IN_CH = 1;
    localparam IN_H = 1;
    localparam IN_W = 1;
    localparam OUT_CH = 6;
    localparam K = 3;
    localparam PADDING = 1;
    localparam STRIDE = 1;
    localparam OUT_H = 1;
    localparam OUT_W = 1;

    localparam [N-1:0] POSIT_ZERO = 8'h00;
    localparam [N-1:0] POSIT_ONE  = 8'h40;

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

    conv2D #(
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
        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    task check_output;
        input integer index;
        input [N-1:0] expected;
        begin
            if (DUT.output_mem[index] !== expected) begin
                $display("FAIL output_mem[%0d] expected=%h got=%h", index, expected, DUT.output_mem[index]);
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
        i = 0;
        oc = 0;
        pix = 0;

        for (i = 0; i < IN_CH*IN_H*IN_W; i = i + 1)
            DUT.input_mem[i] = POSIT_ONE;

        for (i = 0; i < OUT_CH*IN_CH*K*K; i = i + 1)
            DUT.weight_mem[i] = POSIT_ZERO;

        for (i = 0; i < OUT_CH; i = i + 1)
            DUT.bias_mem[i] = POSIT_ZERO;

        for (i = 0; i < OUT_CH*OUT_H*OUT_W; i = i + 1)
            DUT.output_mem[i] = POSIT_ZERO;

        for (oc = 0; oc < OUT_CH; oc = oc + 1)
            DUT.weight_mem[(oc * IN_CH * K * K) + 4] = POSIT_ONE;

        repeat (5) @(posedge clk);
        reset = 1'b0;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        while (!done && timeout < 2000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (!done) begin
            $display("FAIL timeout waiting for conv2D done");
            errors = errors + 1;
        end

        for (oc = 0; oc < OUT_CH; oc = oc + 1) begin
            for (pix = 0; pix < OUT_H*OUT_W; pix = pix + 1) begin
                check_output((oc * OUT_H * OUT_W) + pix, POSIT_ONE);
            end
        end

        if (errors == 0)
            $display("tb_conv2D PASS");
        else
            $display("tb_conv2D FAIL errors=%0d", errors);

        $finish;
    end
endmodule
