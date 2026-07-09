`timescale 1ns / 1ps

module cnn_axi_lite_wrapper #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6,
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
    parameter ROWS = 3,
    parameter COLS = 3,
    parameter CLASS_W = (NUM_CLASSES <= 2) ? 1 : $clog2(NUM_CLASSES)
)(
    input  wire                              s_axi_aclk,
    input  wire                              s_axi_aresetn,

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
    input  wire                              s_axi_rready
);

    localparam integer ADDR_LSB = 2;

    localparam [3:0] REG_CONTROL    = 4'h0; // write bit0=start pulse, bit1=clear done
    localparam [3:0] REG_STATUS     = 4'h1; // bit0=busy, bit1=done_latched, bits[15:8]=class
    localparam [3:0] REG_CFG_SEL    = 4'h2; // bits[3:0]=cfg_layer, bits[9:8]=cfg_mem
    localparam [3:0] REG_CFG_ADDR   = 4'h3; // cfg address
    localparam [3:0] REG_CFG_DATA   = 4'h4; // write pulses cfg_write_en
    localparam [3:0] REG_LOGIT_ADDR = 4'h5; // logit read address
    localparam [3:0] REG_LOGIT_DATA = 4'h6; // read logit data

    reg start_pulse;
    reg cfg_write_pulse;
    reg done_latched;

    reg [3:0] cfg_layer_reg;
    reg [1:0] cfg_mem_reg;
    reg [31:0] cfg_addr_reg;
    reg [N-1:0] cfg_data_reg;
    reg [31:0] logit_addr_reg;

    wire [N-1:0] logit_data;
    wire busy;
    wire done;
    wire [CLASS_W-1:0] class_out;

    wire reset = ~s_axi_aresetn;

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
        .clk(s_axi_aclk),
        .reset(reset),
        .start(start_pulse),
        .cfg_write_en(cfg_write_pulse),
        .cfg_layer(cfg_layer_reg),
        .cfg_mem(cfg_mem_reg),
        .cfg_addr(cfg_addr_reg),
        .cfg_data(cfg_data_reg),
        .logit_read_addr(logit_addr_reg),
        .logit_read_data(logit_data),
        .busy(busy),
        .done(done),
        .class_out(class_out)
    );

    wire write_accept = s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid;
    wire read_accept = s_axi_arvalid && !s_axi_rvalid;
    wire [3:0] write_addr = s_axi_awaddr[ADDR_LSB +: 4];
    wire [3:0] read_addr = s_axi_araddr[ADDR_LSB +: 4];

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_bvalid <= 1'b0;
            s_axi_arready <= 1'b0;
            s_axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
            s_axi_rresp <= 2'b00;
            s_axi_rvalid <= 1'b0;

            start_pulse <= 1'b0;
            cfg_write_pulse <= 1'b0;
            done_latched <= 1'b0;
            cfg_layer_reg <= 4'd0;
            cfg_mem_reg <= 2'd0;
            cfg_addr_reg <= 32'd0;
            cfg_data_reg <= {N{1'b0}};
            logit_addr_reg <= 32'd0;
        end
        else begin
            start_pulse <= 1'b0;
            cfg_write_pulse <= 1'b0;

            if (done)
                done_latched <= 1'b1;

            s_axi_awready <= write_accept;
            s_axi_wready <= write_accept;

            if (write_accept) begin
                case (write_addr)
                    REG_CONTROL: begin
                        if (s_axi_wdata[0])
                            start_pulse <= 1'b1;
                        if (s_axi_wdata[1])
                            done_latched <= 1'b0;
                    end

                    REG_CFG_SEL: begin
                        cfg_layer_reg <= s_axi_wdata[3:0];
                        cfg_mem_reg <= s_axi_wdata[9:8];
                    end

                    REG_CFG_ADDR: begin
                        cfg_addr_reg <= s_axi_wdata;
                    end

                    REG_CFG_DATA: begin
                        cfg_data_reg <= s_axi_wdata[N-1:0];
                        cfg_write_pulse <= 1'b1;
                    end

                    REG_LOGIT_ADDR: begin
                        logit_addr_reg <= s_axi_wdata;
                    end

                    default: begin
                    end
                endcase

                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            s_axi_arready <= read_accept;

            if (read_accept) begin
                case (read_addr)
                    REG_CONTROL: begin
                        s_axi_rdata <= 32'd0;
                    end

                    REG_STATUS: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[0] <= busy;
                        s_axi_rdata[1] <= done_latched;
                        s_axi_rdata[15:8] <= {{(8-CLASS_W){1'b0}}, class_out};
                    end

                    REG_CFG_SEL: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[3:0] <= cfg_layer_reg;
                        s_axi_rdata[9:8] <= cfg_mem_reg;
                    end

                    REG_CFG_ADDR: begin
                        s_axi_rdata <= cfg_addr_reg;
                    end

                    REG_CFG_DATA: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[N-1:0] <= cfg_data_reg;
                    end

                    REG_LOGIT_ADDR: begin
                        s_axi_rdata <= logit_addr_reg;
                    end

                    REG_LOGIT_DATA: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rdata[N-1:0] <= logit_data;
                    end

                    default: begin
                        s_axi_rdata <= 32'd0;
                    end
                endcase

                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end

        end
    end

endmodule
