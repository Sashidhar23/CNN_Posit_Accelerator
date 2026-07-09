`timescale 1ns / 1ps

module reduced_vgg16_mnist_tiled_core #(
    parameter N = 8,
    parameter ES = 1,
    parameter USE_QUIRE = 0,
    parameter QW = 48,
    parameter QF = QW / 2,
    parameter IN_CH = 1,
    parameter IN_H = 28,
    parameter IN_W = 28,
    parameter C1 = 64,
    parameter C2 = 128,
    parameter C3 = 256,
    parameter C4 = 512,
    parameter FC1 = 256,
    parameter NUM_CLASSES = 10,
    parameter ROWS = 3,
    parameter COLS = 3,
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

    output reg         param_req_valid,
    output reg  [1:0]  param_req_kind,
    output reg  [3:0]  param_req_layer,
    output reg  [31:0] param_req_addr,
    input  wire        param_resp_valid,
    input  wire [N-1:0] param_resp_data,

    output reg         feature_rd_req_valid,
    output reg         feature_rd_bank,
    output reg  [31:0] feature_rd_addr,
    input  wire        feature_rd_resp_valid,
    input  wire [N-1:0] feature_rd_resp_data,

    output reg         feature_wr_valid,
    output reg         feature_wr_bank,
    output reg  [31:0] feature_wr_addr,
    output reg  [N-1:0] feature_wr_data,

    input  wire [31:0] logit_read_addr,
    output reg  [N-1:0] logit_read_data,

    output reg busy,
    output reg done,
    output reg [CLASS_W-1:0] class_out
);

    function integer imax;
        input integer a;
        input integer b;
        begin
            imax = (a > b) ? a : b;
        end
    endfunction

    localparam [1:0] CFG_INPUT  = 2'd0;
    localparam [1:0] CFG_WEIGHT = 2'd1;
    localparam [1:0] CFG_BIAS   = 2'd2;
    localparam [1:0] PARAM_WEIGHT = 2'd0;
    localparam [1:0] PARAM_BIAS   = 2'd1;

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
    localparam integer L10_W_SIZE = FC1 * C4 * H5 * W5;
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
    localparam integer TOTAL_WEIGHT_VALUES = L11_W_BASE + L11_W_SIZE;

    localparam integer L0_B_SIZE  = C1;
    localparam integer L1_B_SIZE  = C1;
    localparam integer L2_B_SIZE  = C2;
    localparam integer L3_B_SIZE  = C2;
    localparam integer L4_B_SIZE  = C3;
    localparam integer L5_B_SIZE  = C3;
    localparam integer L6_B_SIZE  = C3;
    localparam integer L7_B_SIZE  = C4;
    localparam integer L8_B_SIZE  = C4;
    localparam integer L9_B_SIZE  = C4;
    localparam integer L10_B_SIZE = FC1;
    localparam integer L11_B_SIZE = NUM_CLASSES;

    localparam integer L0_B_BASE  = 0;
    localparam integer L1_B_BASE  = L0_B_BASE  + L0_B_SIZE;
    localparam integer L2_B_BASE  = L1_B_BASE  + L1_B_SIZE;
    localparam integer L3_B_BASE  = L2_B_BASE  + L2_B_SIZE;
    localparam integer L4_B_BASE  = L3_B_BASE  + L3_B_SIZE;
    localparam integer L5_B_BASE  = L4_B_BASE  + L4_B_SIZE;
    localparam integer L6_B_BASE  = L5_B_BASE  + L5_B_SIZE;
    localparam integer L7_B_BASE  = L6_B_BASE  + L6_B_SIZE;
    localparam integer L8_B_BASE  = L7_B_BASE  + L7_B_SIZE;
    localparam integer L9_B_BASE  = L8_B_BASE  + L8_B_SIZE;
    localparam integer L10_B_BASE = L9_B_BASE  + L9_B_SIZE;
    localparam integer L11_B_BASE = L10_B_BASE + L10_B_SIZE;
    localparam integer TOTAL_BIAS_VALUES = L11_B_BASE + L11_B_SIZE;

    localparam integer MAX_FEATURE_VALUES =
        imax(IN_CH*H1*W1,
        imax(C1*H1*W1,
        imax(C1*H2*W2,
        imax(C2*H2*W2,
        imax(C2*H3*W3,
        imax(C3*H3*W3,
        imax(C3*H4*W4,
        imax(C4*H4*W4,
        imax(C4*H5*W5,
        imax(FC1, NUM_CLASSES))))))))));

    localparam integer MAX_OUT_PIXELS = imax(H1*W1, imax(H2*W2, imax(H3*W3, imax(H4*W4, imax(H5*W5, 1)))));
    localparam integer PIXEL_ADDR_W = (MAX_OUT_PIXELS <= 2) ? 1 : $clog2(MAX_OUT_PIXELS);
    localparam integer ROW_ADDR_W = (ROWS <= 2) ? 1 : $clog2(ROWS);
    localparam integer COL_ADDR_W = (COLS <= 2) ? 1 : $clog2(COLS);
    localparam integer WEIGHT_ADDR_W = (ROWS*COLS <= 2) ? 1 : $clog2(ROWS*COLS);

    localparam [5:0] ST_IDLE              = 6'd0;
    localparam [5:0] ST_SETUP_LAYER       = 6'd1;
    localparam [5:0] ST_INIT_TILE         = 6'd2;
    localparam [5:0] ST_LOAD_TILE         = 6'd3;
    localparam [5:0] ST_STREAM_TILE       = 6'd4;
    localparam [5:0] ST_NEXT_DOT          = 6'd5;
    localparam [5:0] ST_NEXT_OC           = 6'd6;
    localparam [5:0] ST_POST_DIRECT_SET   = 6'd7;
    localparam [5:0] ST_POST_DIRECT_WAIT  = 6'd8;
    localparam [5:0] ST_POST_DIRECT_WRITE = 6'd9;
    localparam [5:0] ST_POST_POOL_SET     = 6'd10;
    localparam [5:0] ST_POST_POOL_WAIT    = 6'd11;
    localparam [5:0] ST_POST_POOL_CAPTURE = 6'd12;
    localparam [5:0] ST_ARGMAX_SET        = 6'd13;
    localparam [5:0] ST_ARGMAX_WAIT       = 6'd14;
    localparam [5:0] ST_ARGMAX_CAPTURE    = 6'd15;
    localparam [5:0] ST_DONE              = 6'd16;
    localparam [5:0] ST_STORE_LOGITS      = 6'd17;
    localparam [5:0] ST_PREP_ACT_READ     = 6'd18;
    localparam [5:0] ST_PREP_ACT_CAPTURE  = 6'd19;
    localparam [5:0] ST_PREP_ACT_WAIT     = 6'd20;
    localparam [5:0] ST_FETCH_BIAS        = 6'd21;
    localparam [5:0] ST_FETCH_BIAS_WAIT   = 6'd22;
    localparam [5:0] ST_LOAD_TILE_WAIT    = 6'd23;

    localparam [N-1:0] POSIT_ZERO = {N{1'b0}};
    localparam [N-1:0] POSIT_NAR  = {1'b1, {(N-1){1'b0}}};

    (* ram_style = "distributed" *) reg [N-1:0] tile_out [0:(COLS*MAX_OUT_PIXELS)-1];
    (* ram_style = "block" *) reg signed [QW-1:0] quire_tile_out [0:COLS-1][0:MAX_OUT_PIXELS-1];
    reg quire_tile_nar [0:COLS-1][0:MAX_OUT_PIXELS-1];
    (* ram_style = "distributed" *) reg [N-1:0] logit_mem [0:NUM_CLASSES-1];
    reg [N-1:0] bias_tile [0:COLS-1];

    reg [5:0] state;
    reg [3:0] current_layer;

    reg [31:0] cur_in_ch;
    reg [31:0] cur_out_ch;
    reg [31:0] cur_in_h;
    reg [31:0] cur_in_w;
    reg [31:0] cur_out_h;
    reg [31:0] cur_out_w;
    reg [31:0] cur_k;
    reg [31:0] cur_padding;
    reg [31:0] cur_dot_len;
    reg [31:0] cur_out_pixels;
    reg [31:0] cur_weight_base;
    reg [31:0] cur_bias_base;
    reg [31:0] cur_pool_out_h;
    reg [31:0] cur_pool_out_w;
    reg        cur_pool_after;
    reg        cur_final_layer;

    reg [31:0] oc_base;
    reg [31:0] dot_base;
    reg [31:0] init_col;
    reg [31:0] init_pix;
    reg [31:0] bias_index;
    reg [31:0] load_index;
    reg [31:0] stream_send_count;
    reg [31:0] stream_recv_count;
    reg [31:0] stream_x;
    reg [31:0] stream_y;
    reg [31:0] prep_row;

    reg [31:0] post_idx;
    reg [31:0] post_total;
    reg [31:0] post_read_addr;
    reg [31:0] post_ch;
    reg [31:0] post_oy;
    reg [31:0] post_ox;
    reg [1:0]  pool_pos;
    reg [4*N-1:0] pool_window;
    reg [4*N-1:0] pool_window_candidate;
    reg [N-1:0] selected_post_data;

    reg [31:0] argmax_idx;
    reg [31:0] argmax_addr;
    reg [N-1:0] argmax_best_value;
    reg [CLASS_W-1:0] argmax_best_class;
    reg [N-1:0] selected_logit_data;

    reg core_pe_en;
    reg core_clear_pipe;
    reg core_wshift;
    reg core_stream_valid;
    reg [PIXEL_ADDR_W-1:0] core_stream_tag;
    reg [ROWS*N-1:0] core_activation_vector_data;
    reg core_weight_load_en;
    reg [WEIGHT_ADDR_W-1:0] core_weight_addr;
    reg [N-1:0] core_weight_data;

    wire core_result_valid;
    wire [PIXEL_ADDR_W-1:0] core_result_tag;
    wire [COLS*QW-1:0] core_result_quire_data;
    wire [COLS*N-1:0] core_result_data;
    wire [COLS-1:0] core_result_is_nar;

    wire [N-1:0] relu_single_out;
    wire [N-1:0] pool_single_out;
    wire [N-1:0] stream_acc_old [0:COLS-1];
    wire [N-1:0] stream_acc_sum [0:COLS-1];
    wire [N-1:0] stream_acc_write [0:COLS-1];
    wire stream_result_accept_valid;
    wire signed [QW-1:0] bias_quire [0:COLS-1];
    wire bias_quire_nar [0:COLS-1];
    wire signed [QW-1:0] quire_acc_old [0:COLS-1];
    wire quire_acc_old_nar [0:COLS-1];
    wire signed [QW-1:0] quire_acc_sum [0:COLS-1];
    wire quire_acc_sum_nar [0:COLS-1];

    reg quire_result_valid_d;
    reg [PIXEL_ADDR_W-1:0] quire_result_tag_d;
    reg [COLS*QW-1:0] quire_result_data_d;
    reg [COLS-1:0] quire_result_is_nar_d;
    reg signed [QW-1:0] quire_acc_old_reg [0:COLS-1];
    reg quire_acc_old_nar_reg [0:COLS-1];

    integer i;
    integer load_row;
    integer load_col;
    integer dot_idx;
    integer out_ch_idx;
    integer out_index;
    integer local_col;
    integer local_pix;
    integer dest_index;
    integer pool_out_pixels;
    integer ky;
    integer kx;

    assign stream_result_accept_valid =
        (USE_QUIRE != 0) ? quire_result_valid_d : core_result_valid;

    function [31:0] layer_in_ch;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_in_ch = IN_CH;
                4'd1: layer_in_ch = C1;
                4'd2: layer_in_ch = C1;
                4'd3: layer_in_ch = C2;
                4'd4: layer_in_ch = C2;
                4'd5: layer_in_ch = C3;
                4'd6: layer_in_ch = C3;
                4'd7: layer_in_ch = C3;
                4'd8: layer_in_ch = C4;
                4'd9: layer_in_ch = C4;
                4'd10: layer_in_ch = C4;
                default: layer_in_ch = FC1;
            endcase
        end
    endfunction

    function [31:0] layer_out_ch;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_out_ch = C1;
                4'd1: layer_out_ch = C1;
                4'd2: layer_out_ch = C2;
                4'd3: layer_out_ch = C2;
                4'd4: layer_out_ch = C3;
                4'd5: layer_out_ch = C3;
                4'd6: layer_out_ch = C3;
                4'd7: layer_out_ch = C4;
                4'd8: layer_out_ch = C4;
                4'd9: layer_out_ch = C4;
                4'd10: layer_out_ch = FC1;
                default: layer_out_ch = NUM_CLASSES;
            endcase
        end
    endfunction

    function [31:0] layer_in_h;
        input [3:0] layer;
        begin
            case (layer)
                4'd0, 4'd1: layer_in_h = H1;
                4'd2, 4'd3: layer_in_h = H2;
                4'd4, 4'd5, 4'd6: layer_in_h = H3;
                4'd7, 4'd8, 4'd9: layer_in_h = H4;
                4'd10: layer_in_h = H5;
                default: layer_in_h = 1;
            endcase
        end
    endfunction

    function [31:0] layer_in_w;
        input [3:0] layer;
        begin
            case (layer)
                4'd0, 4'd1: layer_in_w = W1;
                4'd2, 4'd3: layer_in_w = W2;
                4'd4, 4'd5, 4'd6: layer_in_w = W3;
                4'd7, 4'd8, 4'd9: layer_in_w = W4;
                4'd10: layer_in_w = W5;
                default: layer_in_w = 1;
            endcase
        end
    endfunction

    function [31:0] layer_weight_base;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_weight_base = L0_W_BASE;
                4'd1: layer_weight_base = L1_W_BASE;
                4'd2: layer_weight_base = L2_W_BASE;
                4'd3: layer_weight_base = L3_W_BASE;
                4'd4: layer_weight_base = L4_W_BASE;
                4'd5: layer_weight_base = L5_W_BASE;
                4'd6: layer_weight_base = L6_W_BASE;
                4'd7: layer_weight_base = L7_W_BASE;
                4'd8: layer_weight_base = L8_W_BASE;
                4'd9: layer_weight_base = L9_W_BASE;
                4'd10: layer_weight_base = L10_W_BASE;
                default: layer_weight_base = L11_W_BASE;
            endcase
        end
    endfunction

    function [31:0] layer_weight_size;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_weight_size = L0_W_SIZE;
                4'd1: layer_weight_size = L1_W_SIZE;
                4'd2: layer_weight_size = L2_W_SIZE;
                4'd3: layer_weight_size = L3_W_SIZE;
                4'd4: layer_weight_size = L4_W_SIZE;
                4'd5: layer_weight_size = L5_W_SIZE;
                4'd6: layer_weight_size = L6_W_SIZE;
                4'd7: layer_weight_size = L7_W_SIZE;
                4'd8: layer_weight_size = L8_W_SIZE;
                4'd9: layer_weight_size = L9_W_SIZE;
                4'd10: layer_weight_size = L10_W_SIZE;
                default: layer_weight_size = L11_W_SIZE;
            endcase
        end
    endfunction

    function [31:0] layer_bias_base;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_bias_base = L0_B_BASE;
                4'd1: layer_bias_base = L1_B_BASE;
                4'd2: layer_bias_base = L2_B_BASE;
                4'd3: layer_bias_base = L3_B_BASE;
                4'd4: layer_bias_base = L4_B_BASE;
                4'd5: layer_bias_base = L5_B_BASE;
                4'd6: layer_bias_base = L6_B_BASE;
                4'd7: layer_bias_base = L7_B_BASE;
                4'd8: layer_bias_base = L8_B_BASE;
                4'd9: layer_bias_base = L9_B_BASE;
                4'd10: layer_bias_base = L10_B_BASE;
                default: layer_bias_base = L11_B_BASE;
            endcase
        end
    endfunction

    function [31:0] layer_bias_size;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_bias_size = L0_B_SIZE;
                4'd1: layer_bias_size = L1_B_SIZE;
                4'd2: layer_bias_size = L2_B_SIZE;
                4'd3: layer_bias_size = L3_B_SIZE;
                4'd4: layer_bias_size = L4_B_SIZE;
                4'd5: layer_bias_size = L5_B_SIZE;
                4'd6: layer_bias_size = L6_B_SIZE;
                4'd7: layer_bias_size = L7_B_SIZE;
                4'd8: layer_bias_size = L8_B_SIZE;
                4'd9: layer_bias_size = L9_B_SIZE;
                4'd10: layer_bias_size = L10_B_SIZE;
                default: layer_bias_size = L11_B_SIZE;
            endcase
        end
    endfunction

    function layer_has_pool;
        input [3:0] layer;
        begin
            layer_has_pool = (layer == 4'd1) || (layer == 4'd3) ||
                             (layer == 4'd6) || (layer == 4'd9);
        end
    endfunction

    function [31:0] activation_addr;
        input integer dot;
        input integer y;
        input integer x;
        integer ch;
        integer rem;
        integer fy;
        integer fx;
        integer iy;
        integer ix;
        integer addr;
        begin
            ch = dot / (cur_k * cur_k);
            rem = dot - (ch * cur_k * cur_k);
            fy = rem / cur_k;
            fx = rem - (fy * cur_k);
            iy = y + fy - cur_padding;
            ix = x + fx - cur_padding;
            addr = (ch * cur_in_h * cur_in_w) + (iy * cur_in_w) + ix;

            if ((dot < cur_dot_len) &&
                (iy >= 0) && (iy < cur_in_h) &&
                (ix >= 0) && (ix < cur_in_w) &&
                (addr >= 0) && (addr < MAX_FEATURE_VALUES))
                activation_addr = addr;
            else
                activation_addr = MAX_FEATURE_VALUES;
        end
    endfunction

    function is_better_logit;
        input [N-1:0] candidate;
        input [N-1:0] current;
        begin
            if (candidate == POSIT_NAR)
                is_better_logit = 1'b0;
            else if (current == POSIT_NAR)
                is_better_logit = 1'b1;
            else
                is_better_logit = ($signed(candidate) > $signed(current));
        end
    endfunction

    always @(*) begin
        selected_post_data = POSIT_ZERO;
        if (post_read_addr < COLS*MAX_OUT_PIXELS)
            selected_post_data = tile_out[post_read_addr];

        selected_logit_data = POSIT_ZERO;
        if (argmax_addr < NUM_CLASSES)
            selected_logit_data = logit_mem[argmax_addr];

        pool_window_candidate = pool_window;
        pool_window_candidate[pool_pos*N +: N] = relu_single_out;
    end

    always @(posedge clk) begin
        if (logit_read_addr < NUM_CLASSES)
            logit_read_data <= logit_mem[logit_read_addr];
        else
            logit_read_data <= POSIT_ZERO;
    end

    posit_relu2d #(
        .N(N),
        .CHANNELS(1),
        .HEIGHT(1),
        .WIDTH(1)
    ) RELU_SCALAR (
        .data_in(selected_post_data),
        .data_out(relu_single_out)
    );

    posit_maxpool2d #(
        .N(N),
        .CHANNELS(1),
        .HEIGHT(2),
        .WIDTH(2),
        .POOL_SIZE(2),
        .STRIDE(2)
    ) POOL_SCALAR (
        .feature_in(pool_window_candidate),
        .pool_out(pool_single_out)
    );

    genvar gc;
    generate
        if (USE_QUIRE == 0) begin : REGULAR_ACCUM_GEN
            for (gc = 0; gc < COLS; gc = gc + 1) begin : STREAM_ACC_GEN
                assign stream_acc_old[gc] =
                    ((oc_base + gc) < cur_out_ch &&
                     core_result_tag < MAX_OUT_PIXELS) ?
                    tile_out[(gc * MAX_OUT_PIXELS) + core_result_tag] :
                    POSIT_ZERO;

                posit_adder #(
                    .N(N),
                    .ES(ES)
                ) STREAM_ACCUM_ADDER (
                    .posit_a(stream_acc_old[gc]),
                    .posit_b(core_result_data[gc*N +: N]),
                    .posit_out(stream_acc_sum[gc])
                );

                assign stream_acc_write[gc] = stream_acc_sum[gc];
                assign bias_quire[gc] = {QW{1'b0}};
                assign bias_quire_nar[gc] = 1'b0;
                assign quire_acc_old[gc] = {QW{1'b0}};
                assign quire_acc_old_nar[gc] = 1'b0;
                assign quire_acc_sum[gc] = {QW{1'b0}};
                assign quire_acc_sum_nar[gc] = 1'b0;
            end
        end
        else begin : QUIRE_ACCUM_GEN
            for (gc = 0; gc < COLS; gc = gc + 1) begin : STREAM_ACC_GEN
                posit_to_quire #(
                    .N(N),
                    .ES(ES),
                    .QW(QW),
                    .QF(QF)
                ) BIAS_TO_QUIRE (
                    .posit_in  (bias_tile[gc]),
                    .quire_out (bias_quire[gc]),
                    .is_nar    (bias_quire_nar[gc])
                );

                assign stream_acc_old[gc] = POSIT_ZERO;
                assign stream_acc_sum[gc] = POSIT_ZERO;
                assign quire_acc_old[gc] = quire_acc_old_reg[gc];
                assign quire_acc_old_nar[gc] = quire_acc_old_nar_reg[gc];
                (* use_dsp = "yes" *) assign quire_acc_sum[gc] =
                    quire_acc_old[gc] + quire_result_data_d[gc*QW +: QW];
                assign quire_acc_sum_nar[gc] =
                    quire_acc_old_nar[gc] | quire_result_is_nar_d[gc];

                quire_to_posit #(
                    .N(N),
                    .ES(ES),
                    .QW(QW),
                    .QF(QF)
                ) QSUM_TO_POSIT (
                    .quire_in  (quire_acc_sum[gc]),
                    .is_nar    (quire_acc_sum_nar[gc]),
                    .posit_out (stream_acc_write[gc])
                );
            end
        end
    endgenerate

    generate
        if (USE_QUIRE == 0) begin : REGULAR_CORE
            assign core_result_is_nar = {COLS{1'b0}};
            assign core_result_quire_data = {COLS*QW{1'b0}};

            systolic_stream_core #(
                .N(N),
                .ES(ES),
                .ROWS(ROWS),
                .COLS(COLS),
                .TAG_W(PIXEL_ADDR_W),
                .ROW_ADDR_W(ROW_ADDR_W),
                .COL_ADDR_W(COL_ADDR_W),
                .WEIGHT_ADDR_W(WEIGHT_ADDR_W)
            ) STREAM_CORE (
                .clk(clk),
                .reset(reset),
                .pe_en(core_pe_en),
                .clear_pipe(core_clear_pipe),
                .wshift(core_wshift),
                .activation_in(core_activation_vector_data),
                .stream_valid(core_stream_valid),
                .stream_tag(core_stream_tag),
                .weight_load_en(core_weight_load_en),
                .weight_addr(core_weight_addr),
                .weight_data(core_weight_data),
                .result_valid(core_result_valid),
                .result_tag(core_result_tag),
                .result_data(core_result_data)
            );
        end
        else begin : QUIRE_CORE
            systolic_stream_core_quire #(
                .N(N),
                .ES(ES),
                .ROWS(ROWS),
                .COLS(COLS),
                .QW(QW),
                .QF(QF),
                .TAG_W(PIXEL_ADDR_W),
                .ROW_ADDR_W(ROW_ADDR_W),
                .COL_ADDR_W(COL_ADDR_W),
                .WEIGHT_ADDR_W(WEIGHT_ADDR_W)
            ) STREAM_CORE (
                .clk(clk),
                .reset(reset),
                .pe_en(core_pe_en),
                .clear_pipe(core_clear_pipe),
                .wshift(core_wshift),
                .activation_in(core_activation_vector_data),
                .stream_valid(core_stream_valid),
                .stream_tag(core_stream_tag),
                .weight_load_en(core_weight_load_en),
                .weight_addr(core_weight_addr),
                .weight_data(core_weight_data),
                .result_valid(core_result_valid),
                .result_tag(core_result_tag),
                .result_quire_data(core_result_quire_data),
                .result_data(core_result_data),
                .result_is_nar(core_result_is_nar)
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_IDLE;
            current_layer <= 0;
            busy <= 1'b0;
            done <= 1'b0;
            class_out <= {CLASS_W{1'b0}};
            param_req_valid <= 1'b0;
            param_req_kind <= PARAM_WEIGHT;
            param_req_layer <= 4'd0;
            param_req_addr <= 32'd0;
            feature_rd_req_valid <= 1'b0;
            feature_rd_bank <= 1'b0;
            feature_rd_addr <= 32'd0;
            feature_wr_valid <= 1'b0;
            feature_wr_bank <= 1'b0;
            feature_wr_addr <= 32'd0;
            feature_wr_data <= POSIT_ZERO;

            cur_in_ch <= 0;
            cur_out_ch <= 0;
            cur_in_h <= 0;
            cur_in_w <= 0;
            cur_out_h <= 0;
            cur_out_w <= 0;
            cur_k <= 0;
            cur_padding <= 0;
            cur_dot_len <= 0;
            cur_out_pixels <= 0;
            cur_weight_base <= 0;
            cur_bias_base <= 0;
            cur_pool_out_h <= 0;
            cur_pool_out_w <= 0;
            cur_pool_after <= 1'b0;
            cur_final_layer <= 1'b0;

            oc_base <= 0;
            dot_base <= 0;
            init_col <= 0;
            init_pix <= 0;
            bias_index <= 0;
            load_index <= 0;
            stream_send_count <= 0;
            stream_recv_count <= 0;
            stream_x <= 0;
            stream_y <= 0;
            prep_row <= 0;

            post_idx <= 0;
            post_total <= 0;
            post_read_addr <= 0;
            post_ch <= 0;
            post_oy <= 0;
            post_ox <= 0;
            pool_pos <= 0;
            pool_window <= {4*N{1'b0}};

            argmax_idx <= 0;
            argmax_addr <= 0;
            argmax_best_value <= POSIT_ZERO;
            argmax_best_class <= {CLASS_W{1'b0}};

            core_pe_en <= 1'b0;
            core_clear_pipe <= 1'b0;
            core_wshift <= 1'b0;
            core_stream_valid <= 1'b0;
            core_stream_tag <= {PIXEL_ADDR_W{1'b0}};
            core_activation_vector_data <= {ROWS*N{1'b0}};
            core_weight_load_en <= 1'b0;
            core_weight_addr <= {WEIGHT_ADDR_W{1'b0}};
            core_weight_data <= POSIT_ZERO;
            quire_result_valid_d <= 1'b0;
            quire_result_tag_d <= {PIXEL_ADDR_W{1'b0}};
            quire_result_data_d <= {COLS*QW{1'b0}};
            quire_result_is_nar_d <= {COLS{1'b0}};
            for (i = 0; i < COLS; i = i + 1)
                bias_tile[i] <= POSIT_ZERO;
            for (i = 0; i < COLS; i = i + 1) begin
                quire_acc_old_reg[i] <= {QW{1'b0}};
                quire_acc_old_nar_reg[i] <= 1'b0;
            end
        end
        else begin
            done <= 1'b0;
            param_req_valid <= 1'b0;
            feature_rd_req_valid <= 1'b0;
            feature_wr_valid <= 1'b0;
            feature_wr_addr <= 32'd0;
            feature_wr_data <= POSIT_ZERO;
            core_pe_en <= 1'b0;
            core_clear_pipe <= 1'b0;
            core_wshift <= 1'b0;
            core_stream_valid <= 1'b0;
            core_stream_tag <= {PIXEL_ADDR_W{1'b0}};
            core_weight_load_en <= 1'b0;
            core_weight_data <= POSIT_ZERO;
            quire_result_valid_d <= 1'b0;

            if (!busy && cfg_write_en && cfg_mem == CFG_INPUT &&
                cfg_layer == 4'd0 && cfg_addr < IN_CH*IN_H*IN_W) begin
                feature_wr_valid <= 1'b1;
                feature_wr_bank <= 1'b0;
                feature_wr_addr <= cfg_addr;
                feature_wr_data <= cfg_data;
            end

            if ((USE_QUIRE != 0) && core_result_valid) begin
                quire_result_valid_d <= 1'b1;
                quire_result_tag_d <= core_result_tag;
                quire_result_data_d <= core_result_quire_data;
                quire_result_is_nar_d <= core_result_is_nar;
                for (i = 0; i < COLS; i = i + 1) begin
                    if ((oc_base + i) < cur_out_ch &&
                        core_result_tag < MAX_OUT_PIXELS) begin
                        quire_acc_old_reg[i] <= quire_tile_out[i][core_result_tag];
                        quire_acc_old_nar_reg[i] <= quire_tile_nar[i][core_result_tag];
                    end
                    else begin
                        quire_acc_old_reg[i] <= {QW{1'b0}};
                        quire_acc_old_nar_reg[i] <= 1'b0;
                    end
                end
            end

            if ((USE_QUIRE == 0) && core_result_valid) begin
                for (i = 0; i < COLS; i = i + 1) begin
                    if ((oc_base + i) < cur_out_ch) begin
                        out_index = (i * MAX_OUT_PIXELS) + core_result_tag;
                        if (out_index < COLS*MAX_OUT_PIXELS) begin
                            tile_out[out_index] <=
                                core_result_is_nar[i] ? POSIT_NAR : stream_acc_write[i];
                        end
                    end
                end
                stream_recv_count <= stream_recv_count + 1;
            end

            if ((USE_QUIRE != 0) && quire_result_valid_d) begin
                for (i = 0; i < COLS; i = i + 1) begin
                    if ((oc_base + i) < cur_out_ch) begin
                        out_index = (i * MAX_OUT_PIXELS) + quire_result_tag_d;
                        if (out_index < COLS*MAX_OUT_PIXELS) begin
                            quire_tile_out[i][quire_result_tag_d] <= quire_acc_sum[i];
                            quire_tile_nar[i][quire_result_tag_d] <= quire_acc_sum_nar[i];
                            tile_out[out_index] <= quire_acc_sum_nar[i] ?
                                POSIT_NAR : stream_acc_write[i];
                        end
                    end
                end
                stream_recv_count <= stream_recv_count + 1;
            end

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        current_layer <= 0;
                        state <= ST_SETUP_LAYER;
                    end
                end

                ST_SETUP_LAYER: begin
                    cur_in_ch <= layer_in_ch(current_layer);
                    cur_out_ch <= layer_out_ch(current_layer);
                    cur_in_h <= layer_in_h(current_layer);
                    cur_in_w <= layer_in_w(current_layer);
                    cur_k <= (current_layer >= 4'd10) ? 1 : 3;
                    cur_padding <= (current_layer >= 4'd10) ? 0 : 1;
                    cur_out_h <= layer_in_h(current_layer);
                    cur_out_w <= layer_in_w(current_layer);
                    cur_dot_len <= layer_in_ch(current_layer) *
                                   ((current_layer >= 4'd10) ? 1 : 9);
                    cur_out_pixels <= layer_in_h(current_layer) * layer_in_w(current_layer);
                    cur_weight_base <= layer_weight_base(current_layer);
                    cur_bias_base <= layer_bias_base(current_layer);
                    cur_pool_after <= layer_has_pool(current_layer);
                    cur_pool_out_h <= ((layer_in_h(current_layer) - 2) / 2) + 1;
                    cur_pool_out_w <= ((layer_in_w(current_layer) - 2) / 2) + 1;
                    cur_final_layer <= (current_layer == 4'd11);

                    oc_base <= 0;
                    dot_base <= 0;
                    bias_index <= 0;
                    init_col <= 0;
                    init_pix <= 0;
                    state <= ST_FETCH_BIAS;
                end

                ST_FETCH_BIAS: begin
                    if (bias_index < COLS) begin
                        if ((oc_base + bias_index) < cur_out_ch) begin
                            param_req_valid <= 1'b1;
                            param_req_kind <= PARAM_BIAS;
                            param_req_layer <= current_layer;
                            param_req_addr <= oc_base + bias_index;
                            state <= ST_FETCH_BIAS_WAIT;
                        end
                        else begin
                            bias_tile[bias_index] <= POSIT_ZERO;
                            bias_index <= bias_index + 1;
                        end
                    end
                    else begin
                        init_col <= 0;
                        init_pix <= 0;
                        state <= ST_INIT_TILE;
                    end
                end

                ST_FETCH_BIAS_WAIT: begin
                    if (param_resp_valid) begin
                        bias_tile[bias_index] <= param_resp_data;
                        bias_index <= bias_index + 1;
                        state <= ST_FETCH_BIAS;
                    end
                end

                ST_INIT_TILE: begin
                    if (init_col < COLS && (oc_base + init_col) < cur_out_ch) begin
                        out_index = (init_col * MAX_OUT_PIXELS) + init_pix;
                        if (out_index < COLS*MAX_OUT_PIXELS) begin
                            tile_out[out_index] <= bias_tile[init_col];
                            if (USE_QUIRE != 0) begin
                                quire_tile_out[init_col][init_pix] <= bias_quire[init_col];
                                quire_tile_nar[init_col][init_pix] <= bias_quire_nar[init_col];
                            end
                        end
                    end

                    if (init_col >= COLS-1 && init_pix >= cur_out_pixels-1) begin
                        load_index <= 0;
                        state <= ST_LOAD_TILE;
                    end
                    else if (init_pix >= cur_out_pixels-1) begin
                        init_pix <= 0;
                        init_col <= init_col + 1;
                    end
                    else begin
                        init_pix <= init_pix + 1;
                    end
                end

                ST_LOAD_TILE: begin
                    if (load_index < ROWS*COLS) begin
                        load_row = load_index / COLS;
                        load_col = load_index - (load_row * COLS);
                        dot_idx = dot_base + load_row;
                        out_ch_idx = oc_base + load_col;

                        core_weight_addr <= load_index[WEIGHT_ADDR_W-1:0];

                        if ((dot_idx < cur_dot_len) && (out_ch_idx < cur_out_ch)) begin
                            param_req_valid <= 1'b1;
                            param_req_kind <= PARAM_WEIGHT;
                            param_req_layer <= current_layer;
                            param_req_addr <= (out_ch_idx * cur_dot_len) + dot_idx;
                            state <= ST_LOAD_TILE_WAIT;
                        end
                        else begin
                            core_weight_load_en <= 1'b1;
                            core_weight_data <= POSIT_ZERO;
                            load_index <= load_index + 1;
                        end
                    end
                    else begin
                        core_clear_pipe <= 1'b1;
                        core_wshift <= 1'b1;
                        stream_send_count <= 0;
                        stream_recv_count <= 0;
                        stream_x <= 0;
                        stream_y <= 0;
                        prep_row <= 0;
                        state <= ST_PREP_ACT_READ;
                    end
                end

                ST_LOAD_TILE_WAIT: begin
                    if (param_resp_valid) begin
                        core_weight_load_en <= 1'b1;
                        core_weight_addr <= load_index[WEIGHT_ADDR_W-1:0];
                        core_weight_data <= param_resp_data;
                        load_index <= load_index + 1;
                        state <= ST_LOAD_TILE;
                    end
                end

                ST_PREP_ACT_READ: begin
                    if (stream_send_count < cur_out_pixels) begin
                        feature_rd_req_valid <= 1'b1;
                        feature_rd_bank <= current_layer[0];
                        feature_rd_addr <= activation_addr(dot_base + prep_row,
                                                           stream_y,
                                                           stream_x);
                        state <= ST_PREP_ACT_WAIT;
                    end
                    else begin
                        state <= ST_STREAM_TILE;
                    end
                end

                ST_PREP_ACT_WAIT: begin
                    if (feature_rd_resp_valid) begin
                        core_activation_vector_data[prep_row*N +: N] <= feature_rd_resp_data;
                        if (prep_row < ROWS-1) begin
                            prep_row <= prep_row + 1;
                            state <= ST_PREP_ACT_READ;
                        end
                        else begin
                            prep_row <= 0;
                            state <= ST_STREAM_TILE;
                        end
                    end
                end

                ST_PREP_ACT_CAPTURE: begin
                    core_activation_vector_data[prep_row*N +: N] <= feature_rd_resp_data;
                    if (prep_row < ROWS-1) begin
                        prep_row <= prep_row + 1;
                        state <= ST_PREP_ACT_READ;
                    end
                    else begin
                        prep_row <= 0;
                        state <= ST_STREAM_TILE;
                    end
                end

                ST_STREAM_TILE: begin
                    if (stream_send_count < cur_out_pixels) begin
                        core_stream_valid <= 1'b1;
                        core_stream_tag <= stream_send_count[PIXEL_ADDR_W-1:0];
                        core_pe_en <= 1'b1;
                        stream_send_count <= stream_send_count + 1;

                        if (stream_x >= cur_out_w-1) begin
                            stream_x <= 0;
                            stream_y <= stream_y + 1;
                        end
                        else begin
                            stream_x <= stream_x + 1;
                        end

                        if (stream_send_count + 1 < cur_out_pixels)
                            state <= ST_PREP_ACT_READ;
                    end
                    else if (!(stream_result_accept_valid && (stream_recv_count == cur_out_pixels-1))) begin
                        core_pe_en <= 1'b1;
                    end

                    if (stream_result_accept_valid && (stream_recv_count == cur_out_pixels-1))
                        state <= ST_NEXT_DOT;
                end

                ST_NEXT_DOT: begin
                    if ((dot_base + ROWS) < cur_dot_len) begin
                        dot_base <= dot_base + ROWS;
                        load_index <= 0;
                        state <= ST_LOAD_TILE;
                    end
                    else begin
                        state <= ST_NEXT_OC;
                    end
                end

                ST_NEXT_OC: begin
                    if (cur_final_layer) begin
                        post_idx <= 0;
                        state <= ST_STORE_LOGITS;
                    end
                    else if (cur_pool_after) begin
                        post_idx <= 0;
                        post_total <= COLS * cur_pool_out_h * cur_pool_out_w;
                        post_ch <= 0;
                        post_oy <= 0;
                        post_ox <= 0;
                        pool_pos <= 0;
                        pool_window <= {4*N{1'b0}};
                        state <= ST_POST_POOL_SET;
                    end
                    else begin
                        post_idx <= 0;
                        post_total <= COLS * cur_out_pixels;
                        state <= ST_POST_DIRECT_SET;
                    end
                end

                ST_STORE_LOGITS: begin
                    if (post_idx < COLS) begin
                        if ((oc_base + post_idx) < NUM_CLASSES)
                            logit_mem[oc_base + post_idx] <=
                                tile_out[(post_idx * MAX_OUT_PIXELS)];
                        post_idx <= post_idx + 1;
                    end
                    else if ((oc_base + COLS) < cur_out_ch) begin
                        oc_base <= oc_base + COLS;
                        dot_base <= 0;
                        bias_index <= 0;
                        init_col <= 0;
                        init_pix <= 0;
                        state <= ST_FETCH_BIAS;
                    end
                    else begin
                        argmax_idx <= 0;
                        argmax_addr <= 0;
                        argmax_best_value <= POSIT_ZERO;
                        argmax_best_class <= {CLASS_W{1'b0}};
                        state <= ST_ARGMAX_SET;
                    end
                end

                ST_POST_DIRECT_SET: begin
                    local_col = post_idx / cur_out_pixels;
                    if ((post_idx < post_total) &&
                        (local_col < COLS) &&
                        ((oc_base + local_col) < cur_out_ch)) begin
                        local_pix = post_idx - (local_col * cur_out_pixels);
                        post_read_addr <= (local_col * MAX_OUT_PIXELS) + local_pix;
                        state <= ST_POST_DIRECT_WAIT;
                    end
                    else if ((post_idx < post_total) &&
                             (local_col < COLS) &&
                             ((oc_base + local_col) >= cur_out_ch)) begin
                        post_idx <= (local_col + 1) * cur_out_pixels;
                    end
                    else if ((oc_base + COLS) < cur_out_ch) begin
                        oc_base <= oc_base + COLS;
                        dot_base <= 0;
                        bias_index <= 0;
                        init_col <= 0;
                        init_pix <= 0;
                        state <= ST_FETCH_BIAS;
                    end
                    else begin
                        current_layer <= current_layer + 1;
                        state <= ST_SETUP_LAYER;
                    end
                end

                ST_POST_DIRECT_WAIT: begin
                    state <= ST_POST_DIRECT_WRITE;
                end

                ST_POST_DIRECT_WRITE: begin
                    local_col = post_idx / cur_out_pixels;
                    local_pix = post_idx - (local_col * cur_out_pixels);
                    dest_index = ((oc_base + local_col) * cur_out_pixels) + local_pix;
                    if (dest_index < MAX_FEATURE_VALUES) begin
                        feature_wr_valid <= 1'b1;
                        feature_wr_bank <= ~current_layer[0];
                        feature_wr_addr <= dest_index;
                        feature_wr_data <= relu_single_out;
                    end
                    post_idx <= post_idx + 1;
                    state <= ST_POST_DIRECT_SET;
                end

                ST_POST_POOL_SET: begin
                    pool_out_pixels = cur_pool_out_h * cur_pool_out_w;
                    if ((post_idx < post_total) &&
                        (post_ch < COLS) &&
                        ((oc_base + post_ch) < cur_out_ch)) begin
                        ky = pool_pos / 2;
                        kx = pool_pos - (ky * 2);
                        post_read_addr <= (post_ch * MAX_OUT_PIXELS) +
                                          (((post_oy * 2) + ky) * cur_out_w) +
                                          ((post_ox * 2) + kx);
                        state <= ST_POST_POOL_WAIT;
                    end
                    else if ((post_idx < post_total) &&
                             (post_ch < COLS) &&
                             ((oc_base + post_ch) >= cur_out_ch)) begin
                        post_idx <= (post_ch + 1) * pool_out_pixels;
                        post_ch <= post_ch + 1;
                        post_oy <= 0;
                        post_ox <= 0;
                        pool_pos <= 0;
                        pool_window <= {4*N{1'b0}};
                    end
                    else if ((oc_base + COLS) < cur_out_ch) begin
                        oc_base <= oc_base + COLS;
                        dot_base <= 0;
                        bias_index <= 0;
                        init_col <= 0;
                        init_pix <= 0;
                        state <= ST_FETCH_BIAS;
                    end
                    else begin
                        current_layer <= current_layer + 1;
                        state <= ST_SETUP_LAYER;
                    end
                end

                ST_POST_POOL_WAIT: begin
                    state <= ST_POST_POOL_CAPTURE;
                end

                ST_POST_POOL_CAPTURE: begin
                    if (pool_pos == 2'd3) begin
                        dest_index = ((oc_base + post_ch) * cur_pool_out_h * cur_pool_out_w) +
                                     (post_oy * cur_pool_out_w) + post_ox;
                        if (dest_index < MAX_FEATURE_VALUES) begin
                            feature_wr_valid <= 1'b1;
                            feature_wr_bank <= ~current_layer[0];
                            feature_wr_addr <= dest_index;
                            feature_wr_data <= pool_single_out;
                        end

                        post_idx <= post_idx + 1;
                        pool_pos <= 0;
                        pool_window <= {4*N{1'b0}};

                        if (post_ox + 1 < cur_pool_out_w) begin
                            post_ox <= post_ox + 1;
                        end
                        else begin
                            post_ox <= 0;
                            if (post_oy + 1 < cur_pool_out_h) begin
                                post_oy <= post_oy + 1;
                            end
                            else begin
                                post_oy <= 0;
                                post_ch <= post_ch + 1;
                            end
                        end
                    end
                    else begin
                        pool_window <= pool_window_candidate;
                        pool_pos <= pool_pos + 1;
                    end
                    state <= ST_POST_POOL_SET;
                end

                ST_ARGMAX_SET: begin
                    if (argmax_idx < NUM_CLASSES) begin
                        argmax_addr <= argmax_idx;
                        state <= ST_ARGMAX_WAIT;
                    end
                    else begin
                        class_out <= argmax_best_class;
                        state <= ST_DONE;
                    end
                end

                ST_ARGMAX_WAIT: begin
                    state <= ST_ARGMAX_CAPTURE;
                end

                ST_ARGMAX_CAPTURE: begin
                    if (argmax_idx == 0 || is_better_logit(selected_logit_data, argmax_best_value)) begin
                        argmax_best_value <= selected_logit_data;
                        argmax_best_class <= argmax_idx[CLASS_W-1:0];
                    end
                    argmax_idx <= argmax_idx + 1;
                    state <= ST_ARGMAX_SET;
                end

                ST_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
