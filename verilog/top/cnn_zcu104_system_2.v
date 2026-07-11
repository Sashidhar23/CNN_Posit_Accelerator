//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Fri Jul 10 21:13:44 2026
//Host        : LAPTOP-Q67ALKPQ running 64-bit major release  (build 9200)
//Command     : generate_target cnn_zcu104_system_2.bd
//Design      : cnn_zcu104_system_2
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "cnn_zcu104_system_2,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=cnn_zcu104_system_2,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=4,numReposBlks=4,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=1,numPkgbdBlks=0,bdsource=USER,da_zynq_ultra_ps_e_cnt=1,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "cnn_zcu104_system_2.hwdef" *) 
module cnn_zcu104_system_2
   ();

  wire [6:0]axi_ctrl_sc_M00_AXI_ARADDR;
  wire [2:0]axi_ctrl_sc_M00_AXI_ARPROT;
  wire axi_ctrl_sc_M00_AXI_ARREADY;
  wire axi_ctrl_sc_M00_AXI_ARVALID;
  wire [6:0]axi_ctrl_sc_M00_AXI_AWADDR;
  wire [2:0]axi_ctrl_sc_M00_AXI_AWPROT;
  wire axi_ctrl_sc_M00_AXI_AWREADY;
  wire axi_ctrl_sc_M00_AXI_AWVALID;
  wire axi_ctrl_sc_M00_AXI_BREADY;
  wire [1:0]axi_ctrl_sc_M00_AXI_BRESP;
  wire axi_ctrl_sc_M00_AXI_BVALID;
  wire [31:0]axi_ctrl_sc_M00_AXI_RDATA;
  wire axi_ctrl_sc_M00_AXI_RREADY;
  wire [1:0]axi_ctrl_sc_M00_AXI_RRESP;
  wire axi_ctrl_sc_M00_AXI_RVALID;
  wire [31:0]axi_ctrl_sc_M00_AXI_WDATA;
  wire axi_ctrl_sc_M00_AXI_WREADY;
  wire [3:0]axi_ctrl_sc_M00_AXI_WSTRB;
  wire axi_ctrl_sc_M00_AXI_WVALID;
  wire [48:0]axi_ddr_sc_M00_AXI_ARADDR;
  wire [1:0]axi_ddr_sc_M00_AXI_ARBURST;
  wire [3:0]axi_ddr_sc_M00_AXI_ARCACHE;
  wire [7:0]axi_ddr_sc_M00_AXI_ARLEN;
  wire [0:0]axi_ddr_sc_M00_AXI_ARLOCK;
  wire [2:0]axi_ddr_sc_M00_AXI_ARPROT;
  wire [3:0]axi_ddr_sc_M00_AXI_ARQOS;
  wire axi_ddr_sc_M00_AXI_ARREADY;
  wire [2:0]axi_ddr_sc_M00_AXI_ARSIZE;
  wire axi_ddr_sc_M00_AXI_ARVALID;
  wire [48:0]axi_ddr_sc_M00_AXI_AWADDR;
  wire [1:0]axi_ddr_sc_M00_AXI_AWBURST;
  wire [3:0]axi_ddr_sc_M00_AXI_AWCACHE;
  wire [7:0]axi_ddr_sc_M00_AXI_AWLEN;
  wire [0:0]axi_ddr_sc_M00_AXI_AWLOCK;
  wire [2:0]axi_ddr_sc_M00_AXI_AWPROT;
  wire [3:0]axi_ddr_sc_M00_AXI_AWQOS;
  wire axi_ddr_sc_M00_AXI_AWREADY;
  wire [2:0]axi_ddr_sc_M00_AXI_AWSIZE;
  wire axi_ddr_sc_M00_AXI_AWVALID;
  wire axi_ddr_sc_M00_AXI_BREADY;
  wire [1:0]axi_ddr_sc_M00_AXI_BRESP;
  wire axi_ddr_sc_M00_AXI_BVALID;
  wire [127:0]axi_ddr_sc_M00_AXI_RDATA;
  wire axi_ddr_sc_M00_AXI_RLAST;
  wire axi_ddr_sc_M00_AXI_RREADY;
  wire [1:0]axi_ddr_sc_M00_AXI_RRESP;
  wire axi_ddr_sc_M00_AXI_RVALID;
  wire [127:0]axi_ddr_sc_M00_AXI_WDATA;
  wire axi_ddr_sc_M00_AXI_WLAST;
  wire axi_ddr_sc_M00_AXI_WREADY;
  wire [15:0]axi_ddr_sc_M00_AXI_WSTRB;
  wire axi_ddr_sc_M00_AXI_WVALID;
  wire [39:0]cnn_accel_0_m_axi_ARADDR;
  wire [1:0]cnn_accel_0_m_axi_ARBURST;
  wire [3:0]cnn_accel_0_m_axi_ARCACHE;
  wire [0:0]cnn_accel_0_m_axi_ARID;
  wire [7:0]cnn_accel_0_m_axi_ARLEN;
  wire cnn_accel_0_m_axi_ARLOCK;
  wire [2:0]cnn_accel_0_m_axi_ARPROT;
  wire [3:0]cnn_accel_0_m_axi_ARQOS;
  wire cnn_accel_0_m_axi_ARREADY;
  wire [2:0]cnn_accel_0_m_axi_ARSIZE;
  wire cnn_accel_0_m_axi_ARVALID;
  wire [39:0]cnn_accel_0_m_axi_AWADDR;
  wire [1:0]cnn_accel_0_m_axi_AWBURST;
  wire [3:0]cnn_accel_0_m_axi_AWCACHE;
  wire [0:0]cnn_accel_0_m_axi_AWID;
  wire [7:0]cnn_accel_0_m_axi_AWLEN;
  wire cnn_accel_0_m_axi_AWLOCK;
  wire [2:0]cnn_accel_0_m_axi_AWPROT;
  wire [3:0]cnn_accel_0_m_axi_AWQOS;
  wire cnn_accel_0_m_axi_AWREADY;
  wire [2:0]cnn_accel_0_m_axi_AWSIZE;
  wire cnn_accel_0_m_axi_AWVALID;
  wire [0:0]cnn_accel_0_m_axi_BID;
  wire cnn_accel_0_m_axi_BREADY;
  wire [1:0]cnn_accel_0_m_axi_BRESP;
  wire cnn_accel_0_m_axi_BVALID;
  wire [63:0]cnn_accel_0_m_axi_RDATA;
  wire [0:0]cnn_accel_0_m_axi_RID;
  wire cnn_accel_0_m_axi_RLAST;
  wire cnn_accel_0_m_axi_RREADY;
  wire [1:0]cnn_accel_0_m_axi_RRESP;
  wire cnn_accel_0_m_axi_RVALID;
  wire [63:0]cnn_accel_0_m_axi_WDATA;
  wire cnn_accel_0_m_axi_WLAST;
  wire cnn_accel_0_m_axi_WREADY;
  wire [7:0]cnn_accel_0_m_axi_WSTRB;
  wire cnn_accel_0_m_axi_WVALID;
  wire [39:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARADDR;
  wire [1:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARBURST;
  wire [3:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARCACHE;
  wire [15:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARID;
  wire [7:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARLEN;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARLOCK;
  wire [2:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARPROT;
  wire [3:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARQOS;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARREADY;
  wire [2:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARSIZE;
  wire [15:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARUSER;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARVALID;
  wire [39:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWADDR;
  wire [1:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWBURST;
  wire [3:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWCACHE;
  wire [15:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWID;
  wire [7:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWLEN;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWLOCK;
  wire [2:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWPROT;
  wire [3:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWQOS;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWREADY;
  wire [2:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWSIZE;
  wire [15:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWUSER;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWVALID;
  wire [15:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BID;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BREADY;
  wire [1:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BRESP;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BVALID;
  wire [127:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RDATA;
  wire [15:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RID;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RLAST;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RREADY;
  wire [1:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RRESP;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RVALID;
  wire [127:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WDATA;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WLAST;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WREADY;
  wire [15:0]zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WSTRB;
  wire zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WVALID;
  wire zynq_ultra_ps_e_0_pl_clk0;
  wire zynq_ultra_ps_e_0_pl_resetn0;

  cnn_zcu104_system_2_axi_ctrl_sc_0 axi_ctrl_sc
       (.M00_AXI_araddr(axi_ctrl_sc_M00_AXI_ARADDR),
        .M00_AXI_arprot(axi_ctrl_sc_M00_AXI_ARPROT),
        .M00_AXI_arready(axi_ctrl_sc_M00_AXI_ARREADY),
        .M00_AXI_arvalid(axi_ctrl_sc_M00_AXI_ARVALID),
        .M00_AXI_awaddr(axi_ctrl_sc_M00_AXI_AWADDR),
        .M00_AXI_awprot(axi_ctrl_sc_M00_AXI_AWPROT),
        .M00_AXI_awready(axi_ctrl_sc_M00_AXI_AWREADY),
        .M00_AXI_awvalid(axi_ctrl_sc_M00_AXI_AWVALID),
        .M00_AXI_bready(axi_ctrl_sc_M00_AXI_BREADY),
        .M00_AXI_bresp(axi_ctrl_sc_M00_AXI_BRESP),
        .M00_AXI_bvalid(axi_ctrl_sc_M00_AXI_BVALID),
        .M00_AXI_rdata(axi_ctrl_sc_M00_AXI_RDATA),
        .M00_AXI_rready(axi_ctrl_sc_M00_AXI_RREADY),
        .M00_AXI_rresp(axi_ctrl_sc_M00_AXI_RRESP),
        .M00_AXI_rvalid(axi_ctrl_sc_M00_AXI_RVALID),
        .M00_AXI_wdata(axi_ctrl_sc_M00_AXI_WDATA),
        .M00_AXI_wready(axi_ctrl_sc_M00_AXI_WREADY),
        .M00_AXI_wstrb(axi_ctrl_sc_M00_AXI_WSTRB),
        .M00_AXI_wvalid(axi_ctrl_sc_M00_AXI_WVALID),
        .S00_AXI_araddr(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARADDR),
        .S00_AXI_arburst(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARBURST),
        .S00_AXI_arcache(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARCACHE),
        .S00_AXI_arid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARID),
        .S00_AXI_arlen(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARLEN),
        .S00_AXI_arlock(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARLOCK),
        .S00_AXI_arprot(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARPROT),
        .S00_AXI_arqos(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARQOS),
        .S00_AXI_arready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARREADY),
        .S00_AXI_arsize(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARSIZE),
        .S00_AXI_aruser(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARUSER),
        .S00_AXI_arvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARVALID),
        .S00_AXI_awaddr(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWADDR),
        .S00_AXI_awburst(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWBURST),
        .S00_AXI_awcache(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWCACHE),
        .S00_AXI_awid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWID),
        .S00_AXI_awlen(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWLEN),
        .S00_AXI_awlock(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWLOCK),
        .S00_AXI_awprot(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWPROT),
        .S00_AXI_awqos(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWQOS),
        .S00_AXI_awready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWREADY),
        .S00_AXI_awsize(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWSIZE),
        .S00_AXI_awuser(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWUSER),
        .S00_AXI_awvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWVALID),
        .S00_AXI_bid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BID),
        .S00_AXI_bready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BREADY),
        .S00_AXI_bresp(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BRESP),
        .S00_AXI_bvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BVALID),
        .S00_AXI_rdata(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RDATA),
        .S00_AXI_rid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RID),
        .S00_AXI_rlast(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RLAST),
        .S00_AXI_rready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RREADY),
        .S00_AXI_rresp(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RRESP),
        .S00_AXI_rvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RVALID),
        .S00_AXI_wdata(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WDATA),
        .S00_AXI_wlast(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WLAST),
        .S00_AXI_wready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WREADY),
        .S00_AXI_wstrb(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WSTRB),
        .S00_AXI_wvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WVALID),
        .aclk(zynq_ultra_ps_e_0_pl_clk0),
        .aresetn(zynq_ultra_ps_e_0_pl_resetn0));
  cnn_zcu104_system_2_axi_ddr_sc_0 axi_ddr_sc
       (.M00_AXI_araddr(axi_ddr_sc_M00_AXI_ARADDR),
        .M00_AXI_arburst(axi_ddr_sc_M00_AXI_ARBURST),
        .M00_AXI_arcache(axi_ddr_sc_M00_AXI_ARCACHE),
        .M00_AXI_arlen(axi_ddr_sc_M00_AXI_ARLEN),
        .M00_AXI_arlock(axi_ddr_sc_M00_AXI_ARLOCK),
        .M00_AXI_arprot(axi_ddr_sc_M00_AXI_ARPROT),
        .M00_AXI_arqos(axi_ddr_sc_M00_AXI_ARQOS),
        .M00_AXI_arready(axi_ddr_sc_M00_AXI_ARREADY),
        .M00_AXI_arsize(axi_ddr_sc_M00_AXI_ARSIZE),
        .M00_AXI_arvalid(axi_ddr_sc_M00_AXI_ARVALID),
        .M00_AXI_awaddr(axi_ddr_sc_M00_AXI_AWADDR),
        .M00_AXI_awburst(axi_ddr_sc_M00_AXI_AWBURST),
        .M00_AXI_awcache(axi_ddr_sc_M00_AXI_AWCACHE),
        .M00_AXI_awlen(axi_ddr_sc_M00_AXI_AWLEN),
        .M00_AXI_awlock(axi_ddr_sc_M00_AXI_AWLOCK),
        .M00_AXI_awprot(axi_ddr_sc_M00_AXI_AWPROT),
        .M00_AXI_awqos(axi_ddr_sc_M00_AXI_AWQOS),
        .M00_AXI_awready(axi_ddr_sc_M00_AXI_AWREADY),
        .M00_AXI_awsize(axi_ddr_sc_M00_AXI_AWSIZE),
        .M00_AXI_awvalid(axi_ddr_sc_M00_AXI_AWVALID),
        .M00_AXI_bready(axi_ddr_sc_M00_AXI_BREADY),
        .M00_AXI_bresp(axi_ddr_sc_M00_AXI_BRESP),
        .M00_AXI_bvalid(axi_ddr_sc_M00_AXI_BVALID),
        .M00_AXI_rdata(axi_ddr_sc_M00_AXI_RDATA),
        .M00_AXI_rlast(axi_ddr_sc_M00_AXI_RLAST),
        .M00_AXI_rready(axi_ddr_sc_M00_AXI_RREADY),
        .M00_AXI_rresp(axi_ddr_sc_M00_AXI_RRESP),
        .M00_AXI_rvalid(axi_ddr_sc_M00_AXI_RVALID),
        .M00_AXI_wdata(axi_ddr_sc_M00_AXI_WDATA),
        .M00_AXI_wlast(axi_ddr_sc_M00_AXI_WLAST),
        .M00_AXI_wready(axi_ddr_sc_M00_AXI_WREADY),
        .M00_AXI_wstrb(axi_ddr_sc_M00_AXI_WSTRB),
        .M00_AXI_wvalid(axi_ddr_sc_M00_AXI_WVALID),
        .S00_AXI_araddr(cnn_accel_0_m_axi_ARADDR),
        .S00_AXI_arburst(cnn_accel_0_m_axi_ARBURST),
        .S00_AXI_arcache(cnn_accel_0_m_axi_ARCACHE),
        .S00_AXI_arid(cnn_accel_0_m_axi_ARID),
        .S00_AXI_arlen(cnn_accel_0_m_axi_ARLEN),
        .S00_AXI_arlock(cnn_accel_0_m_axi_ARLOCK),
        .S00_AXI_arprot(cnn_accel_0_m_axi_ARPROT),
        .S00_AXI_arqos(cnn_accel_0_m_axi_ARQOS),
        .S00_AXI_arready(cnn_accel_0_m_axi_ARREADY),
        .S00_AXI_arsize(cnn_accel_0_m_axi_ARSIZE),
        .S00_AXI_arvalid(cnn_accel_0_m_axi_ARVALID),
        .S00_AXI_awaddr(cnn_accel_0_m_axi_AWADDR),
        .S00_AXI_awburst(cnn_accel_0_m_axi_AWBURST),
        .S00_AXI_awcache(cnn_accel_0_m_axi_AWCACHE),
        .S00_AXI_awid(cnn_accel_0_m_axi_AWID),
        .S00_AXI_awlen(cnn_accel_0_m_axi_AWLEN),
        .S00_AXI_awlock(cnn_accel_0_m_axi_AWLOCK),
        .S00_AXI_awprot(cnn_accel_0_m_axi_AWPROT),
        .S00_AXI_awqos(cnn_accel_0_m_axi_AWQOS),
        .S00_AXI_awready(cnn_accel_0_m_axi_AWREADY),
        .S00_AXI_awsize(cnn_accel_0_m_axi_AWSIZE),
        .S00_AXI_awvalid(cnn_accel_0_m_axi_AWVALID),
        .S00_AXI_bid(cnn_accel_0_m_axi_BID),
        .S00_AXI_bready(cnn_accel_0_m_axi_BREADY),
        .S00_AXI_bresp(cnn_accel_0_m_axi_BRESP),
        .S00_AXI_bvalid(cnn_accel_0_m_axi_BVALID),
        .S00_AXI_rdata(cnn_accel_0_m_axi_RDATA),
        .S00_AXI_rid(cnn_accel_0_m_axi_RID),
        .S00_AXI_rlast(cnn_accel_0_m_axi_RLAST),
        .S00_AXI_rready(cnn_accel_0_m_axi_RREADY),
        .S00_AXI_rresp(cnn_accel_0_m_axi_RRESP),
        .S00_AXI_rvalid(cnn_accel_0_m_axi_RVALID),
        .S00_AXI_wdata(cnn_accel_0_m_axi_WDATA),
        .S00_AXI_wlast(cnn_accel_0_m_axi_WLAST),
        .S00_AXI_wready(cnn_accel_0_m_axi_WREADY),
        .S00_AXI_wstrb(cnn_accel_0_m_axi_WSTRB),
        .S00_AXI_wvalid(cnn_accel_0_m_axi_WVALID),
        .aclk(zynq_ultra_ps_e_0_pl_clk0),
        .aresetn(zynq_ultra_ps_e_0_pl_resetn0));
  cnn_zcu104_system_2_cnn_accel_0_0 cnn_accel_0
       (.aclk(zynq_ultra_ps_e_0_pl_clk0),
        .aresetn(zynq_ultra_ps_e_0_pl_resetn0),
        .m_axi_araddr(cnn_accel_0_m_axi_ARADDR),
        .m_axi_arburst(cnn_accel_0_m_axi_ARBURST),
        .m_axi_arcache(cnn_accel_0_m_axi_ARCACHE),
        .m_axi_arid(cnn_accel_0_m_axi_ARID),
        .m_axi_arlen(cnn_accel_0_m_axi_ARLEN),
        .m_axi_arlock(cnn_accel_0_m_axi_ARLOCK),
        .m_axi_arprot(cnn_accel_0_m_axi_ARPROT),
        .m_axi_arqos(cnn_accel_0_m_axi_ARQOS),
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
        .m_axi_awqos(cnn_accel_0_m_axi_AWQOS),
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
        .s_axi_araddr(axi_ctrl_sc_M00_AXI_ARADDR),
        .s_axi_arprot(axi_ctrl_sc_M00_AXI_ARPROT),
        .s_axi_arready(axi_ctrl_sc_M00_AXI_ARREADY),
        .s_axi_arvalid(axi_ctrl_sc_M00_AXI_ARVALID),
        .s_axi_awaddr(axi_ctrl_sc_M00_AXI_AWADDR),
        .s_axi_awprot(axi_ctrl_sc_M00_AXI_AWPROT),
        .s_axi_awready(axi_ctrl_sc_M00_AXI_AWREADY),
        .s_axi_awvalid(axi_ctrl_sc_M00_AXI_AWVALID),
        .s_axi_bready(axi_ctrl_sc_M00_AXI_BREADY),
        .s_axi_bresp(axi_ctrl_sc_M00_AXI_BRESP),
        .s_axi_bvalid(axi_ctrl_sc_M00_AXI_BVALID),
        .s_axi_rdata(axi_ctrl_sc_M00_AXI_RDATA),
        .s_axi_rready(axi_ctrl_sc_M00_AXI_RREADY),
        .s_axi_rresp(axi_ctrl_sc_M00_AXI_RRESP),
        .s_axi_rvalid(axi_ctrl_sc_M00_AXI_RVALID),
        .s_axi_wdata(axi_ctrl_sc_M00_AXI_WDATA),
        .s_axi_wready(axi_ctrl_sc_M00_AXI_WREADY),
        .s_axi_wstrb(axi_ctrl_sc_M00_AXI_WSTRB),
        .s_axi_wvalid(axi_ctrl_sc_M00_AXI_WVALID));
  cnn_zcu104_system_2_zynq_ultra_ps_e_0_0 zynq_ultra_ps_e_0
       (.maxigp0_araddr(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARADDR),
        .maxigp0_arburst(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARBURST),
        .maxigp0_arcache(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARCACHE),
        .maxigp0_arid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARID),
        .maxigp0_arlen(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARLEN),
        .maxigp0_arlock(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARLOCK),
        .maxigp0_arprot(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARPROT),
        .maxigp0_arqos(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARQOS),
        .maxigp0_arready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARREADY),
        .maxigp0_arsize(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARSIZE),
        .maxigp0_aruser(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARUSER),
        .maxigp0_arvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_ARVALID),
        .maxigp0_awaddr(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWADDR),
        .maxigp0_awburst(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWBURST),
        .maxigp0_awcache(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWCACHE),
        .maxigp0_awid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWID),
        .maxigp0_awlen(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWLEN),
        .maxigp0_awlock(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWLOCK),
        .maxigp0_awprot(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWPROT),
        .maxigp0_awqos(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWQOS),
        .maxigp0_awready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWREADY),
        .maxigp0_awsize(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWSIZE),
        .maxigp0_awuser(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWUSER),
        .maxigp0_awvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_AWVALID),
        .maxigp0_bid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BID),
        .maxigp0_bready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BREADY),
        .maxigp0_bresp(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BRESP),
        .maxigp0_bvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_BVALID),
        .maxigp0_rdata(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RDATA),
        .maxigp0_rid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RID),
        .maxigp0_rlast(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RLAST),
        .maxigp0_rready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RREADY),
        .maxigp0_rresp(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RRESP),
        .maxigp0_rvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_RVALID),
        .maxigp0_wdata(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WDATA),
        .maxigp0_wlast(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WLAST),
        .maxigp0_wready(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WREADY),
        .maxigp0_wstrb(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WSTRB),
        .maxigp0_wvalid(zynq_ultra_ps_e_0_M_AXI_HPM0_FPD_WVALID),
        .maxigp1_arready(1'b0),
        .maxigp1_awready(1'b0),
        .maxigp1_bid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .maxigp1_bresp({1'b0,1'b0}),
        .maxigp1_bvalid(1'b0),
        .maxigp1_rdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .maxigp1_rid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .maxigp1_rlast(1'b0),
        .maxigp1_rresp({1'b0,1'b0}),
        .maxigp1_rvalid(1'b0),
        .maxigp1_wready(1'b0),
        .maxihpm0_fpd_aclk(zynq_ultra_ps_e_0_pl_clk0),
        .maxihpm1_fpd_aclk(zynq_ultra_ps_e_0_pl_clk0),
        .pl_clk0(zynq_ultra_ps_e_0_pl_clk0),
        .pl_ps_irq0(1'b0),
        .pl_resetn0(zynq_ultra_ps_e_0_pl_resetn0),
        .saxigp0_araddr(axi_ddr_sc_M00_AXI_ARADDR),
        .saxigp0_arburst(axi_ddr_sc_M00_AXI_ARBURST),
        .saxigp0_arcache(axi_ddr_sc_M00_AXI_ARCACHE),
        .saxigp0_arid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .saxigp0_arlen(axi_ddr_sc_M00_AXI_ARLEN),
        .saxigp0_arlock(axi_ddr_sc_M00_AXI_ARLOCK),
        .saxigp0_arprot(axi_ddr_sc_M00_AXI_ARPROT),
        .saxigp0_arqos(axi_ddr_sc_M00_AXI_ARQOS),
        .saxigp0_arready(axi_ddr_sc_M00_AXI_ARREADY),
        .saxigp0_arsize(axi_ddr_sc_M00_AXI_ARSIZE),
        .saxigp0_aruser(1'b0),
        .saxigp0_arvalid(axi_ddr_sc_M00_AXI_ARVALID),
        .saxigp0_awaddr(axi_ddr_sc_M00_AXI_AWADDR),
        .saxigp0_awburst(axi_ddr_sc_M00_AXI_AWBURST),
        .saxigp0_awcache(axi_ddr_sc_M00_AXI_AWCACHE),
        .saxigp0_awid({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .saxigp0_awlen(axi_ddr_sc_M00_AXI_AWLEN),
        .saxigp0_awlock(axi_ddr_sc_M00_AXI_AWLOCK),
        .saxigp0_awprot(axi_ddr_sc_M00_AXI_AWPROT),
        .saxigp0_awqos(axi_ddr_sc_M00_AXI_AWQOS),
        .saxigp0_awready(axi_ddr_sc_M00_AXI_AWREADY),
        .saxigp0_awsize(axi_ddr_sc_M00_AXI_AWSIZE),
        .saxigp0_awuser(1'b0),
        .saxigp0_awvalid(axi_ddr_sc_M00_AXI_AWVALID),
        .saxigp0_bready(axi_ddr_sc_M00_AXI_BREADY),
        .saxigp0_bresp(axi_ddr_sc_M00_AXI_BRESP),
        .saxigp0_bvalid(axi_ddr_sc_M00_AXI_BVALID),
        .saxigp0_rdata(axi_ddr_sc_M00_AXI_RDATA),
        .saxigp0_rlast(axi_ddr_sc_M00_AXI_RLAST),
        .saxigp0_rready(axi_ddr_sc_M00_AXI_RREADY),
        .saxigp0_rresp(axi_ddr_sc_M00_AXI_RRESP),
        .saxigp0_rvalid(axi_ddr_sc_M00_AXI_RVALID),
        .saxigp0_wdata(axi_ddr_sc_M00_AXI_WDATA),
        .saxigp0_wlast(axi_ddr_sc_M00_AXI_WLAST),
        .saxigp0_wready(axi_ddr_sc_M00_AXI_WREADY),
        .saxigp0_wstrb(axi_ddr_sc_M00_AXI_WSTRB),
        .saxigp0_wvalid(axi_ddr_sc_M00_AXI_WVALID),
        .saxihpc0_fpd_aclk(zynq_ultra_ps_e_0_pl_clk0));
endmodule
