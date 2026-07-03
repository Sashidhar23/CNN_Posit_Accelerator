`timescale 1ns / 1ps

module reduced_vgg16_mnist #(
    parameter N = 8,
    parameter ES = 1,
    parameter IN_CH = 1,
    parameter IN_H = 28,
    parameter IN_W = 28,
    parameter C1 = 64,
    parameter C2 = 128,
    parameter C3 = 256,
    parameter C4 = 512,
    parameter FC1 = 256,
    parameter NUM_CLASSES = 10,
    parameter ROWS = 6,
    parameter COLS = 6,
    parameter CLASS_W = (NUM_CLASSES <= 2) ? 1 : $clog2(NUM_CLASSES),
    parameter H1 = IN_H,
    parameter W1 = IN_W,
    parameter H2 = ((H1 - 2) / 2) + 1,
    parameter W2 = ((W1 - 2) / 2) + 1,
    parameter H3 = ((H2 - 2) / 2) + 1,
    parameter W3 = ((W2 - 2) / 2) + 1,
    parameter H4 = ((H3 - 2) / 2) + 1,
    parameter W4 = ((W3 - 2) / 2) + 1,
    parameter H5 = ((H4 - 2) / 2) + 1,
    parameter W5 = ((W4 - 2) / 2) + 1
)(
    input  wire clk,
    input  wire reset,
    input  wire start,

    input  wire cfg_write_en,
    input  wire [3:0] cfg_layer,
    input  wire [1:0] cfg_mem,
    input  wire [31:0] cfg_addr,
    input  wire [N-1:0] cfg_data,

    input  wire [31:0] logit_read_addr,
    output wire [N-1:0] logit_read_data,

    output reg busy,
    output reg done,
    output reg [CLASS_W-1:0] class_out
);

    localparam [1:0] CFG_INPUT  = 2'd0;
    localparam [1:0] CFG_WEIGHT = 2'd1;
    localparam [1:0] CFG_BIAS   = 2'd2;

    localparam [3:0] S_IDLE              = 4'd0;
    localparam [3:0] S_START_LAYER       = 4'd1;
    localparam [3:0] S_WAIT_LAYER        = 4'd2;
    localparam [3:0] S_COPY_DIRECT_SET   = 4'd3;
    localparam [3:0] S_COPY_DIRECT_WRITE = 4'd4;
    localparam [3:0] S_COPY_POOL_SET     = 4'd5;
    localparam [3:0] S_COPY_POOL_CAPTURE = 4'd6;
    localparam [3:0] S_ARGMAX_SET        = 4'd7;
    localparam [3:0] S_ARGMAX_CAPTURE    = 4'd8;
    localparam [3:0] S_DONE              = 4'd9;
    localparam [3:0] S_COPY_DIRECT_WAIT  = 4'd10;
    localparam [3:0] S_COPY_POOL_WAIT    = 4'd11;
    localparam [3:0] S_ARGMAX_WAIT       = 4'd12;

    reg [3:0] state;
    reg [3:0] current_layer;
    reg [11:0] layer_start;

    wire [11:0] layer_done;

    reg [3:0] copy_src;
    reg [3:0] copy_dst;
    reg [31:0] copy_idx;
    reg [31:0] copy_total;
    reg [31:0] copy_src_addr;
    reg [31:0] copy_dst_addr;
    reg [31:0] copy_src_h;
    reg [31:0] copy_src_w;
    reg [31:0] copy_dst_h;
    reg [31:0] copy_dst_w;
    reg [1:0] pool_pos;
    reg [4*N-1:0] pool_window;
    reg [4*N-1:0] pool_window_candidate;
    reg copy_write_en;
    reg [N-1:0] copy_write_data;

    reg [31:0] argmax_idx;
    reg [31:0] argmax_addr;
    reg [N-1:0] argmax_best_value;
    reg [CLASS_W-1:0] argmax_best_class;

    wire [N-1:0] l0_out_data;
    wire [N-1:0] l1_out_data;
    wire [N-1:0] l2_out_data;
    wire [N-1:0] l3_out_data;
    wire [N-1:0] l4_out_data;
    wire [N-1:0] l5_out_data;
    wire [N-1:0] l6_out_data;
    wire [N-1:0] l7_out_data;
    wire [N-1:0] l8_out_data;
    wire [N-1:0] l9_out_data;
    wire [N-1:0] l10_out_data;
    wire [N-1:0] l11_out_data;
    reg  [N-1:0] selected_src_data;
    wire [N-1:0] relu_single_out;
    wire [N-1:0] pool_single_out;

    reg [31:0] l0_out_addr;
    reg [31:0] l1_out_addr;
    reg [31:0] l2_out_addr;
    reg [31:0] l3_out_addr;
    reg [31:0] l4_out_addr;
    reg [31:0] l5_out_addr;
    reg [31:0] l6_out_addr;
    reg [31:0] l7_out_addr;
    reg [31:0] l8_out_addr;
    reg [31:0] l9_out_addr;
    reg [31:0] l10_out_addr;
    reg [31:0] l11_out_addr;

    wire cfg_l0 = cfg_write_en && (cfg_layer == 4'd0);
    wire cfg_l1 = cfg_write_en && (cfg_layer == 4'd1);
    wire cfg_l2 = cfg_write_en && (cfg_layer == 4'd2);
    wire cfg_l3 = cfg_write_en && (cfg_layer == 4'd3);
    wire cfg_l4 = cfg_write_en && (cfg_layer == 4'd4);
    wire cfg_l5 = cfg_write_en && (cfg_layer == 4'd5);
    wire cfg_l6 = cfg_write_en && (cfg_layer == 4'd6);
    wire cfg_l7 = cfg_write_en && (cfg_layer == 4'd7);
    wire cfg_l8 = cfg_write_en && (cfg_layer == 4'd8);
    wire cfg_l9 = cfg_write_en && (cfg_layer == 4'd9);
    wire cfg_l10 = cfg_write_en && (cfg_layer == 4'd10);
    wire cfg_l11 = cfg_write_en && (cfg_layer == 4'd11);

    wire [31:0] copy_or_cfg_addr = copy_write_en ? copy_dst_addr : cfg_addr;
    wire [N-1:0] copy_or_cfg_data = copy_write_en ? copy_write_data : cfg_data;

    function [31:0] pool_source_addr;
        input [31:0] out_index;
        input [31:0] src_h;
        input [31:0] src_w;
        input [31:0] dst_h;
        input [31:0] dst_w;
        input [1:0] pos;
        integer ch;
        integer rem;
        integer oy;
        integer ox;
        integer ky;
        integer kx;
        integer iy;
        integer ix;
        begin
            ch = out_index / (dst_h * dst_w);
            rem = out_index - (ch * dst_h * dst_w);
            oy = rem / dst_w;
            ox = rem - (oy * dst_w);
            ky = pos / 2;
            kx = pos - (ky * 2);
            iy = (oy * 2) + ky;
            ix = (ox * 2) + kx;
            pool_source_addr = (ch * src_h * src_w) + (iy * src_w) + ix;
        end
    endfunction

    function is_better_logit;
        input [N-1:0] candidate;
        input [N-1:0] current;
        begin
            if (candidate == {1'b1, {(N-1){1'b0}}})
                is_better_logit = 1'b0;
            else if (current == {1'b1, {(N-1){1'b0}}})
                is_better_logit = 1'b1;
            else
                is_better_logit = ($signed(candidate) > $signed(current));
        end
    endfunction

    posit_relu2d #(
        .N(N),
        .CHANNELS(1),
        .HEIGHT(1),
        .WIDTH(1)
    ) RELU_COPY (
        .data_in(selected_src_data),
        .data_out(relu_single_out)
    );

    posit_maxpool2d #(
        .N(N),
        .CHANNELS(1),
        .HEIGHT(2),
        .WIDTH(2),
        .POOL_SIZE(2),
        .STRIDE(2)
    ) POOL_COPY (
        .feature_in(pool_window_candidate),
        .pool_out(pool_single_out)
    );

    always @(*) begin
        pool_window_candidate = pool_window;
        pool_window_candidate[pool_pos*N +: N] = relu_single_out;

        l0_out_addr = 0;
        l1_out_addr = 0;
        l2_out_addr = 0;
        l3_out_addr = 0;
        l4_out_addr = 0;
        l5_out_addr = 0;
        l6_out_addr = 0;
        l7_out_addr = 0;
        l8_out_addr = 0;
        l9_out_addr = 0;
        l10_out_addr = 0;
        l11_out_addr = logit_read_addr;

        case (copy_src)
            4'd0: l0_out_addr = copy_src_addr;
            4'd1: l1_out_addr = copy_src_addr;
            4'd2: l2_out_addr = copy_src_addr;
            4'd3: l3_out_addr = copy_src_addr;
            4'd4: l4_out_addr = copy_src_addr;
            4'd5: l5_out_addr = copy_src_addr;
            4'd6: l6_out_addr = copy_src_addr;
            4'd7: l7_out_addr = copy_src_addr;
            4'd8: l8_out_addr = copy_src_addr;
            4'd9: l9_out_addr = copy_src_addr;
            4'd10: l10_out_addr = copy_src_addr;
            default: begin end
        endcase

        if (state == S_ARGMAX_SET || state == S_ARGMAX_WAIT || state == S_ARGMAX_CAPTURE)
            l11_out_addr = argmax_addr;

        selected_src_data = {N{1'b0}};
        case (copy_src)
            4'd0: selected_src_data = l0_out_data;
            4'd1: selected_src_data = l1_out_data;
            4'd2: selected_src_data = l2_out_data;
            4'd3: selected_src_data = l3_out_data;
            4'd4: selected_src_data = l4_out_data;
            4'd5: selected_src_data = l5_out_data;
            4'd6: selected_src_data = l6_out_data;
            4'd7: selected_src_data = l7_out_data;
            4'd8: selected_src_data = l8_out_data;
            4'd9: selected_src_data = l9_out_data;
            4'd10: selected_src_data = l10_out_data;
            default: selected_src_data = {N{1'b0}};
        endcase
    end

    assign logit_read_data = l11_out_data;

    conv2D #(.N(N), .ES(ES), .IN_CH(IN_CH), .IN_H(H1), .IN_W(W1), .OUT_CH(C1), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L0 (
        .clk(clk), .reset(reset), .start(layer_start[0]),
        .ext_input_write_en((cfg_l0 && cfg_mem == CFG_INPUT)), .ext_input_addr(cfg_addr), .ext_input_data(cfg_data),
        .ext_weight_write_en((cfg_l0 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l0 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l0_out_addr), .ext_output_data(l0_out_data), .busy(), .done(layer_done[0])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C1), .IN_H(H1), .IN_W(W1), .OUT_CH(C1), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L1 (
        .clk(clk), .reset(reset), .start(layer_start[1]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd1) || (cfg_l1 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l1 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l1 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l1_out_addr), .ext_output_data(l1_out_data), .busy(), .done(layer_done[1])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C1), .IN_H(H2), .IN_W(W2), .OUT_CH(C2), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L2 (
        .clk(clk), .reset(reset), .start(layer_start[2]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd2) || (cfg_l2 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l2 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l2 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l2_out_addr), .ext_output_data(l2_out_data), .busy(), .done(layer_done[2])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C2), .IN_H(H2), .IN_W(W2), .OUT_CH(C2), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L3 (
        .clk(clk), .reset(reset), .start(layer_start[3]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd3) || (cfg_l3 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l3 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l3 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l3_out_addr), .ext_output_data(l3_out_data), .busy(), .done(layer_done[3])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C2), .IN_H(H3), .IN_W(W3), .OUT_CH(C3), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L4 (
        .clk(clk), .reset(reset), .start(layer_start[4]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd4) || (cfg_l4 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l4 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l4 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l4_out_addr), .ext_output_data(l4_out_data), .busy(), .done(layer_done[4])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C3), .IN_H(H3), .IN_W(W3), .OUT_CH(C3), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L5 (
        .clk(clk), .reset(reset), .start(layer_start[5]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd5) || (cfg_l5 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l5 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l5 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l5_out_addr), .ext_output_data(l5_out_data), .busy(), .done(layer_done[5])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C3), .IN_H(H3), .IN_W(W3), .OUT_CH(C3), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L6 (
        .clk(clk), .reset(reset), .start(layer_start[6]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd6) || (cfg_l6 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l6 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l6 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l6_out_addr), .ext_output_data(l6_out_data), .busy(), .done(layer_done[6])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C3), .IN_H(H4), .IN_W(W4), .OUT_CH(C4), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L7 (
        .clk(clk), .reset(reset), .start(layer_start[7]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd7) || (cfg_l7 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l7 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l7 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l7_out_addr), .ext_output_data(l7_out_data), .busy(), .done(layer_done[7])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C4), .IN_H(H4), .IN_W(W4), .OUT_CH(C4), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L8 (
        .clk(clk), .reset(reset), .start(layer_start[8]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd8) || (cfg_l8 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l8 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l8 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l8_out_addr), .ext_output_data(l8_out_data), .busy(), .done(layer_done[8])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C4), .IN_H(H4), .IN_W(W4), .OUT_CH(C4), .K(3), .PADDING(1), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L9 (
        .clk(clk), .reset(reset), .start(layer_start[9]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd9) || (cfg_l9 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l9 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l9 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l9_out_addr), .ext_output_data(l9_out_data), .busy(), .done(layer_done[9])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(C4), .IN_H(H5), .IN_W(W5), .OUT_CH(FC1), .K(1), .PADDING(0), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L10 (
        .clk(clk), .reset(reset), .start(layer_start[10]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd10) || (cfg_l10 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l10 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l10 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l10_out_addr), .ext_output_data(l10_out_data), .busy(), .done(layer_done[10])
    );

    conv2D #(.N(N), .ES(ES), .IN_CH(FC1), .IN_H(1), .IN_W(1), .OUT_CH(NUM_CLASSES), .K(1), .PADDING(0), .STRIDE(1), .ROWS(ROWS), .COLS(COLS)) L11 (
        .clk(clk), .reset(reset), .start(layer_start[11]),
        .ext_input_write_en((copy_write_en && copy_dst == 4'd11) || (cfg_l11 && cfg_mem == CFG_INPUT)), .ext_input_addr(copy_or_cfg_addr), .ext_input_data(copy_or_cfg_data),
        .ext_weight_write_en((cfg_l11 && cfg_mem == CFG_WEIGHT)), .ext_weight_addr(cfg_addr), .ext_weight_data(cfg_data),
        .ext_bias_write_en((cfg_l11 && cfg_mem == CFG_BIAS)), .ext_bias_addr(cfg_addr), .ext_bias_data(cfg_data),
        .ext_output_addr(l11_out_addr), .ext_output_data(l11_out_data), .busy(), .done(layer_done[11])
    );

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            current_layer <= 0;
            layer_start <= 12'b0;
            busy <= 1'b0;
            done <= 1'b0;
            class_out <= {CLASS_W{1'b0}};
            copy_src <= 0;
            copy_dst <= 0;
            copy_idx <= 0;
            copy_total <= 0;
            copy_src_addr <= 0;
            copy_dst_addr <= 0;
            copy_src_h <= 0;
            copy_src_w <= 0;
            copy_dst_h <= 0;
            copy_dst_w <= 0;
            pool_pos <= 0;
            pool_window <= {4*N{1'b0}};
            copy_write_en <= 1'b0;
            copy_write_data <= {N{1'b0}};
            argmax_idx <= 0;
            argmax_addr <= 0;
            argmax_best_value <= {N{1'b0}};
            argmax_best_class <= {CLASS_W{1'b0}};
        end
        else begin
            layer_start <= 12'b0;
            copy_write_en <= 1'b0;
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        current_layer <= 0;
                        state <= S_START_LAYER;
                    end
                end

                S_START_LAYER: begin
                    layer_start[current_layer] <= 1'b1;
                    state <= S_WAIT_LAYER;
                end

                S_WAIT_LAYER: begin
                    if (layer_done[current_layer]) begin
                        copy_idx <= 0;
                        pool_pos <= 0;
                        pool_window <= {4*N{1'b0}};

                        case (current_layer)
                            4'd0: begin copy_src <= 0; copy_dst <= 1; copy_total <= C1*H1*W1; state <= S_COPY_DIRECT_SET; end
                            4'd1: begin copy_src <= 1; copy_dst <= 2; copy_total <= C1*H2*W2; copy_src_h <= H1; copy_src_w <= W1; copy_dst_h <= H2; copy_dst_w <= W2; state <= S_COPY_POOL_SET; end
                            4'd2: begin copy_src <= 2; copy_dst <= 3; copy_total <= C2*H2*W2; state <= S_COPY_DIRECT_SET; end
                            4'd3: begin copy_src <= 3; copy_dst <= 4; copy_total <= C2*H3*W3; copy_src_h <= H2; copy_src_w <= W2; copy_dst_h <= H3; copy_dst_w <= W3; state <= S_COPY_POOL_SET; end
                            4'd4: begin copy_src <= 4; copy_dst <= 5; copy_total <= C3*H3*W3; state <= S_COPY_DIRECT_SET; end
                            4'd5: begin copy_src <= 5; copy_dst <= 6; copy_total <= C3*H3*W3; state <= S_COPY_DIRECT_SET; end
                            4'd6: begin copy_src <= 6; copy_dst <= 7; copy_total <= C3*H4*W4; copy_src_h <= H3; copy_src_w <= W3; copy_dst_h <= H4; copy_dst_w <= W4; state <= S_COPY_POOL_SET; end
                            4'd7: begin copy_src <= 7; copy_dst <= 8; copy_total <= C4*H4*W4; state <= S_COPY_DIRECT_SET; end
                            4'd8: begin copy_src <= 8; copy_dst <= 9; copy_total <= C4*H4*W4; state <= S_COPY_DIRECT_SET; end
                            4'd9: begin copy_src <= 9; copy_dst <= 10; copy_total <= C4*H5*W5; copy_src_h <= H4; copy_src_w <= W4; copy_dst_h <= H5; copy_dst_w <= W5; state <= S_COPY_POOL_SET; end
                            4'd10: begin copy_src <= 10; copy_dst <= 11; copy_total <= FC1; state <= S_COPY_DIRECT_SET; end
                            default: begin argmax_idx <= 0; argmax_addr <= 0; state <= S_ARGMAX_SET; end
                        endcase
                    end
                end

                S_COPY_DIRECT_SET: begin
                    if (copy_idx < copy_total) begin
                        copy_src_addr <= copy_idx;
                        copy_dst_addr <= copy_idx;
                        state <= S_COPY_DIRECT_WAIT;
                    end
                    else begin
                        current_layer <= current_layer + 1'b1;
                        state <= S_START_LAYER;
                    end
                end

                S_COPY_DIRECT_WAIT: begin
                    state <= S_COPY_DIRECT_WRITE;
                end

                S_COPY_DIRECT_WRITE: begin
                    copy_write_data <= relu_single_out;
                    copy_write_en <= 1'b1;
                    copy_idx <= copy_idx + 1'b1;
                    state <= S_COPY_DIRECT_SET;
                end

                S_COPY_POOL_SET: begin
                    if (copy_idx < copy_total) begin
                        copy_src_addr <= pool_source_addr(copy_idx, copy_src_h, copy_src_w,
                                                          copy_dst_h, copy_dst_w, pool_pos);
                        copy_dst_addr <= copy_idx;
                        state <= S_COPY_POOL_WAIT;
                    end
                    else begin
                        current_layer <= current_layer + 1'b1;
                        state <= S_START_LAYER;
                    end
                end

                S_COPY_POOL_WAIT: begin
                    state <= S_COPY_POOL_CAPTURE;
                end

                S_COPY_POOL_CAPTURE: begin
                    if (pool_pos == 2'd3) begin
                        copy_write_data <= pool_single_out;
                        copy_write_en <= 1'b1;
                        copy_idx <= copy_idx + 1'b1;
                        pool_pos <= 0;
                        pool_window <= {4*N{1'b0}};
                    end
                    else begin
                        pool_window <= pool_window_candidate;
                        pool_pos <= pool_pos + 1'b1;
                    end
                    state <= S_COPY_POOL_SET;
                end

                S_ARGMAX_SET: begin
                    if (argmax_idx < NUM_CLASSES) begin
                        argmax_addr <= argmax_idx;
                        state <= S_ARGMAX_WAIT;
                    end
                    else begin
                        class_out <= argmax_best_class;
                        state <= S_DONE;
                    end
                end

                S_ARGMAX_WAIT: begin
                    state <= S_ARGMAX_CAPTURE;
                end

                S_ARGMAX_CAPTURE: begin
                    if (argmax_idx == 0 || is_better_logit(l11_out_data, argmax_best_value)) begin
                        argmax_best_value <= l11_out_data;
                        argmax_best_class <= argmax_idx[CLASS_W-1:0];
                    end
                    argmax_idx <= argmax_idx + 1'b1;
                    state <= S_ARGMAX_SET;
                end

                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule

