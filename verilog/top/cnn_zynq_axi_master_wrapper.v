`timescale 1ns / 1ps

module cnn_zynq_axi_master_wrapper #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 7,
    parameter integer C_M_AXI_DATA_WIDTH = 32,
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
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
    parameter CLASS_W = (NUM_CLASSES <= 2) ? 1 : $clog2(NUM_CLASSES)
)(
    input  wire                              aclk,
    input  wire                              aresetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [2:0]                        s_axi_awprot,
    input  wire                              s_axi_awvalid,
    output reg                               s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                              s_axi_wvalid,
    output reg                               s_axi_wready,
    output reg [1:0]                         s_axi_bresp,
    output reg                               s_axi_bvalid,
    input  wire                              s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [2:0]                        s_axi_arprot,
    input  wire                              s_axi_arvalid,
    output reg                               s_axi_arready,
    output reg [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
    output reg [1:0]                         s_axi_rresp,
    output reg                               s_axi_rvalid,
    input  wire                              s_axi_rready,

    output reg [C_M_AXI_ADDR_WIDTH-1:0]      m_axi_araddr,
    output wire [7:0]                        m_axi_arlen,
    output wire [2:0]                        m_axi_arsize,
    output wire [1:0]                        m_axi_arburst,
    output reg                               m_axi_arvalid,
    input  wire                              m_axi_arready,
    input  wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                        m_axi_rresp,
    input  wire                              m_axi_rvalid,
    output reg                               m_axi_rready,
    input  wire                              m_axi_rlast
);

    localparam integer ADDR_LSB = 2;
    localparam integer VALUES_PER_WORD = C_M_AXI_DATA_WIDTH / N;
    localparam integer IMAGE_SIZE = IN_CH * IN_H * IN_W;

    localparam [1:0] CFG_INPUT  = 2'd0;
    localparam [1:0] CFG_WEIGHT = 2'd1;
    localparam [1:0] CFG_BIAS   = 2'd2;

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

    localparam [4:0] ST_IDLE             = 5'd0;
    localparam [4:0] ST_LOAD_W_SETUP     = 5'd1;
    localparam [4:0] ST_LOAD_B_SETUP     = 5'd2;
    localparam [4:0] ST_LOAD_I_SETUP     = 5'd3;
    localparam [4:0] ST_READ_WORD        = 5'd4;
    localparam [4:0] ST_WAIT_WORD        = 5'd5;
    localparam [4:0] ST_WRITE_CFG        = 5'd6;
    localparam [4:0] ST_NEXT_VALUE       = 5'd7;
    localparam [4:0] ST_NEXT_WEIGHT_LYR  = 5'd8;
    localparam [4:0] ST_NEXT_BIAS_LYR    = 5'd9;
    localparam [4:0] ST_START_INFERENCE  = 5'd10;
    localparam [4:0] ST_WAIT_INFERENCE   = 5'd11;
    localparam [4:0] ST_DONE             = 5'd12;
    localparam [4:0] ST_ERROR            = 5'd13;

    localparam [3:0] REG_CONTROL     = 4'h0; // bit0=run full sequence, bit1=clear done/error
    localparam [3:0] REG_STATUS      = 4'h1; // bit0=busy, bit1=done, bit2=error, bit3=dut_busy
    localparam [3:0] REG_WEIGHT_BASE = 4'h2; // packed weight stream base address
    localparam [3:0] REG_BIAS_BASE   = 4'h3; // packed bias stream base address
    localparam [3:0] REG_IMAGE_BASE  = 4'h4; // packed image stream base address
    localparam [3:0] REG_TIMEOUT     = 4'h5; // inference timeout cycles, 0 disables
    localparam [3:0] REG_CLASS       = 4'h6; // class_out
    localparam [3:0] REG_LOGIT_ADDR  = 4'h7; // logit index
    localparam [3:0] REG_LOGIT_DATA  = 4'h8; // logit value
    localparam [3:0] REG_DEBUG_STATE = 4'h9; // loader state
    localparam [3:0] REG_DEBUG_LAYER = 4'hA; // loader layer/index info

    assign m_axi_arlen = 8'd0;
    assign m_axi_arsize = (C_M_AXI_DATA_WIDTH == 64) ? 3'd3 :
                          (C_M_AXI_DATA_WIDTH == 32) ? 3'd2 :
                          (C_M_AXI_DATA_WIDTH == 16) ? 3'd1 : 3'd0;
    assign m_axi_arburst = 2'b01;

    reg [4:0] state;
    reg [4:0] return_state;
    reg done_latched;
    reg error_latched;

    reg [31:0] weight_base_addr;
    reg [31:0] bias_base_addr;
    reg [31:0] image_base_addr;
    reg [31:0] timeout_limit;
    reg [31:0] timeout_count;

    reg [3:0] load_layer;
    reg [1:0] load_mem;
    reg [31:0] load_addr;
    reg [31:0] load_count;
    reg [31:0] layer_count;
    reg [31:0] stream_value_base;
    reg [31:0] word_value_index;
    reg [C_M_AXI_DATA_WIDTH-1:0] packed_word;

    reg dut_start;
    reg dut_cfg_write_en;
    reg [3:0] dut_cfg_layer;
    reg [1:0] dut_cfg_mem;
    reg [31:0] dut_cfg_addr;
    reg [N-1:0] dut_cfg_data;
    reg [31:0] dut_logit_addr;

    wire [N-1:0] dut_logit_data;
    wire dut_busy;
    wire dut_done;
    wire [CLASS_W-1:0] dut_class_out;

    wire reset = ~aresetn;
    wire write_accept = s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid;
    wire read_accept = s_axi_arvalid && !s_axi_rvalid;
    wire [3:0] write_addr = s_axi_awaddr[ADDR_LSB +: 4];
    wire [3:0] read_addr = s_axi_araddr[ADDR_LSB +: 4];
    wire control_start = write_accept && (write_addr == REG_CONTROL) && s_axi_wdata[0];
    wire control_clear = write_accept && (write_addr == REG_CONTROL) && s_axi_wdata[1];

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
                4'd11: layer_weight_size = L11_W_SIZE;
                default: layer_weight_size = 0;
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
                4'd11: layer_bias_size = L11_B_SIZE;
                default: layer_bias_size = 0;
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

    generate
        if (USE_QUIRE == 0) begin : REGULAR_DUT
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
                .clk(aclk),
                .reset(reset),
                .start(dut_start),
                .cfg_write_en(dut_cfg_write_en),
                .cfg_layer(dut_cfg_layer),
                .cfg_mem(dut_cfg_mem),
                .cfg_addr(dut_cfg_addr),
                .cfg_data(dut_cfg_data),
                .logit_read_addr(dut_logit_addr),
                .logit_read_data(dut_logit_data),
                .busy(dut_busy),
                .done(dut_done),
                .class_out(dut_class_out)
            );
        end
        else begin : QUIRE_DUT
            reduced_vgg16_mnist_quire #(
                .N(N),
                .ES(ES),
                .QW(QW),
                .QF(QF),
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
                .clk(aclk),
                .reset(reset),
                .start(dut_start),
                .cfg_write_en(dut_cfg_write_en),
                .cfg_layer(dut_cfg_layer),
                .cfg_mem(dut_cfg_mem),
                .cfg_addr(dut_cfg_addr),
                .cfg_data(dut_cfg_data),
                .logit_read_addr(dut_logit_addr),
                .logit_read_data(dut_logit_data),
                .busy(dut_busy),
                .done(dut_done),
                .class_out(dut_class_out)
            );
        end
    endgenerate

    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_bvalid <= 1'b0;
            s_axi_arready <= 1'b0;
            s_axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
            s_axi_rresp <= 2'b00;
            s_axi_rvalid <= 1'b0;
            weight_base_addr <= 32'd0;
            bias_base_addr <= 32'd0;
            image_base_addr <= 32'd0;
            timeout_limit <= 32'd0;
            dut_logit_addr <= 32'd0;
        end
        else begin
            s_axi_awready <= write_accept;
            s_axi_wready <= write_accept;
            s_axi_arready <= read_accept;

            if (write_accept) begin
                case (write_addr)
                    REG_CONTROL: begin
                        // Command bits are consumed by the loader FSM.
                    end
                    REG_WEIGHT_BASE: weight_base_addr <= s_axi_wdata;
                    REG_BIAS_BASE:   bias_base_addr <= s_axi_wdata;
                    REG_IMAGE_BASE:  image_base_addr <= s_axi_wdata;
                    REG_TIMEOUT:     timeout_limit <= s_axi_wdata;
                    REG_LOGIT_ADDR:  dut_logit_addr <= s_axi_wdata;
                    default: begin end
                endcase
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            if (read_accept) begin
                case (read_addr)
                    REG_CONTROL: begin
                        s_axi_rdata <= 32'd0;
                    end
                    REG_STATUS: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[0] <= (state != ST_IDLE);
                        s_axi_rdata[1] <= done_latched;
                        s_axi_rdata[2] <= error_latched;
                        s_axi_rdata[3] <= dut_busy;
                    end
                    REG_WEIGHT_BASE: s_axi_rdata <= weight_base_addr;
                    REG_BIAS_BASE:   s_axi_rdata <= bias_base_addr;
                    REG_IMAGE_BASE:  s_axi_rdata <= image_base_addr;
                    REG_TIMEOUT:     s_axi_rdata <= timeout_limit;
                    REG_CLASS: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[CLASS_W-1:0] <= dut_class_out;
                    end
                    REG_LOGIT_ADDR: s_axi_rdata <= dut_logit_addr;
                    REG_LOGIT_DATA: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[N-1:0] <= dut_logit_data;
                    end
                    REG_DEBUG_STATE: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[4:0] <= state;
                    end
                    REG_DEBUG_LAYER: begin
                        s_axi_rdata <= {load_layer, load_mem, 2'b00, load_addr[21:0]};
                    end
                    default: s_axi_rdata <= 32'd0;
                endcase
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            state <= ST_IDLE;
            return_state <= ST_IDLE;
            timeout_count <= 32'd0;
            load_layer <= 4'd0;
            load_mem <= CFG_WEIGHT;
            load_addr <= 32'd0;
            load_count <= 32'd0;
            layer_count <= 32'd0;
            stream_value_base <= 32'd0;
            word_value_index <= 32'd0;
            packed_word <= {C_M_AXI_DATA_WIDTH{1'b0}};
            dut_start <= 1'b0;
            dut_cfg_write_en <= 1'b0;
            dut_cfg_layer <= 4'd0;
            dut_cfg_mem <= 2'd0;
            dut_cfg_addr <= 32'd0;
            dut_cfg_data <= {N{1'b0}};
            m_axi_araddr <= {C_M_AXI_ADDR_WIDTH{1'b0}};
            m_axi_arvalid <= 1'b0;
            m_axi_rready <= 1'b0;
            done_latched <= 1'b0;
            error_latched <= 1'b0;
        end
        else begin
            dut_start <= 1'b0;
            dut_cfg_write_en <= 1'b0;
            m_axi_rready <= 1'b0;

            if (control_clear) begin
                done_latched <= 1'b0;
                error_latched <= 1'b0;
            end

            case (state)
                ST_IDLE: begin
                    m_axi_arvalid <= 1'b0;
                    if (control_start) begin
                        done_latched <= 1'b0;
                        error_latched <= 1'b0;
                        load_layer <= 4'd0;
                        stream_value_base <= 32'd0;
                        state <= ST_LOAD_W_SETUP;
                    end
                end

                ST_LOAD_W_SETUP: begin
                    load_mem <= CFG_WEIGHT;
                    load_addr <= 32'd0;
                    load_count <= layer_weight_size(load_layer);
                    layer_count <= 32'd0;
                    word_value_index <= stream_value_base;
                    return_state <= ST_NEXT_VALUE;
                    state <= (layer_weight_size(load_layer) == 0) ? ST_NEXT_WEIGHT_LYR : ST_READ_WORD;
                end

                ST_LOAD_B_SETUP: begin
                    load_mem <= CFG_BIAS;
                    load_addr <= 32'd0;
                    load_count <= layer_bias_size(load_layer);
                    layer_count <= 32'd0;
                    word_value_index <= stream_value_base;
                    return_state <= ST_NEXT_VALUE;
                    state <= (layer_bias_size(load_layer) == 0) ? ST_NEXT_BIAS_LYR : ST_READ_WORD;
                end

                ST_LOAD_I_SETUP: begin
                    load_layer <= 4'd0;
                    load_mem <= CFG_INPUT;
                    load_addr <= 32'd0;
                    load_count <= IMAGE_SIZE;
                    layer_count <= 32'd0;
                    stream_value_base <= 32'd0;
                    word_value_index <= 32'd0;
                    return_state <= ST_NEXT_VALUE;
                    state <= ST_READ_WORD;
                end

                ST_READ_WORD: begin
                    m_axi_araddr <= ((load_mem == CFG_WEIGHT) ? weight_base_addr :
                                     (load_mem == CFG_BIAS) ? bias_base_addr :
                                     image_base_addr) +
                                    ((word_value_index / VALUES_PER_WORD) * (C_M_AXI_DATA_WIDTH / 8));
                    m_axi_arvalid <= 1'b1;
                    state <= ST_WAIT_WORD;
                end

                ST_WAIT_WORD: begin
                    if (m_axi_arvalid && m_axi_arready)
                        m_axi_arvalid <= 1'b0;

                    if (!m_axi_arvalid || m_axi_arready)
                        m_axi_rready <= 1'b1;

                    if (m_axi_rvalid) begin
                        packed_word <= m_axi_rdata;
                        if (m_axi_rresp != 2'b00)
                            state <= ST_ERROR;
                        else
                            state <= ST_WRITE_CFG;
                    end
                end

                ST_WRITE_CFG: begin
                    dut_cfg_layer <= load_layer;
                    dut_cfg_mem <= load_mem;
                    dut_cfg_addr <= load_addr;
                    dut_cfg_data <= packed_value_at(packed_word, word_value_index);
                    dut_cfg_write_en <= 1'b1;
                    state <= return_state;
                end

                ST_NEXT_VALUE: begin
                    load_addr <= load_addr + 1;
                    layer_count <= layer_count + 1;
                    word_value_index <= word_value_index + 1;

                    if (layer_count + 1 >= load_count) begin
                        if (load_mem == CFG_WEIGHT)
                            state <= ST_NEXT_WEIGHT_LYR;
                        else if (load_mem == CFG_BIAS)
                            state <= ST_NEXT_BIAS_LYR;
                        else
                            state <= ST_START_INFERENCE;
                    end
                    else begin
                        state <= ST_READ_WORD;
                    end
                end

                ST_NEXT_WEIGHT_LYR: begin
                    stream_value_base <= stream_value_base + layer_weight_size(load_layer);
                    if (load_layer == 4'd11) begin
                        load_layer <= 4'd0;
                        stream_value_base <= 32'd0;
                        state <= ST_LOAD_B_SETUP;
                    end
                    else begin
                        load_layer <= load_layer + 1;
                        state <= ST_LOAD_W_SETUP;
                    end
                end

                ST_NEXT_BIAS_LYR: begin
                    stream_value_base <= stream_value_base + layer_bias_size(load_layer);
                    if (load_layer == 4'd11)
                        state <= ST_LOAD_I_SETUP;
                    else begin
                        load_layer <= load_layer + 1;
                        state <= ST_LOAD_B_SETUP;
                    end
                end

                ST_START_INFERENCE: begin
                    timeout_count <= 32'd0;
                    dut_start <= 1'b1;
                    state <= ST_WAIT_INFERENCE;
                end

                ST_WAIT_INFERENCE: begin
                    if (dut_done) begin
                        done_latched <= 1'b1;
                        state <= ST_DONE;
                    end
                    else if (timeout_limit != 0 && timeout_count >= timeout_limit) begin
                        error_latched <= 1'b1;
                        state <= ST_ERROR;
                    end
                    else begin
                        timeout_count <= timeout_count + 1;
                    end
                end

                ST_DONE: begin
                    state <= ST_IDLE;
                end

                ST_ERROR: begin
                    error_latched <= 1'b1;
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready <= 1'b0;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_ERROR;
                end
            endcase
        end
    end

endmodule
