`timescale 1ns / 1ps

// End-to-end Boolean deployment simulation. The physical AXI Quad SPI block
// is replaced by a read-only AXI memory model containing the exact packed
// flash payload; the deployed controller and accelerator wrapper are real RTL.
module tb_boolean_accelerator_10_image_inference;
    localparam integer N = 8;
    localparam integer IMAGE_COUNT = 10;
    localparam integer IMAGE_BYTES = 28 * 28;
    localparam integer USE_QUIRE = 1;
    localparam [31:0] CONTROL_BASE = 32'h8000_0000;
    localparam [31:0] WEIGHT_BASE = 32'h0040_0000;
    localparam [31:0] BIAS_BASE = 32'h00B6_7C40;
    localparam [31:0] IMAGE_BASE = 32'h00B6_87CC;
    localparam integer FLASH_BYTES =
        (IMAGE_BASE + IMAGE_COUNT * IMAGE_BYTES) - WEIGHT_BASE;
    localparam [63:0] MAX_SIM_CYCLES = 64'd6_000_000_000;

    reg clk;
    reg reset;

    wire [31:0] ctrl_awaddr;
    wire [2:0] ctrl_awprot;
    wire ctrl_awvalid;
    wire ctrl_awready;
    wire [31:0] ctrl_wdata;
    wire [3:0] ctrl_wstrb;
    wire ctrl_wvalid;
    wire ctrl_wready;
    wire [1:0] ctrl_bresp;
    wire ctrl_bvalid;
    wire ctrl_bready;
    wire [31:0] ctrl_araddr;
    wire [2:0] ctrl_arprot;
    wire ctrl_arvalid;
    wire ctrl_arready;
    wire [31:0] ctrl_rdata;
    wire [1:0] ctrl_rresp;
    wire ctrl_rvalid;
    wire ctrl_rready;

    wire accel_busy;
    wire accel_done;
    wire accel_error;
    wire [3:0] accel_class;
    wire batch_busy;
    wire batch_done;
    wire batch_error;
    wire [3:0] batch_image_index;
    wire [3:0] batch_correct_count;
    wire [3:0] display_value;

    wire [0:0] mem_awid;
    wire [23:0] mem_awaddr;
    wire [7:0] mem_awlen;
    wire [2:0] mem_awsize;
    wire [1:0] mem_awburst;
    wire mem_awlock;
    wire [3:0] mem_awcache;
    wire [2:0] mem_awprot;
    wire [3:0] mem_awqos;
    wire [3:0] mem_awregion;
    wire mem_awvalid;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire mem_wlast;
    wire mem_wvalid;
    wire mem_bready;
    wire [0:0] mem_arid;
    wire [23:0] mem_araddr;
    wire [7:0] mem_arlen;
    wire [2:0] mem_arsize;
    wire [1:0] mem_arburst;
    wire mem_arlock;
    wire [3:0] mem_arcache;
    wire [2:0] mem_arprot;
    wire [3:0] mem_arqos;
    wire [3:0] mem_arregion;
    wire mem_arvalid;
    wire mem_arready;
    reg [31:0] mem_rdata;
    reg mem_rvalid;
    wire mem_rready;

    reg [7:0] flash_mem [0:FLASH_BYTES-1];
    reg [3:0] expected_class [0:IMAGE_COUNT-1];
    reg [3:0] predicted_class [0:IMAGE_COUNT-1];
    reg last_accel_done;
    reg [63:0] cycle_count;
    integer observed_images;
    integer observed_correct;
    integer errors;
    integer i;
    integer flash_offset;

    always #100 clk = ~clk;

    function [31:0] flash_word;
        input [23:0] address;
        integer offset;
        begin
            offset = address - WEIGHT_BASE;
            if (offset >= 0 && offset + 3 < FLASH_BYTES)
                flash_word = {flash_mem[offset + 3], flash_mem[offset + 2],
                              flash_mem[offset + 1], flash_mem[offset]};
            else
                flash_word = 32'hxxxx_xxxx;
        end
    endfunction

    boolean_batch_controller #(
        .CONTROL_BASE(CONTROL_BASE),
        .IMAGE_BASE(IMAGE_BASE),
        .IMAGE_BYTES(IMAGE_BYTES),
        .IMAGE_COUNT(IMAGE_COUNT)
    ) BATCH_CONTROLLER (
        .clk(clk), .reset(reset),
        .accel_done(accel_done), .accel_error(accel_error),
        .accel_class(accel_class),
        .m_axi_awaddr(ctrl_awaddr), .m_axi_awprot(ctrl_awprot),
        .m_axi_awvalid(ctrl_awvalid), .m_axi_awready(ctrl_awready),
        .m_axi_wdata(ctrl_wdata), .m_axi_wstrb(ctrl_wstrb),
        .m_axi_wvalid(ctrl_wvalid), .m_axi_wready(ctrl_wready),
        .m_axi_bresp(ctrl_bresp), .m_axi_bvalid(ctrl_bvalid),
        .m_axi_bready(ctrl_bready),
        .m_axi_araddr(ctrl_araddr), .m_axi_arprot(ctrl_arprot),
        .m_axi_arvalid(ctrl_arvalid), .m_axi_arready(ctrl_arready),
        .m_axi_rdata(ctrl_rdata), .m_axi_rresp(ctrl_rresp),
        .m_axi_rvalid(ctrl_rvalid), .m_axi_rready(ctrl_rready),
        .batch_busy(batch_busy), .batch_done(batch_done),
        .batch_error(batch_error), .image_index(batch_image_index),
        .correct_count(batch_correct_count), .display_value(display_value)
    );

    cnn_zynq_axi_master_wrapper #(
        .C_M_AXI_DATA_WIDTH(32),
        .C_M_AXI_ADDR_WIDTH(24),
        .C_M_AXI_ID_WIDTH(1),
        .DEFAULT_WEIGHT_BASE(WEIGHT_BASE),
        .DEFAULT_BIAS_BASE(BIAS_BASE),
        .DEFAULT_IMAGE_BASE(IMAGE_BASE),
        .N(N), .ES(1), .USE_QUIRE(USE_QUIRE),
        .ROWS(4), .COLS(4), .CLASS_W(4)
    ) ACCELERATOR (
        .aclk(clk), .aresetn(~reset),
        .s_axi_awaddr(ctrl_awaddr[6:0]), .s_axi_awprot(ctrl_awprot),
        .s_axi_awvalid(ctrl_awvalid), .s_axi_awready(ctrl_awready),
        .s_axi_wdata(ctrl_wdata), .s_axi_wstrb(ctrl_wstrb),
        .s_axi_wvalid(ctrl_wvalid), .s_axi_wready(ctrl_wready),
        .s_axi_bresp(ctrl_bresp), .s_axi_bvalid(ctrl_bvalid),
        .s_axi_bready(ctrl_bready),
        .s_axi_araddr(ctrl_araddr[6:0]), .s_axi_arprot(ctrl_arprot),
        .s_axi_arvalid(ctrl_arvalid), .s_axi_arready(ctrl_arready),
        .s_axi_rdata(ctrl_rdata), .s_axi_rresp(ctrl_rresp),
        .s_axi_rvalid(ctrl_rvalid), .s_axi_rready(ctrl_rready),
        .m_axi_awid(mem_awid), .m_axi_awaddr(mem_awaddr),
        .m_axi_awlen(mem_awlen), .m_axi_awsize(mem_awsize),
        .m_axi_awburst(mem_awburst), .m_axi_awlock(mem_awlock),
        .m_axi_awcache(mem_awcache), .m_axi_awprot(mem_awprot),
        .m_axi_awqos(mem_awqos), .m_axi_awregion(mem_awregion),
        .m_axi_awvalid(mem_awvalid), .m_axi_awready(1'b1),
        .m_axi_wdata(mem_wdata), .m_axi_wstrb(mem_wstrb),
        .m_axi_wlast(mem_wlast), .m_axi_wvalid(mem_wvalid),
        .m_axi_wready(1'b1), .m_axi_bid(1'b0), .m_axi_bresp(2'b00),
        .m_axi_bvalid(1'b0), .m_axi_bready(mem_bready),
        .m_axi_arid(mem_arid), .m_axi_araddr(mem_araddr),
        .m_axi_arlen(mem_arlen), .m_axi_arsize(mem_arsize),
        .m_axi_arburst(mem_arburst), .m_axi_arlock(mem_arlock),
        .m_axi_arcache(mem_arcache), .m_axi_arprot(mem_arprot),
        .m_axi_arqos(mem_arqos), .m_axi_arregion(mem_arregion),
        .m_axi_arvalid(mem_arvalid), .m_axi_arready(mem_arready),
        .m_axi_rid(1'b0), .m_axi_rdata(mem_rdata),
        .m_axi_rresp(2'b00), .m_axi_rlast(1'b1),
        .m_axi_rvalid(mem_rvalid), .m_axi_rready(mem_rready),
        .irq(), .busy(accel_busy), .done(accel_done),
        .error(accel_error), .class_result(accel_class)
    );

    assign mem_arready = !mem_rvalid;

    // One-cycle-latency, one-beat AXI read-only model of the QSPI XIP window.
    always @(posedge clk) begin
        if (reset) begin
            mem_rdata <= 32'd0;
            mem_rvalid <= 1'b0;
        end
        else begin
            if (mem_rvalid && mem_rready)
                mem_rvalid <= 1'b0;
            if (mem_arvalid && mem_arready) begin
                mem_rdata <= flash_word(mem_araddr);
                mem_rvalid <= 1'b1;
                if (mem_arlen != 0 || mem_arsize != 3'd2 ||
                    mem_arburst != 2'b01) begin
                    $display("FAIL unsupported AXI read addr=%h len=%0d size=%0d burst=%0d",
                             mem_araddr, mem_arlen, mem_arsize, mem_arburst);
                    errors = errors + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            last_accel_done <= 1'b0;
        end
        else begin
            last_accel_done <= accel_done;
            if (accel_done && !last_accel_done) begin
                predicted_class[batch_image_index] = accel_class;
                observed_images = observed_images + 1;
                if (accel_class === expected_class[batch_image_index]) begin
                    observed_correct = observed_correct + 1;
                    $display("PASS image %0d predicted=%0d expected=%0d",
                             batch_image_index, accel_class,
                             expected_class[batch_image_index]);
                end
                else begin
                    $display("MISS image %0d predicted=%0d expected=%0d",
                             batch_image_index, accel_class,
                             expected_class[batch_image_index]);
                end
            end
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        mem_rdata = 32'd0;
        mem_rvalid = 1'b0;
        last_accel_done = 1'b0;
        cycle_count = 0;
        observed_images = 0;
        observed_correct = 0;
        errors = 0;
        for (i = 0; i < IMAGE_COUNT; i = i + 1) begin
            expected_class[i] = 0;
            predicted_class[i] = 4'hf;
        end
`include "mnist_expected_labels.vh"

        $display("Loading %0d packed flash bytes...", FLASH_BYTES);
        $readmemh("boolean_model_images.mem", flash_mem);

        repeat (8) @(posedge clk);
        reset = 1'b0;

        while (!batch_done && !batch_error && cycle_count < MAX_SIM_CYCLES) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        if (batch_error || accel_error) begin
            $display("FAIL accelerator terminated with error");
            errors = errors + 1;
        end
        if (!batch_done) begin
            $display("FAIL timeout after %0d cycles", cycle_count);
            errors = errors + 1;
        end
        if (observed_images != IMAGE_COUNT) begin
            $display("FAIL observed %0d images, expected %0d",
                     observed_images, IMAGE_COUNT);
            errors = errors + 1;
        end
        if (batch_correct_count !== observed_correct[3:0]) begin
            $display("FAIL controller count=%0d testbench count=%0d",
                     batch_correct_count, observed_correct);
            errors = errors + 1;
        end

        $display("============================================================");
        for (i = 0; i < IMAGE_COUNT; i = i + 1)
            $display("Image %0d: predicted=%0d expected=%0d",
                     i, predicted_class[i], expected_class[i]);
        $display("BOOLEAN ACCELERATOR ACCURACY: %0d/%0d = %0d%%",
                 observed_correct, IMAGE_COUNT,
                 (observed_correct * 100) / IMAGE_COUNT);
        $display("Simulation cycles: %0d", cycle_count);
        if (errors == 0)
            $display("PASS tb_boolean_accelerator_10_image_inference");
        else
            $display("FAIL tb_boolean_accelerator_10_image_inference errors=%0d",
                     errors);
        $display("============================================================");
        $finish;
    end

endmodule
