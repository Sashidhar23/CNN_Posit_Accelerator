`timescale 1ns / 1ps

// Autonomous AXI-Lite controller for the Real Digital Boolean board.
// A reset release runs all ten flash-resident MNIST images exactly once.
module boolean_batch_controller #(
    parameter [31:0] CONTROL_BASE = 32'h8000_0000,
    parameter [31:0] IMAGE_BASE = 32'h00B6_87CC,
    parameter integer IMAGE_BYTES = 784,
    parameter integer IMAGE_COUNT = 10
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        accel_done,
    input  wire        accel_error,
    input  wire [3:0]  accel_class,

    output reg  [31:0] m_axi_awaddr,
    output wire [2:0]  m_axi_awprot,
    output reg         m_axi_awvalid,
    input  wire        m_axi_awready,
    output reg  [31:0] m_axi_wdata,
    output wire [3:0]  m_axi_wstrb,
    output reg         m_axi_wvalid,
    input  wire        m_axi_wready,
    input  wire [1:0]  m_axi_bresp,
    input  wire        m_axi_bvalid,
    output reg         m_axi_bready,
    output wire [31:0] m_axi_araddr,
    output wire [2:0]  m_axi_arprot,
    output wire        m_axi_arvalid,
    input  wire        m_axi_arready,
    input  wire [31:0] m_axi_rdata,
    input  wire [1:0]  m_axi_rresp,
    input  wire        m_axi_rvalid,
    output wire        m_axi_rready,

    output reg         batch_busy,
    output reg         batch_done,
    output reg         batch_error,
    output reg  [3:0]  image_index,
    output reg  [3:0]  correct_count,
    output wire [3:0]  display_value
);

    localparam [31:0] REG_CONTROL = CONTROL_BASE + 32'h00;
    localparam [31:0] REG_IMAGE   = CONTROL_BASE + 32'h10;

    localparam [3:0] ST_BOOT       = 4'd0;
    localparam [3:0] ST_CLEAR_SEND = 4'd1;
    localparam [3:0] ST_CLEAR_RESP = 4'd2;
    localparam [3:0] ST_IMAGE_SEND = 4'd3;
    localparam [3:0] ST_IMAGE_RESP = 4'd4;
    localparam [3:0] ST_START_SEND = 4'd5;
    localparam [3:0] ST_START_RESP = 4'd6;
    localparam [3:0] ST_WAIT       = 4'd7;
    localparam [3:0] ST_FINISH     = 4'd8;
    localparam [3:0] ST_ERROR      = 4'd9;

    reg [3:0] state;
    reg [5:0] boot_delay;

    assign m_axi_awprot = 3'b000;
    assign m_axi_wstrb = 4'b1111;
    assign m_axi_araddr = 32'd0;
    assign m_axi_arprot = 3'b000;
    assign m_axi_arvalid = 1'b0;
    assign m_axi_rready = 1'b1;
    assign display_value = batch_done ? correct_count : accel_class;

    function [3:0] expected_label;
        input [3:0] index;
        begin
            case (index)
                4'd0: expected_label = 4'd7;
                4'd1: expected_label = 4'd2;
                4'd2: expected_label = 4'd1;
                4'd3: expected_label = 4'd0;
                4'd4: expected_label = 4'd4;
                4'd5: expected_label = 4'd1;
                4'd6: expected_label = 4'd4;
                4'd7: expected_label = 4'd9;
                4'd8: expected_label = 4'd5;
                4'd9: expected_label = 4'd9;
                default: expected_label = 4'd0;
            endcase
        end
    endfunction

    wire write_sent = (!m_axi_awvalid || m_axi_awready) &&
                      (!m_axi_wvalid || m_axi_wready);

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_BOOT;
            boot_delay <= 6'd0;
            m_axi_awaddr <= 32'd0;
            m_axi_awvalid <= 1'b0;
            m_axi_wdata <= 32'd0;
            m_axi_wvalid <= 1'b0;
            m_axi_bready <= 1'b0;
            batch_busy <= 1'b1;
            batch_done <= 1'b0;
            batch_error <= 1'b0;
            image_index <= 4'd0;
            correct_count <= 4'd0;
        end
        else begin
            case (state)
                ST_BOOT: begin
                    if (boot_delay == 6'd63) begin
                        m_axi_awaddr <= REG_CONTROL;
                        m_axi_wdata <= 32'd2;
                        m_axi_awvalid <= 1'b1;
                        m_axi_wvalid <= 1'b1;
                        state <= ST_CLEAR_SEND;
                    end
                    else begin
                        boot_delay <= boot_delay + 1'b1;
                    end
                end

                ST_CLEAR_SEND: begin
                    if (m_axi_awvalid && m_axi_awready)
                        m_axi_awvalid <= 1'b0;
                    if (m_axi_wvalid && m_axi_wready)
                        m_axi_wvalid <= 1'b0;
                    if (write_sent) begin
                        m_axi_bready <= 1'b1;
                        state <= ST_CLEAR_RESP;
                    end
                end

                ST_CLEAR_RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        if (m_axi_bresp != 2'b00) begin
                            batch_error <= 1'b1;
                            state <= ST_ERROR;
                        end
                        else begin
                            m_axi_awaddr <= REG_IMAGE;
                            m_axi_wdata <= IMAGE_BASE + (image_index * IMAGE_BYTES);
                            m_axi_awvalid <= 1'b1;
                            m_axi_wvalid <= 1'b1;
                            state <= ST_IMAGE_SEND;
                        end
                    end
                end

                ST_IMAGE_SEND: begin
                    if (m_axi_awvalid && m_axi_awready)
                        m_axi_awvalid <= 1'b0;
                    if (m_axi_wvalid && m_axi_wready)
                        m_axi_wvalid <= 1'b0;
                    if (write_sent) begin
                        m_axi_bready <= 1'b1;
                        state <= ST_IMAGE_RESP;
                    end
                end

                ST_IMAGE_RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        if (m_axi_bresp != 2'b00) begin
                            batch_error <= 1'b1;
                            state <= ST_ERROR;
                        end
                        else begin
                            m_axi_awaddr <= REG_CONTROL;
                            m_axi_wdata <= 32'd1;
                            m_axi_awvalid <= 1'b1;
                            m_axi_wvalid <= 1'b1;
                            state <= ST_START_SEND;
                        end
                    end
                end

                ST_START_SEND: begin
                    if (m_axi_awvalid && m_axi_awready)
                        m_axi_awvalid <= 1'b0;
                    if (m_axi_wvalid && m_axi_wready)
                        m_axi_wvalid <= 1'b0;
                    if (write_sent) begin
                        m_axi_bready <= 1'b1;
                        state <= ST_START_RESP;
                    end
                end

                ST_START_RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        if (m_axi_bresp != 2'b00) begin
                            batch_error <= 1'b1;
                            state <= ST_ERROR;
                        end
                        else begin
                            state <= ST_WAIT;
                        end
                    end
                end

                ST_WAIT: begin
                    if (accel_error) begin
                        batch_error <= 1'b1;
                        state <= ST_ERROR;
                    end
                    else if (accel_done) begin
                        if (accel_class == expected_label(image_index))
                            correct_count <= correct_count + 1'b1;
                        if (image_index + 1 >= IMAGE_COUNT) begin
                            state <= ST_FINISH;
                        end
                        else begin
                            image_index <= image_index + 1'b1;
                            m_axi_awaddr <= REG_CONTROL;
                            m_axi_wdata <= 32'd2;
                            m_axi_awvalid <= 1'b1;
                            m_axi_wvalid <= 1'b1;
                            state <= ST_CLEAR_SEND;
                        end
                    end
                end

                ST_FINISH: begin
                    batch_busy <= 1'b0;
                    batch_done <= 1'b1;
                end

                ST_ERROR: begin
                    m_axi_awvalid <= 1'b0;
                    m_axi_wvalid <= 1'b0;
                    m_axi_bready <= 1'b0;
                    batch_busy <= 1'b0;
                    batch_done <= 1'b0;
                    batch_error <= 1'b1;
                end

                default: begin
                    batch_error <= 1'b1;
                    state <= ST_ERROR;
                end
            endcase
        end
    end

endmodule
