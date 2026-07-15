# Create a Real Digital Boolean-board deployment project.
# Required: POSIT_CNN_PROJECT_DIR. Optional: BOOLEAN_BUILD_DIR, BOOLEAN_USE_QUIRE.

if {![info exists ::env(POSIT_CNN_PROJECT_DIR)]} {
    error "Set POSIT_CNN_PROJECT_DIR to the accelerator repository root."
}
set repo_dir [string map {\\ /} $::env(POSIT_CNN_PROJECT_DIR)]
set build_root D:/BooleanBuild/posit_cnn_accelerator_boolean
if {[info exists ::env(BOOLEAN_BUILD_DIR)]} {
    set build_root [string map {\\ /} $::env(BOOLEAN_BUILD_DIR)]
}
set use_quire 1
if {[info exists ::env(BOOLEAN_USE_QUIRE)]} {
    set use_quire $::env(BOOLEAN_USE_QUIRE)
}
if {$use_quire ni {0 1}} {
    error "BOOLEAN_USE_QUIRE must be 0 or 1."
}

if {[info exists ::env(XILINX_TCLAPP_REPO)]} {
    set tclapp_init [file join $::env(XILINX_TCLAPP_REPO) support appinit]
    set tcllib_paths [list $tclapp_init]
    lappend auto_path $tclapp_init
    foreach app_dir [glob -nocomplain \
        [file join $::env(XILINX_TCLAPP_REPO) tclapp * *]] {
        if {[file isdirectory $app_dir]} {
            lappend auto_path $app_dir
            lappend tcllib_paths $app_dir
        }
    }
    set ::env(TCLLIBPATH) $tcllib_paths
    package require ::tclapp::support::appinit 1.2
}

set project_name posit_cnn_accelerator_boolean
file mkdir $build_root
create_project -force $project_name $build_root -part xc7s50csga324-1
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

if {[file isdirectory [file join $repo_dir rtl]]} {
    set rtl_files [glob -nocomplain \
        [file join $repo_dir rtl cnn *.v] \
        [file join $repo_dir rtl Controller *.v] \
        [file join $repo_dir rtl pe *.v] \
        [file join $repo_dir rtl posit *.v] \
        [file join $repo_dir rtl systolic *.v]]
} else {
    # GitHub layout: include active RTL only, excluding testbenches and the
    # legacy ZCU104 generated block-design sources under verilog/top.
    set rtl_files [glob -nocomplain \
        [file join $repo_dir verilog activation posit_relu2d.v] \
        [file join $repo_dir verilog adder posit_adder.v] \
        [file join $repo_dir verilog decoder posit_decoder.v] \
        [file join $repo_dir verilog encoder posit_encoder.v] \
        [file join $repo_dir verilog integrated reduced_vgg16_mnist*.v] \
        [file join $repo_dir verilog multiplier posit_multiplier.v] \
        [file join $repo_dir verilog pe pe*.v] \
        [file join $repo_dir verilog pooling posit_maxpool2d.v] \
        [file join $repo_dir verilog posit posit*.v] \
        [file join $repo_dir verilog posit quire_to_posit.v] \
        [file join $repo_dir verilog systolic systolic*.v] \
        [file join $repo_dir verilog top boolean_batch_controller.v] \
        [file join $repo_dir verilog top cnn_zynq_axi_master_wrapper.v]]
    set active_rtl_files {}
    foreach rtl_file $rtl_files {
        if {![string match {tb_*} [file tail $rtl_file]]} {
            lappend active_rtl_files $rtl_file
        }
    }
    set rtl_files $active_rtl_files
}
if {[llength $rtl_files] == 0} {
    error "No RTL files found under $repo_dir/rtl."
}

# Snapshot into the build directory so generated IP never depends on a path
# containing spaces and so the Vivado project records the exact deployed RTL.
set snapshot_dir [file join $build_root imported_sources]
set snapshot_rtl_dir [file join $snapshot_dir rtl]
file mkdir $snapshot_rtl_dir
set snapshot_rtl_files {}
foreach rtl_file $rtl_files {
    set rtl_group [file tail [file dirname $rtl_file]]
    set rtl_group_dir [file join $snapshot_rtl_dir $rtl_group]
    file mkdir $rtl_group_dir
    set snapshot_file [file join $rtl_group_dir [file tail $rtl_file]]
    file copy -force $rtl_file $snapshot_file
    lappend snapshot_rtl_files $snapshot_file
}
set snapshot_constraint_dir [file join $snapshot_dir constraints]
file mkdir $snapshot_constraint_dir
set snapshot_xdc [file join $snapshot_constraint_dir boolean_accelerator.xdc]
file copy -force [file join $repo_dir constraints boolean_accelerator.xdc] $snapshot_xdc

add_files -norecurse $snapshot_rtl_files
add_files -fileset constrs_1 -norecurse $snapshot_xdc
update_compile_order -fileset sources_1

create_bd_design boolean_accelerator

# The 100 MHz board oscillator supplies a 5 MHz accelerator/AXI clock and a
# 50 MHz AXI Quad SPI reference clock. XIP divides the latter to 25 MHz SCK.
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.NUM_OUT_CLKS {2} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {5.000} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50.000} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_HIGH}] [get_bd_cells clk_wiz_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_core
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_zero
set_property CONFIG.CONST_VAL {0} [get_bd_cells const_zero]

# A small hardware controller runs the ten-image accuracy batch automatically.
create_bd_cell -type module -reference boolean_batch_controller batch_ctrl_0
set_property -dict [list \
    CONFIG.CONTROL_BASE {2147483648} \
    CONFIG.IMAGE_BASE {11962316} \
    CONFIG.IMAGE_BYTES {784} \
    CONFIG.IMAGE_COUNT {10}] [get_bd_cells batch_ctrl_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ctrl
set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {2}] [get_bd_cells axi_ctrl]

# The onboard 16 MiB S25FL128S is a Spansion flash. XIP exposes its contents as
# a read-only, 24-bit-addressed, 32-bit AXI memory to the accelerator.
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 qspi_xip
set_property -dict [list \
    CONFIG.C_XIP_MODE {1} \
    CONFIG.C_XIP_PERF_MODE {1} \
    CONFIG.C_SPI_MODE {2} \
    CONFIG.C_SPI_MEMORY {3} \
    CONFIG.C_SPI_MEM_ADDR_BITS {24} \
    CONFIG.C_USE_STARTUP {1}] [get_bd_cells qspi_xip]

create_bd_cell -type module -reference cnn_zynq_axi_master_wrapper cnn_accel_0
set_property -dict [list \
    CONFIG.USE_QUIRE $use_quire \
    CONFIG.C_M_AXI_DATA_WIDTH {32} \
    CONFIG.C_M_AXI_ADDR_WIDTH {24} \
    CONFIG.C_M_AXI_ID_WIDTH {1} \
    CONFIG.CLASS_W {4} \
    CONFIG.DEFAULT_WEIGHT_BASE {4194304} \
    CONFIG.DEFAULT_BIAS_BASE {11959360} \
    CONFIG.DEFAULT_IMAGE_BASE {11962316}] [get_bd_cells cnn_accel_0]

# External board ports.
make_bd_pins_external [get_bd_pins clk_wiz_0/clk_in1]
set_property name mclk [get_bd_ports clk_in1_0]
create_bd_port -dir I -type rst reset
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports reset]
make_bd_intf_pins_external [get_bd_intf_pins qspi_xip/SPI_0]
set_property name qspi [get_bd_intf_ports SPI_0_0]
create_bd_port -dir O -from 3 -to 0 led_class
create_bd_port -dir O led_busy
create_bd_port -dir O led_done
create_bd_port -dir O led_error
create_bd_port -dir O led_clock_locked

# Clock and reset trees.
connect_bd_net [get_bd_ports reset] [get_bd_pins clk_wiz_0/reset] \
    [get_bd_pins rst_core/ext_reset_in]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] \
    [get_bd_pins rst_core/slowest_sync_clk] \
    [get_bd_pins batch_ctrl_0/clk] \
    [get_bd_pins axi_ctrl/ACLK] [get_bd_pins axi_ctrl/S00_ACLK] \
    [get_bd_pins axi_ctrl/M00_ACLK] [get_bd_pins axi_ctrl/M01_ACLK] \
    [get_bd_pins qspi_xip/s_axi_aclk] [get_bd_pins qspi_xip/s_axi4_aclk] \
    [get_bd_pins cnn_accel_0/aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins qspi_xip/ext_spi_clk]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins rst_core/dcm_locked] \
    [get_bd_ports led_clock_locked]
connect_bd_net [get_bd_pins const_zero/dout] \
    [get_bd_pins rst_core/aux_reset_in] [get_bd_pins rst_core/mb_debug_sys_rst]
connect_bd_net [get_bd_pins rst_core/peripheral_aresetn] \
    [get_bd_pins axi_ctrl/ARESETN] [get_bd_pins axi_ctrl/S00_ARESETN] \
    [get_bd_pins axi_ctrl/M00_ARESETN] [get_bd_pins axi_ctrl/M01_ARESETN] \
    [get_bd_pins qspi_xip/s_axi_aresetn] [get_bd_pins qspi_xip/s_axi4_aresetn] \
    [get_bd_pins cnn_accel_0/aresetn]
connect_bd_net [get_bd_pins rst_core/peripheral_reset] \
    [get_bd_pins batch_ctrl_0/reset]

# The autonomous controller writes the accelerator's AXI-Lite registers.
connect_bd_intf_net [get_bd_intf_pins batch_ctrl_0/m_axi] \
    [get_bd_intf_pins axi_ctrl/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_ctrl/M00_AXI] \
    [get_bd_intf_pins cnn_accel_0/s_axi]
connect_bd_intf_net [get_bd_intf_pins axi_ctrl/M01_AXI] \
    [get_bd_intf_pins qspi_xip/AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins cnn_accel_0/m_axi] \
    [get_bd_intf_pins qspi_xip/AXI_FULL]

connect_bd_net [get_bd_pins cnn_accel_0/class_result] \
    [get_bd_pins batch_ctrl_0/accel_class]
connect_bd_net [get_bd_pins cnn_accel_0/done] \
    [get_bd_pins batch_ctrl_0/accel_done]
connect_bd_net [get_bd_pins cnn_accel_0/error] \
    [get_bd_pins batch_ctrl_0/accel_error]
connect_bd_net [get_bd_pins batch_ctrl_0/display_value] [get_bd_ports led_class]
connect_bd_net [get_bd_pins batch_ctrl_0/batch_busy] [get_bd_ports led_busy]
connect_bd_net [get_bd_pins batch_ctrl_0/batch_done] [get_bd_ports led_done]
connect_bd_net [get_bd_pins batch_ctrl_0/batch_error] [get_bd_ports led_error]

assign_bd_address
set_property offset 0x80000000 \
    [get_bd_addr_segs batch_ctrl_0/m_axi/SEG_cnn_accel_0_reg0]
set_property range 4K \
    [get_bd_addr_segs batch_ctrl_0/m_axi/SEG_cnn_accel_0_reg0]
set_property offset 0x44A00000 \
    [get_bd_addr_segs batch_ctrl_0/m_axi/SEG_qspi_xip_Reg]
set_property range 4K \
    [get_bd_addr_segs batch_ctrl_0/m_axi/SEG_qspi_xip_Reg]
set_property offset 0x00000000 \
    [get_bd_addr_segs cnn_accel_0/m_axi/SEG_qspi_xip_Mem0]
set_property range 16M \
    [get_bd_addr_segs cnn_accel_0/m_axi/SEG_qspi_xip_Mem0]

validate_bd_design
save_bd_design
set bd_file [get_files boolean_accelerator.bd]
set_property synth_checkpoint_mode None $bd_file
generate_target all $bd_file
make_wrapper -files $bd_file -top
set wrapper_file [file join $build_root ${project_name}.gen sources_1 bd \
    boolean_accelerator hdl boolean_accelerator_wrapper.v]
add_files -norecurse $wrapper_file
set_property top boolean_accelerator_wrapper [current_fileset]
update_compile_order -fileset sources_1

set_property strategy Flow_AreaOptimized_high [get_runs synth_1]
set_property strategy Flow_RuntimeOptimized [get_runs impl_1]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

puts "Created [file join $build_root ${project_name}.xpr]"
puts "Boolean deployment mode USE_QUIRE=$use_quire"
