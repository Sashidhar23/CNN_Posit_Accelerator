`timescale 1ns / 1ps

module tb_boolean_batch_controller;
    reg clk;
    reg reset;
    reg accel_done;
    reg accel_error;
    reg [3:0] accel_class;

    wire [31:0] m_axi_awaddr;
    wire [2:0] m_axi_awprot;
    wire m_axi_awvalid;
    reg m_axi_awready;
    wire [31:0] m_axi_wdata;
    wire [3:0] m_axi_wstrb;
    wire m_axi_wvalid;
    reg m_axi_wready;
    reg [1:0] m_axi_bresp;
    reg m_axi_bvalid;
    wire m_axi_bready;
    wire [31:0] m_axi_araddr;
    wire [2:0] m_axi_arprot;
    wire m_axi_arvalid;
    reg m_axi_arready;
    reg [31:0] m_axi_rdata;
    reg [1:0] m_axi_rresp;
    reg m_axi_rvalid;
    wire m_axi_rready;
    wire batch_busy;
    wire batch_done;
    wire batch_error;
    wire [3:0] image_index;
    wire [3:0] correct_count;
    wire [3:0] display_value;

    integer errors;
    integer writes;
    integer starts;
    integer response_delay;
    integer cycles;

    localparam [31:0] CONTROL_BASE = 32'h8000_0000;
    localparam [31:0] IMAGE_BASE = 32'h00B6_87CC;

    boolean_batch_controller DUT (
        .clk(clk), .reset(reset),
        .accel_done(accel_done), .accel_error(accel_error),
        .accel_class(accel_class),
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awprot(m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wvalid(m_axi_wvalid), .m_axi_wready(m_axi_wready),
        .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        .m_axi_araddr(m_axi_araddr), .m_axi_arprot(m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
        .m_axi_rvalid(m_axi_rvalid), .m_axi_rready(m_axi_rready),
        .batch_busy(batch_busy), .batch_done(batch_done),
        .batch_error(batch_error), .image_index(image_index),
        .correct_count(correct_count), .display_value(display_value)
    );

    function [3:0] expected_label;
        input integer index;
        begin
            case (index)
                0: expected_label = 4'd7;
                1: expected_label = 4'd2;
                2: expected_label = 4'd1;
                3: expected_label = 4'd0;
                4: expected_label = 4'd4;
                5: expected_label = 4'd1;
                6: expected_label = 4'd4;
                7: expected_label = 4'd9;
                8: expected_label = 4'd5;
                9: expected_label = 4'd9;
                default: expected_label = 4'd0;
            endcase
        end
    endfunction

    always #5 clk = ~clk;

    // Minimal AXI-Lite write slave plus a short accelerator completion model.
    always @(posedge clk) begin
        if (reset) begin
            m_axi_bvalid <= 1'b0;
            m_axi_bresp <= 2'b00;
            accel_done <= 1'b0;
            accel_class <= 4'd0;
            response_delay <= 0;
            writes <= 0;
            starts <= 0;
        end
        else begin
            if (m_axi_bvalid && m_axi_bready)
                m_axi_bvalid <= 1'b0;

            if (m_axi_awvalid && m_axi_wvalid &&
                m_axi_awready && m_axi_wready && !m_axi_bvalid) begin
                writes <= writes + 1;
                m_axi_bvalid <= 1'b1;
                m_axi_bresp <= 2'b00;

                if (m_axi_awaddr == CONTROL_BASE && m_axi_wdata == 32'd2) begin
                    accel_done <= 1'b0;
                end
                else if (m_axi_awaddr == CONTROL_BASE + 32'h10) begin
                    if (m_axi_wdata !== IMAGE_BASE + (starts * 784)) begin
                        $display("FAIL image address %h expected %h",
                                 m_axi_wdata, IMAGE_BASE + (starts * 784));
                        errors <= errors + 1;
                    end
                end
                else if (m_axi_awaddr == CONTROL_BASE && m_axi_wdata == 32'd1) begin
                    response_delay <= 3;
                    starts <= starts + 1;
                end
                else begin
                    $display("FAIL unexpected write addr=%h data=%h",
                             m_axi_awaddr, m_axi_wdata);
                    errors <= errors + 1;
                end
            end

            if (response_delay > 1)
                response_delay <= response_delay - 1;
            else if (response_delay == 1) begin
                response_delay <= 0;
                accel_class <= expected_label(starts - 1);
                accel_done <= 1'b1;
            end
        end
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        accel_done = 1'b0;
        accel_error = 1'b0;
        accel_class = 4'd0;
        m_axi_awready = 1'b1;
        m_axi_wready = 1'b1;
        m_axi_bresp = 2'b00;
        m_axi_bvalid = 1'b0;
        m_axi_arready = 1'b1;
        m_axi_rdata = 32'd0;
        m_axi_rresp = 2'b00;
        m_axi_rvalid = 1'b0;
        errors = 0;
        writes = 0;
        starts = 0;
        response_delay = 0;

        repeat (4) @(posedge clk);
        reset = 1'b0;

        for (cycles = 0; cycles < 2000 && !batch_done && !batch_error;
             cycles = cycles + 1)
            @(posedge clk);

        if (!batch_done || batch_error) begin
            $display("FAIL controller did not complete cleanly");
            errors = errors + 1;
        end
        if (starts != 10 || writes != 30) begin
            $display("FAIL starts=%0d writes=%0d expected 10/30", starts, writes);
            errors = errors + 1;
        end
        if (correct_count !== 4'd10 || display_value !== 4'd10) begin
            $display("FAIL correct=%0d display=%0d expected 10",
                     correct_count, display_value);
            errors = errors + 1;
        end
        if (image_index !== 4'd9 || batch_busy) begin
            $display("FAIL final index=%0d busy=%b", image_index, batch_busy);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS tb_boolean_batch_controller: 10/10 images sequenced");
        else
            $display("FAIL tb_boolean_batch_controller: errors=%0d", errors);
        $finish;
    end

endmodule
