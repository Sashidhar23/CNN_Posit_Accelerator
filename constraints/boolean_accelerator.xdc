# Real Digital Boolean board constraints for boolean_accelerator_wrapper.
# Device: xc7s50csga324-1. Board oscillator: 100 MHz, active-high GPIO.

set_property PACKAGE_PIN F14 [get_ports mclk]
set_property IOSTANDARD LVCMOS33 [get_ports mclk]
# Clock Wizard constrains this input to 100 MHz in its generated XDC.

# BTN0 is an active-high asynchronous reset request.
set_property PACKAGE_PIN J2 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# LD3:LD0 display the inferred class. LD4..LD7 show runtime status.
set_property PACKAGE_PIN G1 [get_ports {led_class[0]}]
set_property PACKAGE_PIN G2 [get_ports {led_class[1]}]
set_property PACKAGE_PIN F1 [get_ports {led_class[2]}]
set_property PACKAGE_PIN F2 [get_ports {led_class[3]}]
set_property PACKAGE_PIN E1 [get_ports led_busy]
set_property PACKAGE_PIN E2 [get_ports led_done]
set_property PACKAGE_PIN E3 [get_ports led_error]
set_property PACKAGE_PIN E5 [get_ports led_clock_locked]
set_property IOSTANDARD LVCMOS33 \
    [get_ports {led_class[*] led_busy led_done led_error led_clock_locked}]
set_property DRIVE 8 \
    [get_ports {led_class[*] led_busy led_done led_error led_clock_locked}]
set_property SLEW SLOW \
    [get_ports {led_class[*] led_busy led_done led_error led_clock_locked}]

# S25FL128S QSPI. CCLK is driven through STARTUPE2 inside AXI Quad SPI.
set_property PACKAGE_PIN K17 [get_ports qspi_io0_io]
set_property PACKAGE_PIN K18 [get_ports qspi_io1_io]
set_property PACKAGE_PIN L14 [get_ports qspi_io2_io]
set_property PACKAGE_PIN M15 [get_ports qspi_io3_io]
set_property PACKAGE_PIN M13 [get_ports {qspi_ss_io[0]}]
set_property IOSTANDARD LVCMOS33 \
    [get_ports {qspi_io0_io qspi_io1_io qspi_io2_io qspi_io3_io qspi_ss_io[0]}]
set_property PULLUP true \
    [get_ports {qspi_io0_io qspi_io1_io qspi_io2_io qspi_io3_io qspi_ss_io[0]}]

# AXI Quad SPI XIP timing, SCK ratio 2, with SCK routed through STARTUPE2.
# Values are worst-case limits from DS189 for Spartan-7 -1 and the
# S25FL128S data sheet. The 0.5 ns trace budget is conservative for this PCB.
set qspi_cclk_delay 7.5
set qspi_tco_max 14.5
set qspi_tco_min 2.0
set qspi_tsu 5.0
set qspi_th 4.0
set qspi_tcss 10.0
set qspi_tcsh 3.0
set qspi_data_trace_max 0.5
set qspi_data_trace_min 0.0
set qspi_clk_trace_max 0.5
set qspi_clk_trace_min 0.0

set qspi_core [get_cells -hier -filter {X_CORE_INFO =~ axi_quad_spi,*}]
set qspi_ext_clk_pin [get_pins -filter {REF_PIN_NAME == ext_spi_clk} -of_objects $qspi_core]
set qspi_startup_clk_pin [get_pins -hier -filter {REF_PIN_NAME == USRCCLKO}]
set qspi_sck_reg_clk_pin [get_pins -hier -filter {NAME =~ *SCK_O_reg_reg/C}]
set qspi_data_ports \
    [get_ports {qspi_io0_io qspi_io1_io qspi_io2_io qspi_io3_io}]
set qspi_ss_port [get_ports {qspi_ss_io[0]}]

# The routed STARTUPE2 feed is 3.525 ns; 4.0 ns keeps a checked bound with
# margin while remaining comfortably inside the 25 MHz SCK timing budget.
set_max_delay 4.0 -from $qspi_sck_reg_clk_pin \
    -to $qspi_startup_clk_pin -datapath_only
set_min_delay 0.1 -from $qspi_sck_reg_clk_pin \
    -to $qspi_startup_clk_pin

create_generated_clock -name qspi_sck -source $qspi_ext_clk_pin \
    -edges {3 5 7} \
    -edge_shift [list $qspi_cclk_delay $qspi_cclk_delay $qspi_cclk_delay] \
    $qspi_startup_clk_pin

set_input_delay -clock qspi_sck -clock_fall -max \
    [expr {$qspi_tco_max + $qspi_data_trace_max + $qspi_clk_trace_max}] \
    $qspi_data_ports
set_input_delay -clock qspi_sck -clock_fall -min \
    [expr {$qspi_tco_min + $qspi_data_trace_min + $qspi_clk_trace_min}] \
    $qspi_data_ports

set_output_delay -clock qspi_sck -max \
    [expr {$qspi_tsu + $qspi_data_trace_max - $qspi_clk_trace_min}] \
    $qspi_data_ports
set_output_delay -clock qspi_sck -min \
    [expr {$qspi_data_trace_min - $qspi_th - $qspi_clk_trace_max}] \
    $qspi_data_ports
set_output_delay -clock qspi_sck -max \
    [expr {$qspi_tcss + $qspi_data_trace_max - $qspi_clk_trace_min}] \
    $qspi_ss_port
set_output_delay -clock qspi_sck -min \
    [expr {$qspi_data_trace_min - $qspi_tcsh - $qspi_clk_trace_max}] \
    $qspi_ss_port

set_multicycle_path 2 -setup -from [get_clocks qspi_sck] \
    -to [get_clocks -of_objects $qspi_ext_clk_pin]
set_multicycle_path 1 -hold -end -from [get_clocks qspi_sck] \
    -to [get_clocks -of_objects $qspi_ext_clk_pin]
set_multicycle_path 2 -setup -start \
    -from [get_clocks -of_objects $qspi_ext_clk_pin] -to [get_clocks qspi_sck]
set_multicycle_path 1 -hold \
    -from [get_clocks -of_objects $qspi_ext_clk_pin] -to [get_clocks qspi_sck]

# Reset is synchronized by proc_sys_reset. LEDs are human-visible outputs.
set_false_path -from [get_ports reset]
set_false_path -to \
    [get_ports {led_class[*] led_busy led_done led_error led_clock_locked}]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
