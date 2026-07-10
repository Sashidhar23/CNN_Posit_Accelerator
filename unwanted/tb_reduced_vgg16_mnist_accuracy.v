`timescale 1ns / 1ps

`ifndef REDUCED_VGG_TB_MODULE
`define REDUCED_VGG_TB_MODULE tb_reduced_vgg16_mnist_accuracy
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
    localparam NUM_IMAGES = 4;
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

    reg [CLASS_W-1:0] labels [0:NUM_IMAGES-1];

    integer image_idx;
    integer pix;
    integer layer;
    integer k;
    integer timeout;
    integer correct;
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

    task load_sample_image;
        input integer img;
        reg [N-1:0] pixel_value;
        begin
            for (pix = 0; pix < IN_CH*IN_H*IN_W; pix = pix + 1) begin
                if (img == 1)
                    pixel_value = POSIT_ZERO;
                else
                    pixel_value = POSIT_ONE;

                cfg_write(4'd0, 2'd0, pix, pixel_value);
            end
        end
    endtask

    task load_sample_weights_once;
        begin
            for (layer = 0; layer < 10; layer = layer + 1) begin
                for (k = 0; k < 9; k = k + 1)
                    cfg_write(layer[3:0], 2'd1, k, POSIT_ZERO);

                cfg_write(layer[3:0], 2'd1, 4, POSIT_ONE);
                cfg_write(layer[3:0], 2'd2, 0, POSIT_ZERO);
            end

            cfg_write(4'd10, 2'd1, 0, POSIT_ONE);
            cfg_write(4'd10, 2'd2, 0, POSIT_ZERO);

            cfg_write(4'd11, 2'd1, 0, POSIT_ONE);
            cfg_write(4'd11, 2'd1, 1, POSIT_TWO);
            cfg_write(4'd11, 2'd2, 0, POSIT_ZERO);
            cfg_write(4'd11, 2'd2, 1, POSIT_ZERO);
        end
    endtask

    task run_one_image;
        input integer img;
        begin
            load_sample_image(img);

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            timeout = 0;
            while (!done && timeout < 500000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (!done) begin
                $display("FAIL image %0d timeout waiting for inference done", img);
                errors = errors + 1;
            end
            else begin
                if (class_out == labels[img]) begin
                    correct = correct + 1;
                    $display("PASS image %0d predicted=%0d label=%0d",
                             img, class_out, labels[img]);
                end
                else begin
                    $display("FAIL image %0d predicted=%0d label=%0d",
                             img, class_out, labels[img]);
                    errors = errors + 1;
                end
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
        correct = 0;
        errors = 0;

        labels[0] = 1'b1;
        labels[1] = 1'b0;
        labels[2] = 1'b1;
        labels[3] = 1'b1;

        repeat (5) @(posedge clk);
        reset = 1'b0;

        load_sample_weights_once();

        for (image_idx = 0; image_idx < NUM_IMAGES; image_idx = image_idx + 1)
            run_one_image(image_idx);

        $display("ACCURACY %0d/%0d", correct, NUM_IMAGES);

        if (correct == NUM_IMAGES && errors == 0)
            $display("tb_reduced_vgg16_mnist_accuracy PASS");
        else
            $display("tb_reduced_vgg16_mnist_accuracy FAIL errors=%0d", errors);

        $finish;
    end
endmodule

`undef REDUCED_VGG_DUT
`undef REDUCED_VGG_TB_MODULE
