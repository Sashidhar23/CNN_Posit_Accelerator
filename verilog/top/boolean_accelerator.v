//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Tue Jul 14 18:34:41 2026
//Host        : LAPTOP-Q67ALKPQ running 64-bit major release  (build 9200)
//Command     : generate_target boolean_accelerator.bd
//Design      : boolean_accelerator
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "boolean_accelerator,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=boolean_accelerator,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=11,numReposBlks=7,numNonXlnxBlks=0,numHierBlks=4,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=2,numPkgbdBlks=0,bdsource=USER,synth_mode=None}" *) (* HW_HANDOFF = "boolean_accelerator.hwdef" *) 
module boolean_accelerator
   (led_busy,
    led_class,
    led_clock_locked,
    led_done,
    led_error,
    mclk,
    qspi_io0_i,
    qspi_io0_o,
    qspi_io0_t,
    qspi_io1_i,
    qspi_io1_o,
    qspi_io1_t,
    qspi_io2_i,
    qspi_io2_o,
    qspi_io2_t,
    qspi_io3_i,
    qspi_io3_o,
    qspi_io3_t,
    qspi_ss_i,
    qspi_ss_o,
    qspi_ss_t,
    reset);
  output led_busy;
  output [3:0]led_class;
  output led_clock_locked;
  output led_done;
  output led_error;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.MCLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.MCLK, CLK_DOMAIN boolean_accelerator_clk_in1_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input mclk;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO0_I" *) (* X_INTERFACE_MODE = "Master" *) input qspi_io0_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO0_O" *) output qspi_io0_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO0_T" *) output qspi_io0_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO1_I" *) input qspi_io1_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO1_O" *) output qspi_io1_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO1_T" *) output qspi_io1_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO2_I" *) input qspi_io2_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO2_O" *) output qspi_io2_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO2_T" *) output qspi_io2_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO3_I" *) input qspi_io3_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO3_O" *) output qspi_io3_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi IO3_T" *) output qspi_io3_t;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi SS_I" *) input [0:0]qspi_ss_i;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi SS_O" *) output [0:0]qspi_ss_o;
  (* X_INTERFACE_INFO = "xilinx.com:interface:spi:1.0 qspi SS_T" *) output qspi_ss_t;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RESET RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RESET, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input reset;

  wire [31:0]axi_ctrl_M00_AXI_ARADDR;
  wire [2:0]axi_ctrl_M00_AXI_ARPROT;
  wire axi_ctrl_M00_AXI_ARREADY;
  wire axi_ctrl_M00_AXI_ARVALID;
  wire [31:0]axi_ctrl_M00_AXI_AWADDR;
  wire [2:0]axi_ctrl_M00_AXI_AWPROT;
  wire axi_ctrl_M00_AXI_AWREADY;
  wire axi_ctrl_M00_AXI_AWVALID;
  wire axi_ctrl_M00_AXI_BREADY;
  wire [1:0]axi_ctrl_M00_AXI_BRESP;
  wire axi_ctrl_M00_AXI_BVALID;
  wire [31:0]axi_ctrl_M00_AXI_RDATA;
  wire axi_ctrl_M00_AXI_RREADY;
  wire [1:0]axi_ctrl_M00_AXI_RRESP;
  wire axi_ctrl_M00_AXI_RVALID;
  wire [31:0]axi_ctrl_M00_AXI_WDATA;
  wire axi_ctrl_M00_AXI_WREADY;
  wire [3:0]axi_ctrl_M00_AXI_WSTRB;
  wire axi_ctrl_M00_AXI_WVALID;
  wire [31:0]axi_ctrl_M01_AXI_ARADDR;
  wire axi_ctrl_M01_AXI_ARREADY;
  wire axi_ctrl_M01_AXI_ARVALID;
  wire [31:0]axi_ctrl_M01_AXI_AWADDR;
  wire axi_ctrl_M01_AXI_AWREADY;
  wire axi_ctrl_M01_AXI_AWVALID;
  wire axi_ctrl_M01_AXI_BREADY;
  wire [1:0]axi_ctrl_M01_AXI_BRESP;
  wire axi_ctrl_M01_AXI_BVALID;
  wire [31:0]axi_ctrl_M01_AXI_RDATA;
  wire axi_ctrl_M01_AXI_RREADY;
  wire [1:0]axi_ctrl_M01_AXI_RRESP;
  wire axi_ctrl_M01_AXI_RVALID;
  wire [31:0]axi_ctrl_M01_AXI_WDATA;
  wire axi_ctrl_M01_AXI_WREADY;
  wire [3:0]axi_ctrl_M01_AXI_WSTRB;
  wire axi_ctrl_M01_AXI_WVALID;
  wire [31:0]batch_ctrl_0_m_axi_ARADDR;
  wire [2:0]batch_ctrl_0_m_axi_ARPROT;
  wire [0:0]batch_ctrl_0_m_axi_ARREADY;
  wire batch_ctrl_0_m_axi_ARVALID;
  wire [31:0]batch_ctrl_0_m_axi_AWADDR;
  wire [2:0]batch_ctrl_0_m_axi_AWPROT;
  wire [0:0]batch_ctrl_0_m_axi_AWREADY;
  wire batch_ctrl_0_m_axi_AWVALID;
  wire batch_ctrl_0_m_axi_BREADY;
  wire [1:0]batch_ctrl_0_m_axi_BRESP;
  wire [0:0]batch_ctrl_0_m_axi_BVALID;
  wire [31:0]batch_ctrl_0_m_axi_RDATA;
  wire batch_ctrl_0_m_axi_RREADY;
  wire [1:0]batch_ctrl_0_m_axi_RRESP;
  wire [0:0]batch_ctrl_0_m_axi_RVALID;
  wire [31:0]batch_ctrl_0_m_axi_WDATA;
  wire [0:0]batch_ctrl_0_m_axi_WREADY;
  wire [3:0]batch_ctrl_0_m_axi_WSTRB;
  wire batch_ctrl_0_m_axi_WVALID;
  wire clk_wiz_0_clk_out1;
  wire clk_wiz_0_clk_out2;
  wire [3:0]cnn_accel_0_class_result;
  wire cnn_accel_0_done;
  wire cnn_accel_0_error;
  wire [23:0]cnn_accel_0_m_axi_ARADDR;
  wire [1:0]cnn_accel_0_m_axi_ARBURST;
  wire [3:0]cnn_accel_0_m_axi_ARCACHE;
  wire [0:0]cnn_accel_0_m_axi_ARID;
  wire [7:0]cnn_accel_0_m_axi_ARLEN;
  wire cnn_accel_0_m_axi_ARLOCK;
  wire [2:0]cnn_accel_0_m_axi_ARPROT;
  wire cnn_accel_0_m_axi_ARREADY;
  wire [2:0]cnn_accel_0_m_axi_ARSIZE;
  wire cnn_accel_0_m_axi_ARVALID;
  wire [23:0]cnn_accel_0_m_axi_AWADDR;
  wire [1:0]cnn_accel_0_m_axi_AWBURST;
  wire [3:0]cnn_accel_0_m_axi_AWCACHE;
  wire [0:0]cnn_accel_0_m_axi_AWID;
  wire [7:0]cnn_accel_0_m_axi_AWLEN;
  wire cnn_accel_0_m_axi_AWLOCK;
  wire [2:0]cnn_accel_0_m_axi_AWPROT;
  wire cnn_accel_0_m_axi_AWREADY;
  wire [2:0]cnn_accel_0_m_axi_AWSIZE;
  wire cnn_accel_0_m_axi_AWVALID;
  wire [0:0]cnn_accel_0_m_axi_BID;
  wire cnn_accel_0_m_axi_BREADY;
  wire [1:0]cnn_accel_0_m_axi_BRESP;
  wire cnn_accel_0_m_axi_BVALID;
  wire [31:0]cnn_accel_0_m_axi_RDATA;
  wire [0:0]cnn_accel_0_m_axi_RID;
  wire cnn_accel_0_m_axi_RLAST;
  wire cnn_accel_0_m_axi_RREADY;
  wire [1:0]cnn_accel_0_m_axi_RRESP;
  wire cnn_accel_0_m_axi_RVALID;
  wire [31:0]cnn_accel_0_m_axi_WDATA;
  wire cnn_accel_0_m_axi_WLAST;
  wire cnn_accel_0_m_axi_WREADY;
  wire [3:0]cnn_accel_0_m_axi_WSTRB;
  wire cnn_accel_0_m_axi_WVALID;
  wire [0:0]const_zero_dout;
  wire led_busy;
  wire [3:0]led_class;
  wire led_clock_locked;
  wire led_done;
  wire led_error;
  wire mclk;
  wire qspi_io0_i;
  wire qspi_io0_o;
  wire qspi_io0_t;
  wire qspi_io1_i;
  wire qspi_io1_o;
  wire qspi_io1_t;
  wire qspi_io2_i;
  wire qspi_io2_o;
  wire qspi_io2_t;
  wire qspi_io3_i;
  wire qspi_io3_o;
  wire qspi_io3_t;
  wire [0:0]qspi_ss_i;
  wire [0:0]qspi_ss_o;
  wire qspi_ss_t;
  wire reset;
  wire [0:0]rst_core_peripheral_aresetn;
  wire [0:0]rst_core_peripheral_reset;

  boolean_accelerator_axi_ctrl_0 axi_ctrl
       (.ACLK(clk_wiz_0_clk_out1),
        .ARESETN(rst_core_peripheral_aresetn),
        .M00_ACLK(clk_wiz_0_clk_out1),
        .M00_ARESETN(rst_core_peripheral_aresetn),
        .M00_AXI_araddr(axi_ctrl_M00_AXI_ARADDR),
        .M00_AXI_arprot(axi_ctrl_M00_AXI_ARPROT),
        .M00_AXI_arready(axi_ctrl_M00_AXI_ARREADY),
        .M00_AXI_arvalid(axi_ctrl_M00_AXI_ARVALID),
        .M00_AXI_awaddr(axi_ctrl_M00_AXI_AWADDR),
        .M00_AXI_awprot(axi_ctrl_M00_AXI_AWPROT),
        .M00_AXI_awready(axi_ctrl_M00_AXI_AWREADY),
        .M00_AXI_awvalid(axi_ctrl_M00_AXI_AWVALID),
        .M00_AXI_bready(axi_ctrl_M00_AXI_BREADY),
        .M00_AXI_bresp(axi_ctrl_M00_AXI_BRESP),
        .M00_AXI_bvalid(axi_ctrl_M00_AXI_BVALID),
        .M00_AXI_rdata(axi_ctrl_M00_AXI_RDATA),
        .M00_AXI_rready(axi_ctrl_M00_AXI_RREADY),
        .M00_AXI_rresp(axi_ctrl_M00_AXI_RRESP),
        .M00_AXI_rvalid(axi_ctrl_M00_AXI_RVALID),
        .M00_AXI_wdata(axi_ctrl_M00_AXI_WDATA),
        .M00_AXI_wready(axi_ctrl_M00_AXI_WREADY),
        .M00_AXI_wstrb(axi_ctrl_M00_AXI_WSTRB),
        .M00_AXI_wvalid(axi_ctrl_M00_AXI_WVALID),
        .M01_ACLK(clk_wiz_0_clk_out1),
        .M01_ARESETN(rst_core_peripheral_aresetn),
        .M01_AXI_araddr(axi_ctrl_M01_AXI_ARADDR),
        .M01_AXI_arready(axi_ctrl_M01_AXI_ARREADY),
        .M01_AXI_arvalid(axi_ctrl_M01_AXI_ARVALID),
        .M01_AXI_awaddr(axi_ctrl_M01_AXI_AWADDR),
        .M01_AXI_awready(axi_ctrl_M01_AXI_AWREADY),
        .M01_AXI_awvalid(axi_ctrl_M01_AXI_AWVALID),
        .M01_AXI_bready(axi_ctrl_M01_AXI_BREADY),
        .M01_AXI_bresp(axi_ctrl_M01_AXI_BRESP),
        .M01_AXI_bvalid(axi_ctrl_M01_AXI_BVALID),
        .M01_AXI_rdata(axi_ctrl_M01_AXI_RDATA),
        .M01_AXI_rready(axi_ctrl_M01_AXI_RREADY),
        .M01_AXI_rresp(axi_ctrl_M01_AXI_RRESP),
        .M01_AXI_rvalid(axi_ctrl_M01_AXI_RVALID),
        .M01_AXI_wdata(axi_ctrl_M01_AXI_WDATA),
        .M01_AXI_wready(axi_ctrl_M01_AXI_WREADY),
        .M01_AXI_wstrb(axi_ctrl_M01_AXI_WSTRB),
        .M01_AXI_wvalid(axi_ctrl_M01_AXI_WVALID),
        .S00_ACLK(clk_wiz_0_clk_out1),
        .S00_ARESETN(rst_core_peripheral_aresetn),
        .S00_AXI_araddr(batch_ctrl_0_m_axi_ARADDR),
        .S00_AXI_arprot(batch_ctrl_0_m_axi_ARPROT),
        .S00_AXI_arready(batch_ctrl_0_m_axi_ARREADY),
        .S00_AXI_arvalid(batch_ctrl_0_m_axi_ARVALID),
        .S00_AXI_awaddr(batch_ctrl_0_m_axi_AWADDR),
        .S00_AXI_awprot(batch_ctrl_0_m_axi_AWPROT),
        .S00_AXI_awready(batch_ctrl_0_m_axi_AWREADY),
        .S00_AXI_awvalid(batch_ctrl_0_m_axi_AWVALID),
        .S00_AXI_bready(batch_ctrl_0_m_axi_BREADY),
        .S00_AXI_bresp(batch_ctrl_0_m_axi_BRESP),
        .S00_AXI_bvalid(batch_ctrl_0_m_axi_BVALID),
        .S00_AXI_rdata(batch_ctrl_0_m_axi_RDATA),
        .S00_AXI_rready(batch_ctrl_0_m_axi_RREADY),
        .S00_AXI_rresp(batch_ctrl_0_m_axi_RRESP),
        .S00_AXI_rvalid(batch_ctrl_0_m_axi_RVALID),
        .S00_AXI_wdata(batch_ctrl_0_m_axi_WDATA),
        .S00_AXI_wready(batch_ctrl_0_m_axi_WREADY),
        .S00_AXI_wstrb(batch_ctrl_0_m_axi_WSTRB),
        .S00_AXI_wvalid(batch_ctrl_0_m_axi_WVALID));
  boolean_accelerator_batch_ctrl_0_0 batch_ctrl_0
       (.accel_class(cnn_accel_0_class_result),
        .accel_done(cnn_accel_0_done),
        .accel_error(cnn_accel_0_error),
        .batch_busy(led_busy),
        .batch_done(led_done),
        .batch_error(led_error),
        .clk(clk_wiz_0_clk_out1),
        .display_value(led_class),
        .m_axi_araddr(batch_ctrl_0_m_axi_ARADDR),
        .m_axi_arprot(batch_ctrl_0_m_axi_ARPROT),
        .m_axi_arready(batch_ctrl_0_m_axi_ARREADY),
        .m_axi_arvalid(batch_ctrl_0_m_axi_ARVALID),
        .m_axi_awaddr(batch_ctrl_0_m_axi_AWADDR),
        .m_axi_awprot(batch_ctrl_0_m_axi_AWPROT),
        .m_axi_awready(batch_ctrl_0_m_axi_AWREADY),
        .m_axi_awvalid(batch_ctrl_0_m_axi_AWVALID),
        .m_axi_bready(batch_ctrl_0_m_axi_BREADY),
        .m_axi_bresp(batch_ctrl_0_m_axi_BRESP),
        .m_axi_bvalid(batch_ctrl_0_m_axi_BVALID),
        .m_axi_rdata(batch_ctrl_0_m_axi_RDATA),
        .m_axi_rready(batch_ctrl_0_m_axi_RREADY),
        .m_axi_rresp(batch_ctrl_0_m_axi_RRESP),
        .m_axi_rvalid(batch_ctrl_0_m_axi_RVALID),
        .m_axi_wdata(batch_ctrl_0_m_axi_WDATA),
        .m_axi_wready(batch_ctrl_0_m_axi_WREADY),
        .m_axi_wstrb(batch_ctrl_0_m_axi_WSTRB),
        .m_axi_wvalid(batch_ctrl_0_m_axi_WVALID),
        .reset(rst_core_peripheral_reset));
  boolean_accelerator_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(mclk),
        .clk_out1(clk_wiz_0_clk_out1),
        .clk_out2(clk_wiz_0_clk_out2),
        .locked(led_clock_locked),
        .reset(reset));
  boolean_accelerator_cnn_accel_0_0 cnn_accel_0
       (.aclk(clk_wiz_0_clk_out1),
        .aresetn(rst_core_peripheral_aresetn),
        .class_result(cnn_accel_0_class_result),
        .done(cnn_accel_0_done),
        .error(cnn_accel_0_error),
        .m_axi_araddr(cnn_accel_0_m_axi_ARADDR),
        .m_axi_arburst(cnn_accel_0_m_axi_ARBURST),
        .m_axi_arcache(cnn_accel_0_m_axi_ARCACHE),
        .m_axi_arid(cnn_accel_0_m_axi_ARID),
        .m_axi_arlen(cnn_accel_0_m_axi_ARLEN),
        .m_axi_arlock(cnn_accel_0_m_axi_ARLOCK),
        .m_axi_arprot(cnn_accel_0_m_axi_ARPROT),
        .m_axi_arready(cnn_accel_0_m_axi_ARREADY),
        .m_axi_arsize(cnn_accel_0_m_axi_ARSIZE),
        .m_axi_arvalid(cnn_accel_0_m_axi_ARVALID),
        .m_axi_awaddr(cnn_accel_0_m_axi_AWADDR),
        .m_axi_awburst(cnn_accel_0_m_axi_AWBURST),
        .m_axi_awcache(cnn_accel_0_m_axi_AWCACHE),
        .m_axi_awid(cnn_accel_0_m_axi_AWID),
        .m_axi_awlen(cnn_accel_0_m_axi_AWLEN),
        .m_axi_awlock(cnn_accel_0_m_axi_AWLOCK),
        .m_axi_awprot(cnn_accel_0_m_axi_AWPROT),
        .m_axi_awready(cnn_accel_0_m_axi_AWREADY),
        .m_axi_awsize(cnn_accel_0_m_axi_AWSIZE),
        .m_axi_awvalid(cnn_accel_0_m_axi_AWVALID),
        .m_axi_bid(cnn_accel_0_m_axi_BID),
        .m_axi_bready(cnn_accel_0_m_axi_BREADY),
        .m_axi_bresp(cnn_accel_0_m_axi_BRESP),
        .m_axi_bvalid(cnn_accel_0_m_axi_BVALID),
        .m_axi_rdata(cnn_accel_0_m_axi_RDATA),
        .m_axi_rid(cnn_accel_0_m_axi_RID),
        .m_axi_rlast(cnn_accel_0_m_axi_RLAST),
        .m_axi_rready(cnn_accel_0_m_axi_RREADY),
        .m_axi_rresp(cnn_accel_0_m_axi_RRESP),
        .m_axi_rvalid(cnn_accel_0_m_axi_RVALID),
        .m_axi_wdata(cnn_accel_0_m_axi_WDATA),
        .m_axi_wlast(cnn_accel_0_m_axi_WLAST),
        .m_axi_wready(cnn_accel_0_m_axi_WREADY),
        .m_axi_wstrb(cnn_accel_0_m_axi_WSTRB),
        .m_axi_wvalid(cnn_accel_0_m_axi_WVALID),
        .s_axi_araddr(axi_ctrl_M00_AXI_ARADDR[6:0]),
        .s_axi_arprot(axi_ctrl_M00_AXI_ARPROT),
        .s_axi_arready(axi_ctrl_M00_AXI_ARREADY),
        .s_axi_arvalid(axi_ctrl_M00_AXI_ARVALID),
        .s_axi_awaddr(axi_ctrl_M00_AXI_AWADDR[6:0]),
        .s_axi_awprot(axi_ctrl_M00_AXI_AWPROT),
        .s_axi_awready(axi_ctrl_M00_AXI_AWREADY),
        .s_axi_awvalid(axi_ctrl_M00_AXI_AWVALID),
        .s_axi_bready(axi_ctrl_M00_AXI_BREADY),
        .s_axi_bresp(axi_ctrl_M00_AXI_BRESP),
        .s_axi_bvalid(axi_ctrl_M00_AXI_BVALID),
        .s_axi_rdata(axi_ctrl_M00_AXI_RDATA),
        .s_axi_rready(axi_ctrl_M00_AXI_RREADY),
        .s_axi_rresp(axi_ctrl_M00_AXI_RRESP),
        .s_axi_rvalid(axi_ctrl_M00_AXI_RVALID),
        .s_axi_wdata(axi_ctrl_M00_AXI_WDATA),
        .s_axi_wready(axi_ctrl_M00_AXI_WREADY),
        .s_axi_wstrb(axi_ctrl_M00_AXI_WSTRB),
        .s_axi_wvalid(axi_ctrl_M00_AXI_WVALID));
  boolean_accelerator_const_zero_0 const_zero
       (.dout(const_zero_dout));
  boolean_accelerator_qspi_xip_0 qspi_xip
       (.ext_spi_clk(clk_wiz_0_clk_out2),
        .io0_i(qspi_io0_i),
        .io0_o(qspi_io0_o),
        .io0_t(qspi_io0_t),
        .io1_i(qspi_io1_i),
        .io1_o(qspi_io1_o),
        .io1_t(qspi_io1_t),
        .io2_i(qspi_io2_i),
        .io2_o(qspi_io2_o),
        .io2_t(qspi_io2_t),
        .io3_i(qspi_io3_i),
        .io3_o(qspi_io3_o),
        .io3_t(qspi_io3_t),
        .s_axi4_aclk(clk_wiz_0_clk_out1),
        .s_axi4_araddr(cnn_accel_0_m_axi_ARADDR),
        .s_axi4_arburst(cnn_accel_0_m_axi_ARBURST),
        .s_axi4_arcache(cnn_accel_0_m_axi_ARCACHE),
        .s_axi4_aresetn(rst_core_peripheral_aresetn),
        .s_axi4_arid(cnn_accel_0_m_axi_ARID),
        .s_axi4_arlen(cnn_accel_0_m_axi_ARLEN),
        .s_axi4_arlock(cnn_accel_0_m_axi_ARLOCK),
        .s_axi4_arprot(cnn_accel_0_m_axi_ARPROT),
        .s_axi4_arready(cnn_accel_0_m_axi_ARREADY),
        .s_axi4_arsize(cnn_accel_0_m_axi_ARSIZE),
        .s_axi4_arvalid(cnn_accel_0_m_axi_ARVALID),
        .s_axi4_awaddr(cnn_accel_0_m_axi_AWADDR),
        .s_axi4_awburst(cnn_accel_0_m_axi_AWBURST),
        .s_axi4_awcache(cnn_accel_0_m_axi_AWCACHE),
        .s_axi4_awid(cnn_accel_0_m_axi_AWID),
        .s_axi4_awlen(cnn_accel_0_m_axi_AWLEN),
        .s_axi4_awlock(cnn_accel_0_m_axi_AWLOCK),
        .s_axi4_awprot(cnn_accel_0_m_axi_AWPROT),
        .s_axi4_awready(cnn_accel_0_m_axi_AWREADY),
        .s_axi4_awsize(cnn_accel_0_m_axi_AWSIZE),
        .s_axi4_awvalid(cnn_accel_0_m_axi_AWVALID),
        .s_axi4_bid(cnn_accel_0_m_axi_BID),
        .s_axi4_bready(cnn_accel_0_m_axi_BREADY),
        .s_axi4_bresp(cnn_accel_0_m_axi_BRESP),
        .s_axi4_bvalid(cnn_accel_0_m_axi_BVALID),
        .s_axi4_rdata(cnn_accel_0_m_axi_RDATA),
        .s_axi4_rid(cnn_accel_0_m_axi_RID),
        .s_axi4_rlast(cnn_accel_0_m_axi_RLAST),
        .s_axi4_rready(cnn_accel_0_m_axi_RREADY),
        .s_axi4_rresp(cnn_accel_0_m_axi_RRESP),
        .s_axi4_rvalid(cnn_accel_0_m_axi_RVALID),
        .s_axi4_wdata(cnn_accel_0_m_axi_WDATA),
        .s_axi4_wlast(cnn_accel_0_m_axi_WLAST),
        .s_axi4_wready(cnn_accel_0_m_axi_WREADY),
        .s_axi4_wstrb(cnn_accel_0_m_axi_WSTRB),
        .s_axi4_wvalid(cnn_accel_0_m_axi_WVALID),
        .s_axi_aclk(clk_wiz_0_clk_out1),
        .s_axi_araddr(axi_ctrl_M01_AXI_ARADDR[6:0]),
        .s_axi_aresetn(rst_core_peripheral_aresetn),
        .s_axi_arready(axi_ctrl_M01_AXI_ARREADY),
        .s_axi_arvalid(axi_ctrl_M01_AXI_ARVALID),
        .s_axi_awaddr(axi_ctrl_M01_AXI_AWADDR[6:0]),
        .s_axi_awready(axi_ctrl_M01_AXI_AWREADY),
        .s_axi_awvalid(axi_ctrl_M01_AXI_AWVALID),
        .s_axi_bready(axi_ctrl_M01_AXI_BREADY),
        .s_axi_bresp(axi_ctrl_M01_AXI_BRESP),
        .s_axi_bvalid(axi_ctrl_M01_AXI_BVALID),
        .s_axi_rdata(axi_ctrl_M01_AXI_RDATA),
        .s_axi_rready(axi_ctrl_M01_AXI_RREADY),
        .s_axi_rresp(axi_ctrl_M01_AXI_RRESP),
        .s_axi_rvalid(axi_ctrl_M01_AXI_RVALID),
        .s_axi_wdata(axi_ctrl_M01_AXI_WDATA),
        .s_axi_wready(axi_ctrl_M01_AXI_WREADY),
        .s_axi_wstrb(axi_ctrl_M01_AXI_WSTRB),
        .s_axi_wvalid(axi_ctrl_M01_AXI_WVALID),
        .ss_i(qspi_ss_i),
        .ss_o(qspi_ss_o),
        .ss_t(qspi_ss_t));
  boolean_accelerator_rst_core_0 rst_core
       (.aux_reset_in(const_zero_dout),
        .dcm_locked(led_clock_locked),
        .ext_reset_in(reset),
        .mb_debug_sys_rst(const_zero_dout),
        .peripheral_aresetn(rst_core_peripheral_aresetn),
        .peripheral_reset(rst_core_peripheral_reset),
        .slowest_sync_clk(clk_wiz_0_clk_out1));
endmodule

module boolean_accelerator_axi_ctrl_0
   (ACLK,
    ARESETN,
    M00_ACLK,
    M00_ARESETN,
    M00_AXI_araddr,
    M00_AXI_arprot,
    M00_AXI_arready,
    M00_AXI_arvalid,
    M00_AXI_awaddr,
    M00_AXI_awprot,
    M00_AXI_awready,
    M00_AXI_awvalid,
    M00_AXI_bready,
    M00_AXI_bresp,
    M00_AXI_bvalid,
    M00_AXI_rdata,
    M00_AXI_rready,
    M00_AXI_rresp,
    M00_AXI_rvalid,
    M00_AXI_wdata,
    M00_AXI_wready,
    M00_AXI_wstrb,
    M00_AXI_wvalid,
    M01_ACLK,
    M01_ARESETN,
    M01_AXI_araddr,
    M01_AXI_arready,
    M01_AXI_arvalid,
    M01_AXI_awaddr,
    M01_AXI_awready,
    M01_AXI_awvalid,
    M01_AXI_bready,
    M01_AXI_bresp,
    M01_AXI_bvalid,
    M01_AXI_rdata,
    M01_AXI_rready,
    M01_AXI_rresp,
    M01_AXI_rvalid,
    M01_AXI_wdata,
    M01_AXI_wready,
    M01_AXI_wstrb,
    M01_AXI_wvalid,
    S00_ACLK,
    S00_ARESETN,
    S00_AXI_araddr,
    S00_AXI_arprot,
    S00_AXI_arready,
    S00_AXI_arvalid,
    S00_AXI_awaddr,
    S00_AXI_awprot,
    S00_AXI_awready,
    S00_AXI_awvalid,
    S00_AXI_bready,
    S00_AXI_bresp,
    S00_AXI_bvalid,
    S00_AXI_rdata,
    S00_AXI_rready,
    S00_AXI_rresp,
    S00_AXI_rvalid,
    S00_AXI_wdata,
    S00_AXI_wready,
    S00_AXI_wstrb,
    S00_AXI_wvalid);
  input ACLK;
  input ARESETN;
  input M00_ACLK;
  input M00_ARESETN;
  output [31:0]M00_AXI_araddr;
  output [2:0]M00_AXI_arprot;
  input M00_AXI_arready;
  output M00_AXI_arvalid;
  output [31:0]M00_AXI_awaddr;
  output [2:0]M00_AXI_awprot;
  input M00_AXI_awready;
  output M00_AXI_awvalid;
  output M00_AXI_bready;
  input [1:0]M00_AXI_bresp;
  input M00_AXI_bvalid;
  input [31:0]M00_AXI_rdata;
  output M00_AXI_rready;
  input [1:0]M00_AXI_rresp;
  input M00_AXI_rvalid;
  output [31:0]M00_AXI_wdata;
  input M00_AXI_wready;
  output [3:0]M00_AXI_wstrb;
  output M00_AXI_wvalid;
  input M01_ACLK;
  input M01_ARESETN;
  output [31:0]M01_AXI_araddr;
  input M01_AXI_arready;
  output M01_AXI_arvalid;
  output [31:0]M01_AXI_awaddr;
  input M01_AXI_awready;
  output M01_AXI_awvalid;
  output M01_AXI_bready;
  input [1:0]M01_AXI_bresp;
  input M01_AXI_bvalid;
  input [31:0]M01_AXI_rdata;
  output M01_AXI_rready;
  input [1:0]M01_AXI_rresp;
  input M01_AXI_rvalid;
  output [31:0]M01_AXI_wdata;
  input M01_AXI_wready;
  output [3:0]M01_AXI_wstrb;
  output M01_AXI_wvalid;
  input S00_ACLK;
  input S00_ARESETN;
  input [31:0]S00_AXI_araddr;
  input [2:0]S00_AXI_arprot;
  output [0:0]S00_AXI_arready;
  input [0:0]S00_AXI_arvalid;
  input [31:0]S00_AXI_awaddr;
  input [2:0]S00_AXI_awprot;
  output [0:0]S00_AXI_awready;
  input [0:0]S00_AXI_awvalid;
  input [0:0]S00_AXI_bready;
  output [1:0]S00_AXI_bresp;
  output [0:0]S00_AXI_bvalid;
  output [31:0]S00_AXI_rdata;
  input [0:0]S00_AXI_rready;
  output [1:0]S00_AXI_rresp;
  output [0:0]S00_AXI_rvalid;
  input [31:0]S00_AXI_wdata;
  output [0:0]S00_AXI_wready;
  input [3:0]S00_AXI_wstrb;
  input [0:0]S00_AXI_wvalid;

  wire ACLK;
  wire ARESETN;
  wire [31:0]M00_AXI_araddr;
  wire [2:0]M00_AXI_arprot;
  wire M00_AXI_arready;
  wire M00_AXI_arvalid;
  wire [31:0]M00_AXI_awaddr;
  wire [2:0]M00_AXI_awprot;
  wire M00_AXI_awready;
  wire M00_AXI_awvalid;
  wire M00_AXI_bready;
  wire [1:0]M00_AXI_bresp;
  wire M00_AXI_bvalid;
  wire [31:0]M00_AXI_rdata;
  wire M00_AXI_rready;
  wire [1:0]M00_AXI_rresp;
  wire M00_AXI_rvalid;
  wire [31:0]M00_AXI_wdata;
  wire M00_AXI_wready;
  wire [3:0]M00_AXI_wstrb;
  wire M00_AXI_wvalid;
  wire [31:0]M01_AXI_araddr;
  wire M01_AXI_arready;
  wire M01_AXI_arvalid;
  wire [31:0]M01_AXI_awaddr;
  wire M01_AXI_awready;
  wire M01_AXI_awvalid;
  wire M01_AXI_bready;
  wire [1:0]M01_AXI_bresp;
  wire M01_AXI_bvalid;
  wire [31:0]M01_AXI_rdata;
  wire M01_AXI_rready;
  wire [1:0]M01_AXI_rresp;
  wire M01_AXI_rvalid;
  wire [31:0]M01_AXI_wdata;
  wire M01_AXI_wready;
  wire [3:0]M01_AXI_wstrb;
  wire M01_AXI_wvalid;
  wire [31:0]S00_AXI_araddr;
  wire [2:0]S00_AXI_arprot;
  wire [0:0]S00_AXI_arready;
  wire [0:0]S00_AXI_arvalid;
  wire [31:0]S00_AXI_awaddr;
  wire [2:0]S00_AXI_awprot;
  wire [0:0]S00_AXI_awready;
  wire [0:0]S00_AXI_awvalid;
  wire [0:0]S00_AXI_bready;
  wire [1:0]S00_AXI_bresp;
  wire [0:0]S00_AXI_bvalid;
  wire [31:0]S00_AXI_rdata;
  wire [0:0]S00_AXI_rready;
  wire [1:0]S00_AXI_rresp;
  wire [0:0]S00_AXI_rvalid;
  wire [31:0]S00_AXI_wdata;
  wire [0:0]S00_AXI_wready;
  wire [3:0]S00_AXI_wstrb;
  wire [0:0]S00_AXI_wvalid;
  wire [31:0]s00_couplers_to_xbar_ARADDR;
  wire [2:0]s00_couplers_to_xbar_ARPROT;
  wire [0:0]s00_couplers_to_xbar_ARREADY;
  wire [0:0]s00_couplers_to_xbar_ARVALID;
  wire [31:0]s00_couplers_to_xbar_AWADDR;
  wire [2:0]s00_couplers_to_xbar_AWPROT;
  wire [0:0]s00_couplers_to_xbar_AWREADY;
  wire [0:0]s00_couplers_to_xbar_AWVALID;
  wire [0:0]s00_couplers_to_xbar_BREADY;
  wire [1:0]s00_couplers_to_xbar_BRESP;
  wire [0:0]s00_couplers_to_xbar_BVALID;
  wire [31:0]s00_couplers_to_xbar_RDATA;
  wire [0:0]s00_couplers_to_xbar_RREADY;
  wire [1:0]s00_couplers_to_xbar_RRESP;
  wire [0:0]s00_couplers_to_xbar_RVALID;
  wire [31:0]s00_couplers_to_xbar_WDATA;
  wire [0:0]s00_couplers_to_xbar_WREADY;
  wire [3:0]s00_couplers_to_xbar_WSTRB;
  wire [0:0]s00_couplers_to_xbar_WVALID;
  wire [31:0]xbar_to_m00_couplers_ARADDR;
  wire [2:0]xbar_to_m00_couplers_ARPROT;
  wire xbar_to_m00_couplers_ARREADY;
  wire [0:0]xbar_to_m00_couplers_ARVALID;
  wire [31:0]xbar_to_m00_couplers_AWADDR;
  wire [2:0]xbar_to_m00_couplers_AWPROT;
  wire xbar_to_m00_couplers_AWREADY;
  wire [0:0]xbar_to_m00_couplers_AWVALID;
  wire [0:0]xbar_to_m00_couplers_BREADY;
  wire [1:0]xbar_to_m00_couplers_BRESP;
  wire xbar_to_m00_couplers_BVALID;
  wire [31:0]xbar_to_m00_couplers_RDATA;
  wire [0:0]xbar_to_m00_couplers_RREADY;
  wire [1:0]xbar_to_m00_couplers_RRESP;
  wire xbar_to_m00_couplers_RVALID;
  wire [31:0]xbar_to_m00_couplers_WDATA;
  wire xbar_to_m00_couplers_WREADY;
  wire [3:0]xbar_to_m00_couplers_WSTRB;
  wire [0:0]xbar_to_m00_couplers_WVALID;
  wire [63:32]xbar_to_m01_couplers_ARADDR;
  wire xbar_to_m01_couplers_ARREADY;
  wire [1:1]xbar_to_m01_couplers_ARVALID;
  wire [63:32]xbar_to_m01_couplers_AWADDR;
  wire xbar_to_m01_couplers_AWREADY;
  wire [1:1]xbar_to_m01_couplers_AWVALID;
  wire [1:1]xbar_to_m01_couplers_BREADY;
  wire [1:0]xbar_to_m01_couplers_BRESP;
  wire xbar_to_m01_couplers_BVALID;
  wire [31:0]xbar_to_m01_couplers_RDATA;
  wire [1:1]xbar_to_m01_couplers_RREADY;
  wire [1:0]xbar_to_m01_couplers_RRESP;
  wire xbar_to_m01_couplers_RVALID;
  wire [63:32]xbar_to_m01_couplers_WDATA;
  wire xbar_to_m01_couplers_WREADY;
  wire [7:4]xbar_to_m01_couplers_WSTRB;
  wire [1:1]xbar_to_m01_couplers_WVALID;

  m00_couplers_imp_16L67MQ m00_couplers
       (.M_ACLK(ACLK),
        .M_ARESETN(ARESETN),
        .M_AXI_araddr(M00_AXI_araddr),
        .M_AXI_arprot(M00_AXI_arprot),
        .M_AXI_arready(M00_AXI_arready),
        .M_AXI_arvalid(M00_AXI_arvalid),
        .M_AXI_awaddr(M00_AXI_awaddr),
        .M_AXI_awprot(M00_AXI_awprot),
        .M_AXI_awready(M00_AXI_awready),
        .M_AXI_awvalid(M00_AXI_awvalid),
        .M_AXI_bready(M00_AXI_bready),
        .M_AXI_bresp(M00_AXI_bresp),
        .M_AXI_bvalid(M00_AXI_bvalid),
        .M_AXI_rdata(M00_AXI_rdata),
        .M_AXI_rready(M00_AXI_rready),
        .M_AXI_rresp(M00_AXI_rresp),
        .M_AXI_rvalid(M00_AXI_rvalid),
        .M_AXI_wdata(M00_AXI_wdata),
        .M_AXI_wready(M00_AXI_wready),
        .M_AXI_wstrb(M00_AXI_wstrb),
        .M_AXI_wvalid(M00_AXI_wvalid),
        .S_ACLK(ACLK),
        .S_ARESETN(ARESETN),
        .S_AXI_araddr(xbar_to_m00_couplers_ARADDR),
        .S_AXI_arprot(xbar_to_m00_couplers_ARPROT),
        .S_AXI_arready(xbar_to_m00_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m00_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m00_couplers_AWADDR),
        .S_AXI_awprot(xbar_to_m00_couplers_AWPROT),
        .S_AXI_awready(xbar_to_m00_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m00_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m00_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m00_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m00_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m00_couplers_RDATA),
        .S_AXI_rready(xbar_to_m00_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m00_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m00_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m00_couplers_WDATA),
        .S_AXI_wready(xbar_to_m00_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m00_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m00_couplers_WVALID));
  m01_couplers_imp_1XHYARQ m01_couplers
       (.M_ACLK(ACLK),
        .M_ARESETN(ARESETN),
        .M_AXI_araddr(M01_AXI_araddr),
        .M_AXI_arready(M01_AXI_arready),
        .M_AXI_arvalid(M01_AXI_arvalid),
        .M_AXI_awaddr(M01_AXI_awaddr),
        .M_AXI_awready(M01_AXI_awready),
        .M_AXI_awvalid(M01_AXI_awvalid),
        .M_AXI_bready(M01_AXI_bready),
        .M_AXI_bresp(M01_AXI_bresp),
        .M_AXI_bvalid(M01_AXI_bvalid),
        .M_AXI_rdata(M01_AXI_rdata),
        .M_AXI_rready(M01_AXI_rready),
        .M_AXI_rresp(M01_AXI_rresp),
        .M_AXI_rvalid(M01_AXI_rvalid),
        .M_AXI_wdata(M01_AXI_wdata),
        .M_AXI_wready(M01_AXI_wready),
        .M_AXI_wstrb(M01_AXI_wstrb),
        .M_AXI_wvalid(M01_AXI_wvalid),
        .S_ACLK(ACLK),
        .S_ARESETN(ARESETN),
        .S_AXI_araddr(xbar_to_m01_couplers_ARADDR),
        .S_AXI_arready(xbar_to_m01_couplers_ARREADY),
        .S_AXI_arvalid(xbar_to_m01_couplers_ARVALID),
        .S_AXI_awaddr(xbar_to_m01_couplers_AWADDR),
        .S_AXI_awready(xbar_to_m01_couplers_AWREADY),
        .S_AXI_awvalid(xbar_to_m01_couplers_AWVALID),
        .S_AXI_bready(xbar_to_m01_couplers_BREADY),
        .S_AXI_bresp(xbar_to_m01_couplers_BRESP),
        .S_AXI_bvalid(xbar_to_m01_couplers_BVALID),
        .S_AXI_rdata(xbar_to_m01_couplers_RDATA),
        .S_AXI_rready(xbar_to_m01_couplers_RREADY),
        .S_AXI_rresp(xbar_to_m01_couplers_RRESP),
        .S_AXI_rvalid(xbar_to_m01_couplers_RVALID),
        .S_AXI_wdata(xbar_to_m01_couplers_WDATA),
        .S_AXI_wready(xbar_to_m01_couplers_WREADY),
        .S_AXI_wstrb(xbar_to_m01_couplers_WSTRB),
        .S_AXI_wvalid(xbar_to_m01_couplers_WVALID));
  s00_couplers_imp_ANSJFG s00_couplers
       (.M_ACLK(ACLK),
        .M_ARESETN(ARESETN),
        .M_AXI_araddr(s00_couplers_to_xbar_ARADDR),
        .M_AXI_arprot(s00_couplers_to_xbar_ARPROT),
        .M_AXI_arready(s00_couplers_to_xbar_ARREADY),
        .M_AXI_arvalid(s00_couplers_to_xbar_ARVALID),
        .M_AXI_awaddr(s00_couplers_to_xbar_AWADDR),
        .M_AXI_awprot(s00_couplers_to_xbar_AWPROT),
        .M_AXI_awready(s00_couplers_to_xbar_AWREADY),
        .M_AXI_awvalid(s00_couplers_to_xbar_AWVALID),
        .M_AXI_bready(s00_couplers_to_xbar_BREADY),
        .M_AXI_bresp(s00_couplers_to_xbar_BRESP),
        .M_AXI_bvalid(s00_couplers_to_xbar_BVALID),
        .M_AXI_rdata(s00_couplers_to_xbar_RDATA),
        .M_AXI_rready(s00_couplers_to_xbar_RREADY),
        .M_AXI_rresp(s00_couplers_to_xbar_RRESP),
        .M_AXI_rvalid(s00_couplers_to_xbar_RVALID),
        .M_AXI_wdata(s00_couplers_to_xbar_WDATA),
        .M_AXI_wready(s00_couplers_to_xbar_WREADY),
        .M_AXI_wstrb(s00_couplers_to_xbar_WSTRB),
        .M_AXI_wvalid(s00_couplers_to_xbar_WVALID),
        .S_ACLK(ACLK),
        .S_ARESETN(ARESETN),
        .S_AXI_araddr(S00_AXI_araddr),
        .S_AXI_arprot(S00_AXI_arprot),
        .S_AXI_arready(S00_AXI_arready),
        .S_AXI_arvalid(S00_AXI_arvalid),
        .S_AXI_awaddr(S00_AXI_awaddr),
        .S_AXI_awprot(S00_AXI_awprot),
        .S_AXI_awready(S00_AXI_awready),
        .S_AXI_awvalid(S00_AXI_awvalid),
        .S_AXI_bready(S00_AXI_bready),
        .S_AXI_bresp(S00_AXI_bresp),
        .S_AXI_bvalid(S00_AXI_bvalid),
        .S_AXI_rdata(S00_AXI_rdata),
        .S_AXI_rready(S00_AXI_rready),
        .S_AXI_rresp(S00_AXI_rresp),
        .S_AXI_rvalid(S00_AXI_rvalid),
        .S_AXI_wdata(S00_AXI_wdata),
        .S_AXI_wready(S00_AXI_wready),
        .S_AXI_wstrb(S00_AXI_wstrb),
        .S_AXI_wvalid(S00_AXI_wvalid));
  boolean_accelerator_axi_ctrl_imp_xbar_0 xbar
       (.aclk(ACLK),
        .aresetn(ARESETN),
        .m_axi_araddr({xbar_to_m01_couplers_ARADDR,xbar_to_m00_couplers_ARADDR}),
        .m_axi_arprot(xbar_to_m00_couplers_ARPROT),
        .m_axi_arready({xbar_to_m01_couplers_ARREADY,xbar_to_m00_couplers_ARREADY}),
        .m_axi_arvalid({xbar_to_m01_couplers_ARVALID,xbar_to_m00_couplers_ARVALID}),
        .m_axi_awaddr({xbar_to_m01_couplers_AWADDR,xbar_to_m00_couplers_AWADDR}),
        .m_axi_awprot(xbar_to_m00_couplers_AWPROT),
        .m_axi_awready({xbar_to_m01_couplers_AWREADY,xbar_to_m00_couplers_AWREADY}),
        .m_axi_awvalid({xbar_to_m01_couplers_AWVALID,xbar_to_m00_couplers_AWVALID}),
        .m_axi_bready({xbar_to_m01_couplers_BREADY,xbar_to_m00_couplers_BREADY}),
        .m_axi_bresp({xbar_to_m01_couplers_BRESP,xbar_to_m00_couplers_BRESP}),
        .m_axi_bvalid({xbar_to_m01_couplers_BVALID,xbar_to_m00_couplers_BVALID}),
        .m_axi_rdata({xbar_to_m01_couplers_RDATA,xbar_to_m00_couplers_RDATA}),
        .m_axi_rready({xbar_to_m01_couplers_RREADY,xbar_to_m00_couplers_RREADY}),
        .m_axi_rresp({xbar_to_m01_couplers_RRESP,xbar_to_m00_couplers_RRESP}),
        .m_axi_rvalid({xbar_to_m01_couplers_RVALID,xbar_to_m00_couplers_RVALID}),
        .m_axi_wdata({xbar_to_m01_couplers_WDATA,xbar_to_m00_couplers_WDATA}),
        .m_axi_wready({xbar_to_m01_couplers_WREADY,xbar_to_m00_couplers_WREADY}),
        .m_axi_wstrb({xbar_to_m01_couplers_WSTRB,xbar_to_m00_couplers_WSTRB}),
        .m_axi_wvalid({xbar_to_m01_couplers_WVALID,xbar_to_m00_couplers_WVALID}),
        .s_axi_araddr(s00_couplers_to_xbar_ARADDR),
        .s_axi_arprot(s00_couplers_to_xbar_ARPROT),
        .s_axi_arready(s00_couplers_to_xbar_ARREADY),
        .s_axi_arvalid(s00_couplers_to_xbar_ARVALID),
        .s_axi_awaddr(s00_couplers_to_xbar_AWADDR),
        .s_axi_awprot(s00_couplers_to_xbar_AWPROT),
        .s_axi_awready(s00_couplers_to_xbar_AWREADY),
        .s_axi_awvalid(s00_couplers_to_xbar_AWVALID),
        .s_axi_bready(s00_couplers_to_xbar_BREADY),
        .s_axi_bresp(s00_couplers_to_xbar_BRESP),
        .s_axi_bvalid(s00_couplers_to_xbar_BVALID),
        .s_axi_rdata(s00_couplers_to_xbar_RDATA),
        .s_axi_rready(s00_couplers_to_xbar_RREADY),
        .s_axi_rresp(s00_couplers_to_xbar_RRESP),
        .s_axi_rvalid(s00_couplers_to_xbar_RVALID),
        .s_axi_wdata(s00_couplers_to_xbar_WDATA),
        .s_axi_wready(s00_couplers_to_xbar_WREADY),
        .s_axi_wstrb(s00_couplers_to_xbar_WSTRB),
        .s_axi_wvalid(s00_couplers_to_xbar_WVALID));
endmodule

module m00_couplers_imp_16L67MQ
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire [31:0]M_AXI_araddr;
  wire [2:0]M_AXI_arprot;
  wire M_AXI_arvalid;
  wire [31:0]M_AXI_awaddr;
  wire [2:0]M_AXI_awprot;
  wire M_AXI_awvalid;
  wire M_AXI_bready;
  wire M_AXI_rready;
  wire [31:0]M_AXI_wdata;
  wire [3:0]M_AXI_wstrb;
  wire M_AXI_wvalid;
  wire S_AXI_arready;
  wire S_AXI_awready;
  wire [1:0]S_AXI_bresp;
  wire S_AXI_bvalid;
  wire [31:0]S_AXI_rdata;
  wire [1:0]S_AXI_rresp;
  wire S_AXI_rvalid;
  wire S_AXI_wready;

  assign M_AXI_araddr = S_AXI_araddr[31:0];
  assign M_AXI_arprot = S_AXI_arprot[2:0];
  assign M_AXI_arvalid = S_AXI_arvalid;
  assign M_AXI_awaddr = S_AXI_awaddr[31:0];
  assign M_AXI_awprot = S_AXI_awprot[2:0];
  assign M_AXI_awvalid = S_AXI_awvalid;
  assign M_AXI_bready = S_AXI_bready;
  assign M_AXI_rready = S_AXI_rready;
  assign M_AXI_wdata = S_AXI_wdata[31:0];
  assign M_AXI_wstrb = S_AXI_wstrb[3:0];
  assign M_AXI_wvalid = S_AXI_wvalid;
  assign S_AXI_arready = M_AXI_arready;
  assign S_AXI_awready = M_AXI_awready;
  assign S_AXI_bresp = M_AXI_bresp[1:0];
  assign S_AXI_bvalid = M_AXI_bvalid;
  assign S_AXI_rdata = M_AXI_rdata[31:0];
  assign S_AXI_rresp = M_AXI_rresp[1:0];
  assign S_AXI_rvalid = M_AXI_rvalid;
  assign S_AXI_wready = M_AXI_wready;
endmodule

module m01_couplers_imp_1XHYARQ
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  input M_AXI_arready;
  output M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  input M_AXI_awready;
  output M_AXI_awvalid;
  output M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  output S_AXI_arready;
  input S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  output S_AXI_awready;
  input S_AXI_awvalid;
  input S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input S_AXI_wvalid;

  wire [31:0]M_AXI_araddr;
  wire M_AXI_arvalid;
  wire [31:0]M_AXI_awaddr;
  wire M_AXI_awvalid;
  wire M_AXI_bready;
  wire M_AXI_rready;
  wire [31:0]M_AXI_wdata;
  wire [3:0]M_AXI_wstrb;
  wire M_AXI_wvalid;
  wire S_AXI_arready;
  wire S_AXI_awready;
  wire [1:0]S_AXI_bresp;
  wire S_AXI_bvalid;
  wire [31:0]S_AXI_rdata;
  wire [1:0]S_AXI_rresp;
  wire S_AXI_rvalid;
  wire S_AXI_wready;

  assign M_AXI_araddr = S_AXI_araddr[31:0];
  assign M_AXI_arvalid = S_AXI_arvalid;
  assign M_AXI_awaddr = S_AXI_awaddr[31:0];
  assign M_AXI_awvalid = S_AXI_awvalid;
  assign M_AXI_bready = S_AXI_bready;
  assign M_AXI_rready = S_AXI_rready;
  assign M_AXI_wdata = S_AXI_wdata[31:0];
  assign M_AXI_wstrb = S_AXI_wstrb[3:0];
  assign M_AXI_wvalid = S_AXI_wvalid;
  assign S_AXI_arready = M_AXI_arready;
  assign S_AXI_awready = M_AXI_awready;
  assign S_AXI_bresp = M_AXI_bresp[1:0];
  assign S_AXI_bvalid = M_AXI_bvalid;
  assign S_AXI_rdata = M_AXI_rdata[31:0];
  assign S_AXI_rresp = M_AXI_rresp[1:0];
  assign S_AXI_rvalid = M_AXI_rvalid;
  assign S_AXI_wready = M_AXI_wready;
endmodule

module s00_couplers_imp_ANSJFG
   (M_ACLK,
    M_ARESETN,
    M_AXI_araddr,
    M_AXI_arprot,
    M_AXI_arready,
    M_AXI_arvalid,
    M_AXI_awaddr,
    M_AXI_awprot,
    M_AXI_awready,
    M_AXI_awvalid,
    M_AXI_bready,
    M_AXI_bresp,
    M_AXI_bvalid,
    M_AXI_rdata,
    M_AXI_rready,
    M_AXI_rresp,
    M_AXI_rvalid,
    M_AXI_wdata,
    M_AXI_wready,
    M_AXI_wstrb,
    M_AXI_wvalid,
    S_ACLK,
    S_ARESETN,
    S_AXI_araddr,
    S_AXI_arprot,
    S_AXI_arready,
    S_AXI_arvalid,
    S_AXI_awaddr,
    S_AXI_awprot,
    S_AXI_awready,
    S_AXI_awvalid,
    S_AXI_bready,
    S_AXI_bresp,
    S_AXI_bvalid,
    S_AXI_rdata,
    S_AXI_rready,
    S_AXI_rresp,
    S_AXI_rvalid,
    S_AXI_wdata,
    S_AXI_wready,
    S_AXI_wstrb,
    S_AXI_wvalid);
  input M_ACLK;
  input M_ARESETN;
  output [31:0]M_AXI_araddr;
  output [2:0]M_AXI_arprot;
  input [0:0]M_AXI_arready;
  output [0:0]M_AXI_arvalid;
  output [31:0]M_AXI_awaddr;
  output [2:0]M_AXI_awprot;
  input [0:0]M_AXI_awready;
  output [0:0]M_AXI_awvalid;
  output [0:0]M_AXI_bready;
  input [1:0]M_AXI_bresp;
  input [0:0]M_AXI_bvalid;
  input [31:0]M_AXI_rdata;
  output [0:0]M_AXI_rready;
  input [1:0]M_AXI_rresp;
  input [0:0]M_AXI_rvalid;
  output [31:0]M_AXI_wdata;
  input [0:0]M_AXI_wready;
  output [3:0]M_AXI_wstrb;
  output [0:0]M_AXI_wvalid;
  input S_ACLK;
  input S_ARESETN;
  input [31:0]S_AXI_araddr;
  input [2:0]S_AXI_arprot;
  output [0:0]S_AXI_arready;
  input [0:0]S_AXI_arvalid;
  input [31:0]S_AXI_awaddr;
  input [2:0]S_AXI_awprot;
  output [0:0]S_AXI_awready;
  input [0:0]S_AXI_awvalid;
  input [0:0]S_AXI_bready;
  output [1:0]S_AXI_bresp;
  output [0:0]S_AXI_bvalid;
  output [31:0]S_AXI_rdata;
  input [0:0]S_AXI_rready;
  output [1:0]S_AXI_rresp;
  output [0:0]S_AXI_rvalid;
  input [31:0]S_AXI_wdata;
  output [0:0]S_AXI_wready;
  input [3:0]S_AXI_wstrb;
  input [0:0]S_AXI_wvalid;

  wire [31:0]M_AXI_araddr;
  wire [2:0]M_AXI_arprot;
  wire [0:0]M_AXI_arvalid;
  wire [31:0]M_AXI_awaddr;
  wire [2:0]M_AXI_awprot;
  wire [0:0]M_AXI_awvalid;
  wire [0:0]M_AXI_bready;
  wire [0:0]M_AXI_rready;
  wire [31:0]M_AXI_wdata;
  wire [3:0]M_AXI_wstrb;
  wire [0:0]M_AXI_wvalid;
  wire [0:0]S_AXI_arready;
  wire [0:0]S_AXI_awready;
  wire [1:0]S_AXI_bresp;
  wire [0:0]S_AXI_bvalid;
  wire [31:0]S_AXI_rdata;
  wire [1:0]S_AXI_rresp;
  wire [0:0]S_AXI_rvalid;
  wire [0:0]S_AXI_wready;

  assign M_AXI_araddr = S_AXI_araddr[31:0];
  assign M_AXI_arprot = S_AXI_arprot[2:0];
  assign M_AXI_arvalid = S_AXI_arvalid[0];
  assign M_AXI_awaddr = S_AXI_awaddr[31:0];
  assign M_AXI_awprot = S_AXI_awprot[2:0];
  assign M_AXI_awvalid = S_AXI_awvalid[0];
  assign M_AXI_bready = S_AXI_bready[0];
  assign M_AXI_rready = S_AXI_rready[0];
  assign M_AXI_wdata = S_AXI_wdata[31:0];
  assign M_AXI_wstrb = S_AXI_wstrb[3:0];
  assign M_AXI_wvalid = S_AXI_wvalid[0];
  assign S_AXI_arready = M_AXI_arready[0];
  assign S_AXI_awready = M_AXI_awready[0];
  assign S_AXI_bresp = M_AXI_bresp[1:0];
  assign S_AXI_bvalid = M_AXI_bvalid[0];
  assign S_AXI_rdata = M_AXI_rdata[31:0];
  assign S_AXI_rresp = M_AXI_rresp[1:0];
  assign S_AXI_rvalid = M_AXI_rvalid[0];
  assign S_AXI_wready = M_AXI_wready[0];
endmodule
