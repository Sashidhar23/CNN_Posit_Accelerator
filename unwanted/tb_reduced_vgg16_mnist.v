`timescale 1ns / 1ps

`ifndef REDUCED_VGG_TB_MODULE
`define REDUCED_VGG_TB_MODULE tb_reduced_vgg16_mnist
`endif

`ifndef REDUCED_VGG_DUT
`define REDUCED_VGG_DUT reduced_vgg16_mnist
`endif

module `REDUCED_VGG_TB_MODULE;
    localparam N = 8;
    localparam ES = 1;
    localparam IN_CH = 1;
    localparam IN_H = 16;
    localparam IN_W = 16;
    localparam C1 = 1;
    localparam C2 = 1;
    localparam C3 = 1;
    localparam C4 = 1;
    localparam FC1 = 1;
    localparam NUM_CLASSES = 2;
    localparam CLASS_W = 1;

    localparam [N-1:0] POSIT_ZERO = 8'h00;
    localparam [N-1:0] POSIT_ONE  = 8'h40;
    localparam [N-1:0] POSIT_TWO  = 8'h50;

    reg clk;
    reg reset;
    reg start;
    reg cfg_write_en;
    reg [3:0] cfg_layer;
    reg [1:0] cfg_mem;
    reg [31:0] cfg_addr;
    reg [N-1:0] cfg_data;
    reg [31:0] logit_read_addr;

    wire [N-1:0] logit_read_data;
    wire busy;
    wire done;
    wire [CLASS_W-1:0] class_out;

    integer i;
    integer layer;
    integer timeout;
    integer errors;

    `REDUCED_VGG_DUT #(
        .N(N),
        .ES(ES),
        .IN_CH(IN_CH),
        .IN_H(IN_H),
        .IN_W(IN_W),
        .C1(C1),
        .C2(C2),
        .C3(C3),
        .C4(C4),
        .FC1(FC1),
        .NUM_CLASSES(NUM_CLASSES),
        .CLASS_W(CLASS_W)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .cfg_write_en(cfg_write_en),
        .cfg_layer(cfg_layer),
        .cfg_mem(cfg_mem),
        .cfg_addr(cfg_addr),
        .cfg_data(cfg_data),
        .logit_read_addr(logit_read_addr),
        .logit_read_data(logit_read_data),
        .busy(busy),
        .done(done),
        .class_out(class_out)
    );

    always #5 clk = ~clk;

    task cfg_write;
        input [3:0] layer_id;
        input [1:0] mem_id;
        input [31:0] addr;
        input [N-1:0] data;
        begin
            cfg_layer = layer_id;
            cfg_mem = mem_id;
            cfg_addr = addr;
            cfg_data = data;
            cfg_write_en = 1'b1;
            @(posedge clk);
            #1;
            cfg_write_en = 1'b0;
        end
    endtask

    task check_logit;
        input [31:0] addr;
        input [N-1:0] expected;
        input [8*64-1:0] name;
        begin
            logit_read_addr = addr;
            @(posedge clk);
            @(posedge clk);
            #1;
            if (logit_read_data !== expected) begin
                $display("FAIL %0s got=%h expected=%h", name, logit_read_data, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        start = 1'b0;
        cfg_write_en = 1'b0;
        cfg_layer = 0;
        cfg_mem = 0;
        cfg_addr = 0;
        cfg_data = 0;
        logit_read_addr = 0;
        timeout = 0;
        errors = 0;

        repeat (5) @(posedge clk);
        reset = 1'b0;

        for (i = 0; i < IN_CH*IN_H*IN_W; i = i + 1)
            cfg_write(4'd0, 2'd0, i, POSIT_ONE);

        for (layer = 0; layer < 10; layer = layer + 1) begin
            for (i = 0; i < 9; i = i + 1)
                cfg_write(layer[3:0], 2'd1, i, POSIT_ZERO);
            cfg_write(layer[3:0], 2'd1, 4, POSIT_ONE);
            cfg_write(layer[3:0], 2'd2, 0, POSIT_ZERO);
        end

        cfg_write(4'd10, 2'd1, 0, POSIT_ONE);
        cfg_write(4'd10, 2'd2, 0, POSIT_ZERO);

        cfg_write(4'd11, 2'd1, 0, POSIT_ONE);
        cfg_write(4'd11, 2'd1, 1, POSIT_TWO);
        cfg_write(4'd11, 2'd2, 0, POSIT_ZERO);
        cfg_write(4'd11, 2'd2, 1, POSIT_ZERO);

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        while (!done && timeout < 500000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (!done) begin
            $display("FAIL timeout waiting for reduced_vgg16_mnist done");
            errors = errors + 1;
        end
        else begin
            $display("PASS reduced_vgg16_mnist done");
        end

        if (class_out !== 1'b1) begin
            $display("FAIL class_out got=%0d expected=1", class_out);
            errors = errors + 1;
        end
        else begin
            $display("PASS class_out selects class 1");
        end

        check_logit(0, POSIT_ONE, "class 0 logit");
        check_logit(1, POSIT_TWO, "class 1 logit");

        if (errors == 0)
            $display("tb_reduced_vgg16_mnist PASS");
        else
            $display("tb_reduced_vgg16_mnist FAIL errors=%0d", errors);

        $finish;
    end
endmodule

`undef REDUCED_VGG_DUT
`undef REDUCED_VGG_TB_MODULE
