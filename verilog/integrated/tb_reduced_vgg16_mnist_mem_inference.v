`timescale 1ns / 1ps

module tb_reduced_vgg16_mnist_mem_inference;
    localparam N = 8;
    localparam ES = 1;
    localparam IN_CH = 1;
    localparam IN_H = 28;
    localparam IN_W = 28;
    localparam C1 = 64;
    localparam C2 = 128;
    localparam C3 = 256;
    localparam C4 = 512;
    localparam FC1 = 256;
    localparam NUM_CLASSES = 10;
    localparam ROWS = 3;
    localparam COLS = 3;
    localparam CLASS_W = 4;

    localparam [1:0] CFG_INPUT  = 2'd0;
    localparam [1:0] CFG_WEIGHT = 2'd1;
    localparam [1:0] CFG_BIAS   = 2'd2;

    localparam integer NUM_TEST_IMAGES = 10;
    localparam integer IMAGE_SIZE = IN_CH * IN_H * IN_W;
    localparam integer MAX_INFERENCE_CYCLES = 500000000;

    localparam integer L0_W_SIZE  = C1 * IN_CH * 3 * 3;
    localparam integer L1_W_SIZE  = C1 * C1 * 3 * 3;
    localparam integer L2_W_SIZE  = C2 * C1 * 3 * 3;
    localparam integer L3_W_SIZE  = C2 * C2 * 3 * 3;
    localparam integer L4_W_SIZE  = C3 * C2 * 3 * 3;
    localparam integer L5_W_SIZE  = C3 * C3 * 3 * 3;
    localparam integer L6_W_SIZE  = C3 * C3 * 3 * 3;
    localparam integer L7_W_SIZE  = C4 * C3 * 3 * 3;
    localparam integer L8_W_SIZE  = C4 * C4 * 3 * 3;
    localparam integer L9_W_SIZE  = C4 * C4 * 3 * 3;
    localparam integer L10_W_SIZE = FC1 * C4;
    localparam integer L11_W_SIZE = NUM_CLASSES * FC1;

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

    reg [N-1:0] pixels [0:(10*IMAGE_SIZE)-1];

    reg [N-1:0] l0_w  [0:L0_W_SIZE-1];
    reg [N-1:0] l1_w  [0:L1_W_SIZE-1];
    reg [N-1:0] l2_w  [0:L2_W_SIZE-1];
    reg [N-1:0] l3_w  [0:L3_W_SIZE-1];
    reg [N-1:0] l4_w  [0:L4_W_SIZE-1];
    reg [N-1:0] l5_w  [0:L5_W_SIZE-1];
    reg [N-1:0] l6_w  [0:L6_W_SIZE-1];
    reg [N-1:0] l7_w  [0:L7_W_SIZE-1];
    reg [N-1:0] l8_w  [0:L8_W_SIZE-1];
    reg [N-1:0] l9_w  [0:L9_W_SIZE-1];
    reg [N-1:0] l10_w [0:L10_W_SIZE-1];
    reg [N-1:0] l11_w [0:L11_W_SIZE-1];

    reg [N-1:0] l0_b  [0:C1-1];
    reg [N-1:0] l1_b  [0:C1-1];
    reg [N-1:0] l2_b  [0:C2-1];
    reg [N-1:0] l3_b  [0:C2-1];
    reg [N-1:0] l4_b  [0:C3-1];
    reg [N-1:0] l5_b  [0:C3-1];
    reg [N-1:0] l6_b  [0:C3-1];
    reg [N-1:0] l7_b  [0:C4-1];
    reg [N-1:0] l8_b  [0:C4-1];
    reg [N-1:0] l9_b  [0:C4-1];
    reg [N-1:0] l10_b [0:FC1-1];
    reg [N-1:0] l11_b [0:NUM_CLASSES-1];

    integer i;
    integer timeout;
    integer errors;
    integer correct_count;
    integer test_image;
    integer image_base;
    reg [CLASS_W-1:0] expected_class [0:NUM_TEST_IMAGES-1];

    reduced_vgg16_mnist #(
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
        .ROWS(ROWS),
        .COLS(COLS),
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
            @(posedge clk);
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

    task show_logit;
        input [31:0] addr;
        begin
            logit_read_addr = addr;
            @(posedge clk);
            @(posedge clk);
            #1;
            $display("LOGIT[%0d] = %h", addr, logit_read_data);
        end
    endtask

    task read_all_memories;
        begin
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/mnist_pixels_posit8_1.mem", pixels);

            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_0_weight_posit8_1.mem", l0_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_0_bias_posit8_1.mem", l0_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_2_weight_posit8_1.mem", l1_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_2_bias_posit8_1.mem", l1_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_5_weight_posit8_1.mem", l2_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_5_bias_posit8_1.mem", l2_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_7_weight_posit8_1.mem", l3_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_7_bias_posit8_1.mem", l3_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_10_weight_posit8_1.mem", l4_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_10_bias_posit8_1.mem", l4_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_12_weight_posit8_1.mem", l5_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_12_bias_posit8_1.mem", l5_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_14_weight_posit8_1.mem", l6_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_14_bias_posit8_1.mem", l6_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_17_weight_posit8_1.mem", l7_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_17_bias_posit8_1.mem", l7_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_19_weight_posit8_1.mem", l8_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_19_bias_posit8_1.mem", l8_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_21_weight_posit8_1.mem", l9_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/features_21_bias_posit8_1.mem", l9_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/classifier_0_weight_posit8_1.mem", l10_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/classifier_0_bias_posit8_1.mem", l10_b);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/classifier_3_weight_posit8_1.mem", l11_w);
            $readmemh("C:/Users/Oishik Ganguli/FPGA_projects/posit_cnn_accelerator/VGG16_MNIST_Epoch20/classifier_3_bias_posit8_1.mem", l11_b);
        end
    endtask

`define LOAD_INPUT(ARRAY_BASE) \
    begin \
        for (i = 0; i < IMAGE_SIZE; i = i + 1) \
            cfg_write(4'd0, CFG_INPUT, i, pixels[(ARRAY_BASE) + i]); \
        $display("Loaded image %0d into layer 0 input memory", test_image); \
    end

`define LOAD_WB(LAYER_ID, W_ARRAY, W_COUNT, B_ARRAY, B_COUNT, NAME) \
    begin \
        for (i = 0; i < W_COUNT; i = i + 1) \
            cfg_write(LAYER_ID, CFG_WEIGHT, i, W_ARRAY[i]); \
        for (i = 0; i < B_COUNT; i = i + 1) \
            cfg_write(LAYER_ID, CFG_BIAS, i, B_ARRAY[i]); \
        $display("Loaded %0s weights=%0d biases=%0d", NAME, W_COUNT, B_COUNT); \
    end

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
        correct_count = 0;
        test_image = 0;
        image_base = 0;

        expected_class[0] = 4'd7;
        expected_class[1] = 4'd2;
        expected_class[2] = 4'd1;
        expected_class[3] = 4'd0;
        expected_class[4] = 4'd4;
        expected_class[5] = 4'd1;
        expected_class[6] = 4'd4;
        expected_class[7] = 4'd9;
        expected_class[8] = 4'd5;
        expected_class[9] = 4'd9;

        read_all_memories();

        repeat (8) @(posedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);

        $display("Starting full VGG16-MNIST posit<8,1> inference memory load");
        `LOAD_WB(4'd0,  l0_w,  L0_W_SIZE,  l0_b,  C1,          "features.0")
        `LOAD_WB(4'd1,  l1_w,  L1_W_SIZE,  l1_b,  C1,          "features.2")
        `LOAD_WB(4'd2,  l2_w,  L2_W_SIZE,  l2_b,  C2,          "features.5")
        `LOAD_WB(4'd3,  l3_w,  L3_W_SIZE,  l3_b,  C2,          "features.7")
        `LOAD_WB(4'd4,  l4_w,  L4_W_SIZE,  l4_b,  C3,          "features.10")
        `LOAD_WB(4'd5,  l5_w,  L5_W_SIZE,  l5_b,  C3,          "features.12")
        `LOAD_WB(4'd6,  l6_w,  L6_W_SIZE,  l6_b,  C3,          "features.14")
        `LOAD_WB(4'd7,  l7_w,  L7_W_SIZE,  l7_b,  C4,          "features.17")
        `LOAD_WB(4'd8,  l8_w,  L8_W_SIZE,  l8_b,  C4,          "features.19")
        `LOAD_WB(4'd9,  l9_w,  L9_W_SIZE,  l9_b,  C4,          "features.21")
        `LOAD_WB(4'd10, l10_w, L10_W_SIZE, l10_b, FC1,         "classifier.0")
        `LOAD_WB(4'd11, l11_w, L11_W_SIZE, l11_b, NUM_CLASSES, "classifier.3")

        $display("Weight and bias load complete; starting 10-image inference run");

        for (test_image = 0; test_image < NUM_TEST_IMAGES; test_image = test_image + 1) begin
            image_base = test_image * IMAGE_SIZE;
            timeout = 0;

            $display("------------------------------------------------------------");
            $display("Image %0d expected digit %0d", test_image, expected_class[test_image]);
            `LOAD_INPUT(image_base)

            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            while (!done && timeout < MAX_INFERENCE_CYCLES) begin
                @(posedge clk);
                timeout = timeout + 1;
                if ((timeout % 1000000) == 0)
                    $display("Image %0d inference still running at cycle %0d", test_image, timeout);
            end

            if (!done) begin
                $display("FAIL image %0d timeout waiting for reduced_vgg16_mnist done after %0d cycles",
                         test_image, timeout);
                errors = errors + 1;
            end
            else begin
                $display("PASS image %0d inference done after %0d cycles", test_image, timeout);
            end

            for (i = 0; i < NUM_CLASSES; i = i + 1)
                show_logit(i);

            if (class_out !== expected_class[test_image]) begin
                $display("FAIL image %0d class_out got=%0d expected=%0d",
                         test_image, class_out, expected_class[test_image]);
                errors = errors + 1;
            end
            else begin
                correct_count = correct_count + 1;
                $display("PASS image %0d class_out=%0d expected=%0d",
                         test_image, class_out, expected_class[test_image]);
            end

            repeat (4) @(posedge clk);
        end

        $display("------------------------------------------------------------");
        $display("Accuracy = %0d / %0d", correct_count, NUM_TEST_IMAGES);

        if (errors == 0)
            $display("tb_reduced_vgg16_mnist_mem_inference PASS");
        else
            $display("tb_reduced_vgg16_mnist_mem_inference FAIL errors=%0d", errors);

        $finish;
    end

`undef LOAD_INPUT
`undef LOAD_WB
endmodule
