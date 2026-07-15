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
    localparam ROWS = 4;
    localparam COLS = 4;
    localparam CLASS_W = 4;

    localparam [1:0] CFG_INPUT  = 2'd0;
    localparam [1:0] CFG_WEIGHT = 2'd1;
    localparam [1:0] CFG_BIAS   = 2'd2;
    localparam [1:0] PARAM_WEIGHT = 2'd0;
    localparam [1:0] PARAM_BIAS   = 2'd1;

    localparam integer NUM_TEST_IMAGES = 10;
    localparam integer IMAGE_SIZE = IN_CH * IN_H * IN_W;
    localparam integer MAX_FEATURE_VALUES = C1 * IN_H * IN_W;
    localparam integer MAX_INFERENCE_CYCLES = 500000000;
    localparam integer FAST_BACKDOOR_LOAD = 1;

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

    localparam integer L0_W_BASE  = 0;
    localparam integer L1_W_BASE  = L0_W_BASE  + L0_W_SIZE;
    localparam integer L2_W_BASE  = L1_W_BASE  + L1_W_SIZE;
    localparam integer L3_W_BASE  = L2_W_BASE  + L2_W_SIZE;
    localparam integer L4_W_BASE  = L3_W_BASE  + L3_W_SIZE;
    localparam integer L5_W_BASE  = L4_W_BASE  + L4_W_SIZE;
    localparam integer L6_W_BASE  = L5_W_BASE  + L5_W_SIZE;
    localparam integer L7_W_BASE  = L6_W_BASE  + L6_W_SIZE;
    localparam integer L8_W_BASE  = L7_W_BASE  + L7_W_SIZE;
    localparam integer L9_W_BASE  = L8_W_BASE  + L8_W_SIZE;
    localparam integer L10_W_BASE = L9_W_BASE  + L9_W_SIZE;
    localparam integer L11_W_BASE = L10_W_BASE + L10_W_SIZE;

    localparam integer L0_B_BASE  = 0;
    localparam integer L1_B_BASE  = L0_B_BASE  + C1;
    localparam integer L2_B_BASE  = L1_B_BASE  + C1;
    localparam integer L3_B_BASE  = L2_B_BASE  + C2;
    localparam integer L4_B_BASE  = L3_B_BASE  + C2;
    localparam integer L5_B_BASE  = L4_B_BASE  + C3;
    localparam integer L6_B_BASE  = L5_B_BASE  + C3;
    localparam integer L7_B_BASE  = L6_B_BASE  + C3;
    localparam integer L8_B_BASE  = L7_B_BASE  + C4;
    localparam integer L9_B_BASE  = L8_B_BASE  + C4;
    localparam integer L10_B_BASE = L9_B_BASE  + C4;
    localparam integer L11_B_BASE = L10_B_BASE + FC1;

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
    wire param_req_valid;
    wire [1:0] param_req_kind;
    wire [3:0] param_req_layer;
    wire [31:0] param_req_addr;
    reg param_resp_valid;
    reg [N-1:0] param_resp_data;
    wire feature_rd_req_valid;
    wire feature_rd_bank;
    wire [31:0] feature_rd_addr;
    reg feature_rd_resp_valid;
    reg [N-1:0] feature_rd_resp_data;
    wire feature_wr_valid;
    wire feature_wr_bank;
    wire [31:0] feature_wr_addr;
    wire [N-1:0] feature_wr_data;

    reg [N-1:0] pixels [0:(10*IMAGE_SIZE)-1];
    reg [N-1:0] feature_bank0 [0:MAX_FEATURE_VALUES-1];
    reg [N-1:0] feature_bank1 [0:MAX_FEATURE_VALUES-1];

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
    integer run_images;
    integer image_base;
    integer predicted_class [0:NUM_TEST_IMAGES-1];
    integer expected_class_int [0:NUM_TEST_IMAGES-1];
    integer zero_logit_count;
    reg [N-1:0] observed_logits [0:NUM_CLASSES-1];
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
        .param_req_valid(param_req_valid),
        .param_req_kind(param_req_kind),
        .param_req_layer(param_req_layer),
        .param_req_addr(param_req_addr),
        .param_resp_valid(param_resp_valid),
        .param_resp_data(param_resp_data),
        .feature_rd_req_valid(feature_rd_req_valid),
        .feature_rd_bank(feature_rd_bank),
        .feature_rd_addr(feature_rd_addr),
        .feature_rd_resp_valid(feature_rd_resp_valid),
        .feature_rd_resp_data(feature_rd_resp_data),
        .feature_wr_valid(feature_wr_valid),
        .feature_wr_bank(feature_wr_bank),
        .feature_wr_addr(feature_wr_addr),
        .feature_wr_data(feature_wr_data),
        .logit_read_addr(logit_read_addr),
        .logit_read_data(logit_read_data),
        .busy(busy),
        .done(done),
        .class_out(class_out)
    );

    always #5 clk = ~clk;

    // The supplied PyTorch parameter export stores a negative value as
    // {1'b1, positive_posit_magnitude}.  Standard Posit uses two's-complement
    // negation of the complete word, which is also what posit_decoder expects.
    function [N-1:0] canonical_parameter;
        input [N-1:0] source_value;
        reg [N-1:0] magnitude;
        begin
            magnitude = {1'b0, source_value[N-2:0]};
            if (!source_value[N-1])
                canonical_parameter = source_value;
            else if (magnitude == {N{1'b0}})
                canonical_parameter = {N{1'b0}};
            else
                canonical_parameter = (~magnitude) + 1'b1;
        end
    endfunction

    function [N-1:0] weight_lookup;
        input [3:0] layer_id;
        input [31:0] addr;
        begin
            case (layer_id)
                4'd0:  weight_lookup = (addr < L0_W_SIZE)  ? l0_w[addr]  : {N{1'b0}};
                4'd1:  weight_lookup = (addr < L1_W_SIZE)  ? l1_w[addr]  : {N{1'b0}};
                4'd2:  weight_lookup = (addr < L2_W_SIZE)  ? l2_w[addr]  : {N{1'b0}};
                4'd3:  weight_lookup = (addr < L3_W_SIZE)  ? l3_w[addr]  : {N{1'b0}};
                4'd4:  weight_lookup = (addr < L4_W_SIZE)  ? l4_w[addr]  : {N{1'b0}};
                4'd5:  weight_lookup = (addr < L5_W_SIZE)  ? l5_w[addr]  : {N{1'b0}};
                4'd6:  weight_lookup = (addr < L6_W_SIZE)  ? l6_w[addr]  : {N{1'b0}};
                4'd7:  weight_lookup = (addr < L7_W_SIZE)  ? l7_w[addr]  : {N{1'b0}};
                4'd8:  weight_lookup = (addr < L8_W_SIZE)  ? l8_w[addr]  : {N{1'b0}};
                4'd9:  weight_lookup = (addr < L9_W_SIZE)  ? l9_w[addr]  : {N{1'b0}};
                4'd10: weight_lookup = (addr < L10_W_SIZE) ? l10_w[addr] : {N{1'b0}};
                4'd11: weight_lookup = (addr < L11_W_SIZE) ? l11_w[addr] : {N{1'b0}};
                default: weight_lookup = {N{1'b0}};
            endcase
        end
    endfunction

    function [N-1:0] bias_lookup;
        input [3:0] layer_id;
        input [31:0] addr;
        begin
            case (layer_id)
                4'd0:  bias_lookup = (addr < C1)          ? l0_b[addr]  : {N{1'b0}};
                4'd1:  bias_lookup = (addr < C1)          ? l1_b[addr]  : {N{1'b0}};
                4'd2:  bias_lookup = (addr < C2)          ? l2_b[addr]  : {N{1'b0}};
                4'd3:  bias_lookup = (addr < C2)          ? l3_b[addr]  : {N{1'b0}};
                4'd4:  bias_lookup = (addr < C3)          ? l4_b[addr]  : {N{1'b0}};
                4'd5:  bias_lookup = (addr < C3)          ? l5_b[addr]  : {N{1'b0}};
                4'd6:  bias_lookup = (addr < C3)          ? l6_b[addr]  : {N{1'b0}};
                4'd7:  bias_lookup = (addr < C4)          ? l7_b[addr]  : {N{1'b0}};
                4'd8:  bias_lookup = (addr < C4)          ? l8_b[addr]  : {N{1'b0}};
                4'd9:  bias_lookup = (addr < C4)          ? l9_b[addr]  : {N{1'b0}};
                4'd10: bias_lookup = (addr < FC1)         ? l10_b[addr] : {N{1'b0}};
                4'd11: bias_lookup = (addr < NUM_CLASSES) ? l11_b[addr] : {N{1'b0}};
                default: bias_lookup = {N{1'b0}};
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (reset) begin
            param_resp_valid <= 1'b0;
            param_resp_data <= {N{1'b0}};
            feature_rd_resp_valid <= 1'b0;
            feature_rd_resp_data <= {N{1'b0}};
        end
        else begin
            param_resp_valid <= param_req_valid;
            if (param_req_valid && param_req_kind == PARAM_WEIGHT)
                param_resp_data <= canonical_parameter(
                    weight_lookup(param_req_layer, param_req_addr));
            else if (param_req_valid && param_req_kind == PARAM_BIAS)
                param_resp_data <= canonical_parameter(
                    bias_lookup(param_req_layer, param_req_addr));
            else
                param_resp_data <= {N{1'b0}};

            feature_rd_resp_valid <= feature_rd_req_valid;
            if (feature_rd_req_valid && feature_rd_addr < MAX_FEATURE_VALUES) begin
                if (feature_rd_bank)
                    feature_rd_resp_data <= feature_bank1[feature_rd_addr];
                else
                    feature_rd_resp_data <= feature_bank0[feature_rd_addr];
            end
            else begin
                feature_rd_resp_data <= {N{1'b0}};
            end

            if (feature_wr_valid && feature_wr_addr < MAX_FEATURE_VALUES) begin
                if (feature_wr_bank)
                    feature_bank1[feature_wr_addr] <= feature_wr_data;
                else
                    feature_bank0[feature_wr_addr] <= feature_wr_data;
            end
        end
    end

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
            observed_logits[addr] = logit_read_data;
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

    task preload_image_fast;
        input integer array_base;
        begin
            for (i = 0; i < MAX_FEATURE_VALUES; i = i + 1) begin
                feature_bank0[i] = {N{1'b0}};
                feature_bank1[i] = {N{1'b0}};
            end
            for (i = 0; i < IMAGE_SIZE; i = i + 1)
                feature_bank0[i] = pixels[array_base + i];
            $display("Fast-loaded image %0d into external feature bank 0", test_image);
        end
    endtask

    task preload_weights_fast;
        begin
            $display("Weights and biases remain in the external parameter memory model");
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
        $display("External parameter model ready for %0s weights=%0d biases=%0d", NAME, W_COUNT, B_COUNT); \
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
        param_resp_valid = 1'b0;
        param_resp_data = {N{1'b0}};
        feature_rd_resp_valid = 1'b0;
        feature_rd_resp_data = {N{1'b0}};
        timeout = 0;
        errors = 0;
        correct_count = 0;
        test_image = 0;
        run_images = NUM_TEST_IMAGES;
        image_base = 0;
        zero_logit_count = 0;

`include "tb/cnn/mnist_expected_labels.vh"

        for (i = 0; i < NUM_TEST_IMAGES; i = i + 1) begin
            predicted_class[i] = -1;
            expected_class_int[i] = expected_class[i];
        end

        for (i = 0; i < NUM_CLASSES; i = i + 1)
            observed_logits[i] = {N{1'b0}};

        read_all_memories();

        if ($value$plusargs("max_images=%d", run_images)) begin
            if (run_images < 1)
                run_images = 1;
            else if (run_images > NUM_TEST_IMAGES)
                run_images = NUM_TEST_IMAGES;
        end
        if ($test$plusargs("one_image"))
            run_images = 1;

        repeat (8) @(posedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);

        $display("Starting full VGG16-MNIST posit<8,1> inference memory load");
        if (FAST_BACKDOOR_LOAD) begin
            preload_weights_fast();
        end
        else begin
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
        end

        $display("Weight and bias load complete; starting %0d-image inference run", run_images);

        for (test_image = 0; test_image < run_images; test_image = test_image + 1) begin
            image_base = test_image * IMAGE_SIZE;
            timeout = 0;

            $display("------------------------------------------------------------");
            $display("Image %0d expected digit %0d", test_image, expected_class[test_image]);
            if (FAST_BACKDOOR_LOAD)
                preload_image_fast(image_base);
            else
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

            zero_logit_count = 0;
            for (i = 0; i < NUM_CLASSES; i = i + 1) begin
                if (observed_logits[i] == {N{1'b0}})
                    zero_logit_count = zero_logit_count + 1;
            end
            if (zero_logit_count == NUM_CLASSES)
                $display("WARN image %0d all logits are zero; inference data path likely went inactive before classifier output",
                         test_image);

            predicted_class[test_image] = class_out;

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
        $display("Image predictions summary:");
        for (i = 0; i < run_images; i = i + 1)
            $display("  image %0d predicted=%0d expected=%0d",
                     i, predicted_class[i], expected_class_int[i]);
        $display("Accuracy = %0d / %0d", correct_count, run_images);

        if (errors == 0)
            $display("tb_reduced_vgg16_mnist_mem_inference PASS");
        else
            $display("tb_reduced_vgg16_mnist_mem_inference FAIL errors=%0d", errors);

        $finish;
    end

`undef LOAD_INPUT
`undef LOAD_WB
endmodule
