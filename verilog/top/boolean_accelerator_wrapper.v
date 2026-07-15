//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.2 (win64) Build 6299465 Fri Nov 14 19:35:11 GMT 2025
//Date        : Tue Jul 14 18:34:41 2026
//Host        : LAPTOP-Q67ALKPQ running 64-bit major release  (build 9200)
//Command     : generate_target boolean_accelerator_wrapper.bd
//Design      : boolean_accelerator_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module boolean_accelerator_wrapper
   (led_busy,
    led_class,
    led_clock_locked,
    led_done,
    led_error,
    mclk,
    qspi_io0_io,
    qspi_io1_io,
    qspi_io2_io,
    qspi_io3_io,
    qspi_ss_io,
    reset);
  output led_busy;
  output [3:0]led_class;
  output led_clock_locked;
  output led_done;
  output led_error;
  input mclk;
  inout qspi_io0_io;
  inout qspi_io1_io;
  inout qspi_io2_io;
  inout qspi_io3_io;
  inout [0:0]qspi_ss_io;
  input reset;

  wire led_busy;
  wire [3:0]led_class;
  wire led_clock_locked;
  wire led_done;
  wire led_error;
  wire mclk;
  wire qspi_io0_i;
  wire qspi_io0_io;
  wire qspi_io0_o;
  wire qspi_io0_t;
  wire qspi_io1_i;
  wire qspi_io1_io;
  wire qspi_io1_o;
  wire qspi_io1_t;
  wire qspi_io2_i;
  wire qspi_io2_io;
  wire qspi_io2_o;
  wire qspi_io2_t;
  wire qspi_io3_i;
  wire qspi_io3_io;
  wire qspi_io3_o;
  wire qspi_io3_t;
  wire [0:0]qspi_ss_i_0;
  wire [0:0]qspi_ss_io_0;
  wire [0:0]qspi_ss_o_0;
  wire qspi_ss_t;
  wire reset;

  boolean_accelerator boolean_accelerator_i
       (.led_busy(led_busy),
        .led_class(led_class),
        .led_clock_locked(led_clock_locked),
        .led_done(led_done),
        .led_error(led_error),
        .mclk(mclk),
        .qspi_io0_i(qspi_io0_i),
        .qspi_io0_o(qspi_io0_o),
        .qspi_io0_t(qspi_io0_t),
        .qspi_io1_i(qspi_io1_i),
        .qspi_io1_o(qspi_io1_o),
        .qspi_io1_t(qspi_io1_t),
        .qspi_io2_i(qspi_io2_i),
        .qspi_io2_o(qspi_io2_o),
        .qspi_io2_t(qspi_io2_t),
        .qspi_io3_i(qspi_io3_i),
        .qspi_io3_o(qspi_io3_o),
        .qspi_io3_t(qspi_io3_t),
        .qspi_ss_i(qspi_ss_i_0),
        .qspi_ss_o(qspi_ss_o_0),
        .qspi_ss_t(qspi_ss_t),
        .reset(reset));
  IOBUF qspi_io0_iobuf
       (.I(qspi_io0_o),
        .IO(qspi_io0_io),
        .O(qspi_io0_i),
        .T(qspi_io0_t));
  IOBUF qspi_io1_iobuf
       (.I(qspi_io1_o),
        .IO(qspi_io1_io),
        .O(qspi_io1_i),
        .T(qspi_io1_t));
  IOBUF qspi_io2_iobuf
       (.I(qspi_io2_o),
        .IO(qspi_io2_io),
        .O(qspi_io2_i),
        .T(qspi_io2_t));
  IOBUF qspi_io3_iobuf
       (.I(qspi_io3_o),
        .IO(qspi_io3_io),
        .O(qspi_io3_i),
        .T(qspi_io3_t));
  IOBUF qspi_ss_iobuf_0
       (.I(qspi_ss_o_0),
        .IO(qspi_ss_io[0]),
        .O(qspi_ss_i_0),
        .T(qspi_ss_t));
endmodule
