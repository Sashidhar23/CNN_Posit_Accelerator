`timescale 1ns / 1ps

// ZCU102 deployment wrapper.
//
// S_AXI is the PS control path. M_AXI is a read-only data path to PS DDR.
// Parameters remain in DDR; feature maps use the two on-chip BRAM banks below.
module cnn_zynq_axi_master_wrapper #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7,
    parameter integer C_M_AXI_DATA_WIDTH = 64,
    parameter integer C_M_AXI_ADDR_WIDTH = 40,
    parameter integer C_M_AXI_ID_WIDTH = 1,
    parameter N = 8,
    parameter ES = 1,
    parameter USE_QUIRE = 1,
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
    parameter ROWS = 4,
    parameter COLS = 4,
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
    input  wire                              aclk,
    input  wire                              aresetn,

    // AXI4-Lite slave: connect to a Zynq MPSoC PS master through SmartConnect.
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [2:0]                        s_axi_awprot,
    input  wire                              s_axi_awvalid,
    output wire                              s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                              s_axi_wvalid,
    output wire                              s_axi_wready,
    output reg  [1:0]                        s_axi_bresp,
    output reg                               s_axi_bvalid,
    input  wire                              s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [2:0]                        s_axi_arprot,
    input  wire                              s_axi_arvalid,
    output wire                              s_axi_arready,
    output reg  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                        s_axi_rresp,
    output reg                               s_axi_rvalid,
    input  wire                              s_axi_rready,

    // AXI4 master: connect to an HP/HPC DDR path through SmartConnect.
    output wire [C_M_AXI_ID_WIDTH-1:0]       m_axi_awid,
    output wire [C_M_AXI_ADDR_WIDTH-1:0]     m_axi_awaddr,
    output wire [7:0]                        m_axi_awlen,
    output wire [2:0]                        m_axi_awsize,
    output wire [1:0]                        m_axi_awburst,
    output wire                              m_axi_awlock,
    output wire [3:0]                        m_axi_awcache,
    output wire [2:0]                        m_axi_awprot,
    output wire [3:0]                        m_axi_awqos,
    output wire [3:0]                        m_axi_awregion,
    output wire                              m_axi_awvalid,
    input  wire                              m_axi_awready,
    output wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_wdata,
    output wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output wire                              m_axi_wlast,
    output wire                              m_axi_wvalid,
    input  wire                              m_axi_wready,
    input  wire [C_M_AXI_ID_WIDTH-1:0]       m_axi_bid,
    input  wire [1:0]                        m_axi_bresp,
    input  wire                              m_axi_bvalid,
    output wire                              m_axi_bready,

    output wire [C_M_AXI_ID_WIDTH-1:0]       m_axi_arid,
    output reg  [C_M_AXI_ADDR_WIDTH-1:0]     m_axi_araddr,
    output wire [7:0]                        m_axi_arlen,
    output wire [2:0]                        m_axi_arsize,
    output wire [1:0]                        m_axi_arburst,
    output wire                              m_axi_arlock,
    output wire [3:0]                        m_axi_arcache,
    output wire [2:0]                        m_axi_arprot,
    output wire [3:0]                        m_axi_arqos,
    output wire [3:0]                        m_axi_arregion,
    output reg                               m_axi_arvalid,
    input  wire                              m_axi_arready,
    input  wire [C_M_AXI_ID_WIDTH-1:0]       m_axi_rid,
    input  wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                        m_axi_rresp,
    input  wire                              m_axi_rlast,
    input  wire                              m_axi_rvalid,
    output reg                               m_axi_rready,

    output wire                              irq
);

    function integer imax;
        input integer a;
        input integer b;
        begin
            imax = (a > b) ? a : b;
        end
    endfunction

    localparam integer ADDR_LSB = 2;
    localparam integer VALUES_PER_WORD = C_M_AXI_DATA_WIDTH / N;
    localparam integer WORD_BYTES = C_M_AXI_DATA_WIDTH / 8;
    localparam integer IMAGE_SIZE = IN_CH * IN_H * IN_W;
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

    localparam [1:0] CFG_INPUT = 2'd0;
    localparam [1:0] PARAM_WEIGHT = 2'd0;
    localparam [1:0] PARAM_BIAS = 2'd1;

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

    localparam [3:0] REG_CONTROL     = 4'h0; // bit0 start, bit1 clear done/error
    localparam [3:0] REG_STATUS      = 4'h1; // busy, done, error, core busy
    localparam [3:0] REG_WEIGHT_BASE = 4'h2;
    localparam [3:0] REG_BIAS_BASE   = 4'h3;
    localparam [3:0] REG_IMAGE_BASE  = 4'h4;
    localparam [3:0] REG_TIMEOUT     = 4'h5;
    localparam [3:0] REG_CLASS       = 4'h6;
    localparam [3:0] REG_LOGIT_ADDR  = 4'h7;
    localparam [3:0] REG_LOGIT_DATA  = 4'h8;
    localparam [3:0] REG_DEBUG_STATE = 4'h9;
    localparam [3:0] REG_DEBUG_INDEX = 4'hA;

    localparam [3:0] ST_IDLE          = 4'd0;
    localparam [3:0] ST_IMAGE_REQ     = 4'd1;
    localparam [3:0] ST_IMAGE_AR      = 4'd2;
    localparam [3:0] ST_IMAGE_R       = 4'd3;
    localparam [3:0] ST_IMAGE_WRITE   = 4'd4;
    localparam [3:0] ST_START_DUT     = 4'd5;
    localparam [3:0] ST_WAIT_DUT      = 4'd6;
    localparam [3:0] ST_PARAM_AR      = 4'd7;
    localparam [3:0] ST_PARAM_R       = 4'd8;
    localparam [3:0] ST_DONE          = 4'd9;
    localparam [3:0] ST_ERROR         = 4'd10;

    // Full AXI4 write channel is intentionally inactive: this accelerator only
    // reads model/image data from DDR and writes intermediate maps to BRAM.
    assign m_axi_awid = {C_M_AXI_ID_WIDTH{1'b0}};
    assign m_axi_awaddr = {C_M_AXI_ADDR_WIDTH{1'b0}};
    assign m_axi_awlen = 8'd0;
    assign m_axi_awsize = (C_M_AXI_DATA_WIDTH == 128) ? 3'd4 :
                          (C_M_AXI_DATA_WIDTH == 64)  ? 3'd3 :
                          (C_M_AXI_DATA_WIDTH == 32)  ? 3'd2 : 3'd0;
    assign m_axi_awburst = 2'b01;
    assign m_axi_awlock = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awprot = 3'b000;
    assign m_axi_awqos = 4'd0;
    assign m_axi_awregion = 4'd0;
    assign m_axi_awvalid = 1'b0;
    assign m_axi_wdata = {C_M_AXI_DATA_WIDTH{1'b0}};
    assign m_axi_wstrb = {(C_M_AXI_DATA_WIDTH/8){1'b0}};
    assign m_axi_wlast = 1'b1;
    assign m_axi_wvalid = 1'b0;
    assign m_axi_bready = 1'b1;

    assign m_axi_arid = {C_M_AXI_ID_WIDTH{1'b0}};
    assign m_axi_arlen = 8'd0;
    assign m_axi_arsize = (C_M_AXI_DATA_WIDTH == 128) ? 3'd4 :
                          (C_M_AXI_DATA_WIDTH == 64)  ? 3'd3 :
                          (C_M_AXI_DATA_WIDTH == 32)  ? 3'd2 : 3'd0;
    assign m_axi_arburst = 2'b01;
    assign m_axi_arlock = 1'b0;
    assign m_axi_arcache = 4'b0011;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arqos = 4'd0;
    assign m_axi_arregion = 4'd0;

    reg aw_hold;
    reg w_hold;
    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_hold;
    reg [C_S_AXI_DATA_WIDTH-1:0] wdata_hold;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_hold;
    reg control_start_pulse;
    reg control_clear_pulse;

    reg [31:0] weight_base_addr;
    reg [31:0] bias_base_addr;
    reg [31:0] image_base_addr;
    reg [31:0] timeout_limit;
    reg [31:0] dut_logit_addr;

    reg [3:0] state;
    reg [31:0] image_index;
    reg [31:0] timeout_count;
    reg done_latched;
    reg error_latched;

    reg dut_start;
    reg dut_cfg_write_en;
    reg [3:0] dut_cfg_layer;
    reg [1:0] dut_cfg_mem;
    reg [31:0] dut_cfg_addr;
    reg [N-1:0] dut_cfg_data;

    reg core_param_resp_valid;
    reg [N-1:0] core_param_resp_data;
    reg [31:0] pending_value_index;

    wire core_param_req_valid;
    wire [1:0] core_param_req_kind;
    wire [3:0] core_param_req_layer;
    wire [31:0] core_param_req_addr;
    wire core_feature_rd_req_valid;
    wire core_feature_rd_bank;
    wire [31:0] core_feature_rd_addr;
    reg core_feature_rd_resp_valid;
    reg [N-1:0] core_feature_rd_resp_data;
    wire core_feature_wr_valid;
    wire core_feature_wr_bank;
    wire [31:0] core_feature_wr_addr;
    wire [N-1:0] core_feature_wr_data;
    wire [N-1:0] dut_logit_data;
    wire dut_busy;
    wire dut_done;
    wire [CLASS_W-1:0] dut_class_out;

    // These match the two feature-bank arrays modelled in the inference TB.
    (* ram_style = "block" *) reg [N-1:0] feature_bank0 [0:MAX_FEATURE_VALUES-1];
    (* ram_style = "block" *) reg [N-1:0] feature_bank1 [0:MAX_FEATURE_VALUES-1];

    wire reset = ~aresetn;
    // AXI4-Lite registers are 32-bit word addressed at byte bits [5:2].
    // Fixed indices keep Vivado IP-integrator OOC synthesis parameter-safe.
    wire [3:0] aw_word_addr = awaddr_hold[5:2];
    wire [3:0] ar_word_addr = s_axi_araddr[5:2];
    wire write_commit = aw_hold && w_hold && !s_axi_bvalid;

    assign s_axi_awready = !aw_hold && !s_axi_bvalid;
    assign s_axi_wready = !w_hold && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;
    assign irq = done_latched | error_latched;

    function [31:0] layer_weight_base;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_weight_base = 0;
                4'd1: layer_weight_base = L0_W_SIZE;
                4'd2: layer_weight_base = L0_W_SIZE + L1_W_SIZE;
                4'd3: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE;
                4'd4: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE;
                4'd5: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE + L4_W_SIZE;
                4'd6: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE + L4_W_SIZE + L5_W_SIZE;
                4'd7: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE + L4_W_SIZE + L5_W_SIZE + L6_W_SIZE;
                4'd8: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE + L4_W_SIZE + L5_W_SIZE + L6_W_SIZE + L7_W_SIZE;
                4'd9: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE + L4_W_SIZE + L5_W_SIZE + L6_W_SIZE + L7_W_SIZE + L8_W_SIZE;
                4'd10: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE + L4_W_SIZE + L5_W_SIZE + L6_W_SIZE + L7_W_SIZE + L8_W_SIZE + L9_W_SIZE;
                4'd11: layer_weight_base = L0_W_SIZE + L1_W_SIZE + L2_W_SIZE + L3_W_SIZE + L4_W_SIZE + L5_W_SIZE + L6_W_SIZE + L7_W_SIZE + L8_W_SIZE + L9_W_SIZE + L10_W_SIZE;
                default: layer_weight_base = 0;
            endcase
        end
    endfunction

    function [31:0] layer_bias_base;
        input [3:0] layer;
        begin
            case (layer)
                4'd0: layer_bias_base = 0;
                4'd1: layer_bias_base = L0_B_SIZE;
                4'd2: layer_bias_base = L0_B_SIZE + L1_B_SIZE;
                4'd3: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE;
                4'd4: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE;
                4'd5: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE + L4_B_SIZE;
                4'd6: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE + L4_B_SIZE + L5_B_SIZE;
                4'd7: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE + L4_B_SIZE + L5_B_SIZE + L6_B_SIZE;
                4'd8: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE + L4_B_SIZE + L5_B_SIZE + L6_B_SIZE + L7_B_SIZE;
                4'd9: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE + L4_B_SIZE + L5_B_SIZE + L6_B_SIZE + L7_B_SIZE + L8_B_SIZE;
                4'd10: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE + L4_B_SIZE + L5_B_SIZE + L6_B_SIZE + L7_B_SIZE + L8_B_SIZE + L9_B_SIZE;
                4'd11: layer_bias_base = L0_B_SIZE + L1_B_SIZE + L2_B_SIZE + L3_B_SIZE + L4_B_SIZE + L5_B_SIZE + L6_B_SIZE + L7_B_SIZE + L8_B_SIZE + L9_B_SIZE + L10_B_SIZE;
                default: layer_bias_base = 0;
            endcase
        end
    endfunction

    function [N-1:0] packed_value_at;
        input [C_M_AXI_DATA_WIDTH-1:0] word;
        input [31:0] value_index;
        integer bit_base;
        begin
            bit_base = (value_index % VALUES_PER_WORD) * N;
            packed_value_at = word[bit_base +: N];
        end
    endfunction

    function [31:0] merge_wstrb;
        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0] strobe;
        integer byte_index;
        begin
            merge_wstrb = old_value;
            for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                if (strobe[byte_index])
                    merge_wstrb[byte_index*8 +: 8] = new_value[byte_index*8 +: 8];
        end
    endfunction

    generate
        if (USE_QUIRE == 0) begin : REGULAR_DUT
            reduced_vgg16_mnist #(
                .N(N), .ES(ES), .IN_CH(IN_CH), .IN_H(IN_H), .IN_W(IN_W),
                .C1(C1), .C2(C2), .C3(C3), .C4(C4), .FC1(FC1),
                .NUM_CLASSES(NUM_CLASSES), .ROWS(ROWS), .COLS(COLS),
                .CLASS_W(CLASS_W), .H1(H1), .W1(W1), .H2(H2), .W2(W2),
                .H3(H3), .W3(W3), .H4(H4), .W4(W4), .H5(H5), .W5(W5)
            ) DUT (
                .clk(aclk), .reset(reset), .start(dut_start),
                .cfg_write_en(dut_cfg_write_en), .cfg_layer(dut_cfg_layer),
                .cfg_mem(dut_cfg_mem), .cfg_addr(dut_cfg_addr), .cfg_data(dut_cfg_data),
                .param_req_valid(core_param_req_valid), .param_req_kind(core_param_req_kind),
                .param_req_layer(core_param_req_layer), .param_req_addr(core_param_req_addr),
                .param_resp_valid(core_param_resp_valid), .param_resp_data(core_param_resp_data),
                .feature_rd_req_valid(core_feature_rd_req_valid), .feature_rd_bank(core_feature_rd_bank),
                .feature_rd_addr(core_feature_rd_addr), .feature_rd_resp_valid(core_feature_rd_resp_valid),
                .feature_rd_resp_data(core_feature_rd_resp_data), .feature_wr_valid(core_feature_wr_valid),
                .feature_wr_bank(core_feature_wr_bank), .feature_wr_addr(core_feature_wr_addr),
                .feature_wr_data(core_feature_wr_data), .logit_read_addr(dut_logit_addr),
                .logit_read_data(dut_logit_data), .busy(dut_busy), .done(dut_done),
                .class_out(dut_class_out)
            );
        end
        else begin : QUIRE_DUT
            reduced_vgg16_mnist_quire #(
                .N(N), .ES(ES), .QW(QW), .QF(QF), .IN_CH(IN_CH), .IN_H(IN_H), .IN_W(IN_W),
                .C1(C1), .C2(C2), .C3(C3), .C4(C4), .FC1(FC1),
                .NUM_CLASSES(NUM_CLASSES), .ROWS(ROWS), .COLS(COLS),
                .CLASS_W(CLASS_W), .H1(H1), .W1(W1), .H2(H2), .W2(W2),
                .H3(H3), .W3(W3), .H4(H4), .W4(W4), .H5(H5), .W5(W5)
            ) DUT (
                .clk(aclk), .reset(reset), .start(dut_start),
                .cfg_write_en(dut_cfg_write_en), .cfg_layer(dut_cfg_layer),
                .cfg_mem(dut_cfg_mem), .cfg_addr(dut_cfg_addr), .cfg_data(dut_cfg_data),
                .param_req_valid(core_param_req_valid), .param_req_kind(core_param_req_kind),
                .param_req_layer(core_param_req_layer), .param_req_addr(core_param_req_addr),
                .param_resp_valid(core_param_resp_valid), .param_resp_data(core_param_resp_data),
                .feature_rd_req_valid(core_feature_rd_req_valid), .feature_rd_bank(core_feature_rd_bank),
                .feature_rd_addr(core_feature_rd_addr), .feature_rd_resp_valid(core_feature_rd_resp_valid),
                .feature_rd_resp_data(core_feature_rd_resp_data), .feature_wr_valid(core_feature_wr_valid),
                .feature_wr_bank(core_feature_wr_bank), .feature_wr_addr(core_feature_wr_addr),
                .feature_wr_data(core_feature_wr_data), .logit_read_addr(dut_logit_addr),
                .logit_read_data(dut_logit_data), .busy(dut_busy), .done(dut_done),
                .class_out(dut_class_out)
            );
        end
    endgenerate

    // AXI-Lite channels are deliberately independent, as required by AXI-Lite.
    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_hold <= 1'b0;
            w_hold <= 1'b0;
            awaddr_hold <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            wdata_hold <= {C_S_AXI_DATA_WIDTH{1'b0}};
            wstrb_hold <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
            weight_base_addr <= 32'd0;
            bias_base_addr <= 32'd0;
            image_base_addr <= 32'd0;
            timeout_limit <= 32'd0;
            dut_logit_addr <= 32'd0;
            control_start_pulse <= 1'b0;
            control_clear_pulse <= 1'b0;
        end
        else begin
            control_start_pulse <= 1'b0;
            control_clear_pulse <= 1'b0;

            if (s_axi_awvalid && s_axi_awready) begin
                aw_hold <= 1'b1;
                awaddr_hold <= s_axi_awaddr;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_hold <= 1'b1;
                wdata_hold <= s_axi_wdata;
                wstrb_hold <= s_axi_wstrb;
            end
            if (write_commit) begin
                case (aw_word_addr)
                    REG_CONTROL: begin
                        if (wdata_hold[0] && wstrb_hold[0]) control_start_pulse <= 1'b1;
                        if (wdata_hold[1] && wstrb_hold[0]) control_clear_pulse <= 1'b1;
                    end
                    REG_WEIGHT_BASE: weight_base_addr <= merge_wstrb(weight_base_addr, wdata_hold[31:0], wstrb_hold[3:0]);
                    REG_BIAS_BASE:   bias_base_addr <= merge_wstrb(bias_base_addr, wdata_hold[31:0], wstrb_hold[3:0]);
                    REG_IMAGE_BASE:  image_base_addr <= merge_wstrb(image_base_addr, wdata_hold[31:0], wstrb_hold[3:0]);
                    REG_TIMEOUT:     timeout_limit <= merge_wstrb(timeout_limit, wdata_hold[31:0], wstrb_hold[3:0]);
                    REG_LOGIT_ADDR:  dut_logit_addr <= merge_wstrb(dut_logit_addr, wdata_hold[31:0], wstrb_hold[3:0]);
                    default: begin end
                endcase
                aw_hold <= 1'b0;
                w_hold <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
                case (ar_word_addr)
                    REG_STATUS: begin
                        s_axi_rdata[0] <= (state != ST_IDLE);
                        s_axi_rdata[1] <= done_latched;
                        s_axi_rdata[2] <= error_latched;
                        s_axi_rdata[3] <= dut_busy;
                    end
                    REG_WEIGHT_BASE: s_axi_rdata[31:0] <= weight_base_addr;
                    REG_BIAS_BASE:   s_axi_rdata[31:0] <= bias_base_addr;
                    REG_IMAGE_BASE:  s_axi_rdata[31:0] <= image_base_addr;
                    REG_TIMEOUT:     s_axi_rdata[31:0] <= timeout_limit;
                    // Whole-vector assignment safely zero-extends/truncates for
                    // AXI-Lite and avoids a module-reference parameter part-select.
                    REG_CLASS:       s_axi_rdata <= dut_class_out;
                    REG_LOGIT_ADDR:  s_axi_rdata[31:0] <= dut_logit_addr;
                    REG_LOGIT_DATA:  s_axi_rdata[N-1:0] <= dut_logit_data;
                    REG_DEBUG_STATE: s_axi_rdata[3:0] <= state;
                    REG_DEBUG_INDEX: s_axi_rdata[31:0] <= image_index;
                    default: begin end
                endcase
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // A synchronous, one-cycle feature-memory response matches the tiled core
    // contract used by the existing self-checking inference testbench.
    always @(posedge aclk) begin
        if (reset) begin
            core_feature_rd_resp_valid <= 1'b0;
            core_feature_rd_resp_data <= {N{1'b0}};
        end
        else begin
            core_feature_rd_resp_valid <= core_feature_rd_req_valid;
            if (core_feature_rd_req_valid && core_feature_rd_addr < MAX_FEATURE_VALUES) begin
                if (core_feature_rd_bank)
                    core_feature_rd_resp_data <= feature_bank1[core_feature_rd_addr];
                else
                    core_feature_rd_resp_data <= feature_bank0[core_feature_rd_addr];
            end
            else begin
                core_feature_rd_resp_data <= {N{1'b0}};
            end

            if (core_feature_wr_valid && core_feature_wr_addr < MAX_FEATURE_VALUES) begin
                if (core_feature_wr_bank)
                    feature_bank1[core_feature_wr_addr] <= core_feature_wr_data;
                else
                    feature_bank0[core_feature_wr_addr] <= core_feature_wr_data;
            end
        end
    end

    // One outstanding AXI read is sufficient because the tiled core requests a
    // parameter then explicitly waits for its response. DDR stores packed N-bit
    // values little-endian within each AXI word.
    always @(posedge aclk) begin
        if (reset) begin
            state <= ST_IDLE;
            image_index <= 32'd0;
            timeout_count <= 32'd0;
            done_latched <= 1'b0;
            error_latched <= 1'b0;
            dut_start <= 1'b0;
            dut_cfg_write_en <= 1'b0;
            dut_cfg_layer <= 4'd0;
            dut_cfg_mem <= CFG_INPUT;
            dut_cfg_addr <= 32'd0;
            dut_cfg_data <= {N{1'b0}};
            core_param_resp_valid <= 1'b0;
            core_param_resp_data <= {N{1'b0}};
            pending_value_index <= 32'd0;
            m_axi_araddr <= {C_M_AXI_ADDR_WIDTH{1'b0}};
            m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
        end
        else begin
            dut_start <= 1'b0;
            dut_cfg_write_en <= 1'b0;
            core_param_resp_valid <= 1'b0;

            if (control_clear_pulse) begin
                done_latched <= 1'b0;
                error_latched <= 1'b0;
            end

            case (state)
                ST_IDLE: begin
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready <= 1'b0;
                    if (control_start_pulse) begin
                        done_latched <= 1'b0;
                        error_latched <= 1'b0;
                        image_index <= 32'd0;
                        state <= ST_IMAGE_REQ;
                    end
                end

                ST_IMAGE_REQ: begin
                    m_axi_araddr <= image_base_addr + ((image_index / VALUES_PER_WORD) * WORD_BYTES);
                    m_axi_arvalid <= 1'b1;
                    state <= ST_IMAGE_AR;
                end

                ST_IMAGE_AR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready <= 1'b1;
                        state <= ST_IMAGE_R;
                    end
                end

                ST_IMAGE_R: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready <= 1'b0;
                        if (m_axi_rresp != 2'b00 || !m_axi_rlast) begin
                            error_latched <= 1'b1;
                            state <= ST_ERROR;
                        end
                        else begin
                            dut_cfg_layer <= 4'd0;
                            dut_cfg_mem <= CFG_INPUT;
                            dut_cfg_addr <= image_index;
                            dut_cfg_data <= packed_value_at(m_axi_rdata, image_index);
                            dut_cfg_write_en <= 1'b1;
                            state <= ST_IMAGE_WRITE;
                        end
                    end
                end

                ST_IMAGE_WRITE: begin
                    if (image_index + 1 >= IMAGE_SIZE)
                        state <= ST_START_DUT;
                    else begin
                        image_index <= image_index + 1;
                        state <= ST_IMAGE_REQ;
                    end
                end

                ST_START_DUT: begin
                    timeout_count <= 32'd0;
                    dut_start <= 1'b1;
                    state <= ST_WAIT_DUT;
                end

                ST_WAIT_DUT: begin
                    if (dut_done) begin
                        done_latched <= 1'b1;
                        state <= ST_DONE;
                    end
                    else if (timeout_limit != 0 && timeout_count >= timeout_limit) begin
                        error_latched <= 1'b1;
                        state <= ST_ERROR;
                    end
                    else if (core_param_req_valid) begin
                        if (core_param_req_kind == PARAM_WEIGHT)
                            pending_value_index <= layer_weight_base(core_param_req_layer) + core_param_req_addr;
                        else
                            pending_value_index <= layer_bias_base(core_param_req_layer) + core_param_req_addr;

                        if (core_param_req_kind == PARAM_WEIGHT)
                            m_axi_araddr <= weight_base_addr +
                                (((layer_weight_base(core_param_req_layer) + core_param_req_addr) / VALUES_PER_WORD) * WORD_BYTES);
                        else
                            m_axi_araddr <= bias_base_addr +
                                (((layer_bias_base(core_param_req_layer) + core_param_req_addr) / VALUES_PER_WORD) * WORD_BYTES);
                        m_axi_arvalid <= 1'b1;
                        state <= ST_PARAM_AR;
                    end
                    else begin
                        timeout_count <= timeout_count + 1;
                    end
                end

                ST_PARAM_AR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready <= 1'b1;
                        state <= ST_PARAM_R;
                    end
                end

                ST_PARAM_R: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        m_axi_rready <= 1'b0;
                        if (m_axi_rresp != 2'b00 || !m_axi_rlast) begin
                            error_latched <= 1'b1;
                            state <= ST_ERROR;
                        end
                        else begin
                            core_param_resp_data <= packed_value_at(m_axi_rdata, pending_value_index);
                            core_param_resp_valid <= 1'b1;
                            state <= ST_WAIT_DUT;
                        end
                    end
                end

                ST_DONE: state <= ST_IDLE;

                ST_ERROR: begin
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready <= 1'b0;
                    error_latched <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    error_latched <= 1'b1;
                    state <= ST_ERROR;
                end
            endcase
        end
    end

endmodule
