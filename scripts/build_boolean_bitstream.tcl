# Build and report the Boolean-board project, then create a combined QSPI MCS.

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

set build_root D:/BooleanBuild/posit_cnn_accelerator_boolean
if {[info exists ::env(BOOLEAN_BUILD_DIR)]} {
    set build_root [string map {\\ /} $::env(BOOLEAN_BUILD_DIR)]
}
set xpr [file join $build_root posit_cnn_accelerator_boolean.xpr]
if {![file exists $xpr]} {
    error "Boolean-board project not found: $xpr"
}

open_project $xpr
file mkdir [file join $build_root reports]
set_param general.maxThreads 10
set synth_checkpoint [file join $build_root boolean_post_synth.dcp]
set reuse_synth 0
if {[info exists ::env(BOOLEAN_REUSE_SYNTH)]} {
    set reuse_synth $::env(BOOLEAN_REUSE_SYNTH)
}
if {$reuse_synth && [file exists $synth_checkpoint]} {
    open_checkpoint $synth_checkpoint
    puts "Reusing $synth_checkpoint"
} else {
    update_compile_order -fileset sources_1
    synth_design -top boolean_accelerator_wrapper -part xc7s50csga324-1 \
        -directive AreaOptimized_high
    write_checkpoint -force $synth_checkpoint
}
report_utilization -file [file join $build_root reports utilization_synth.rpt]
report_timing_summary -delay_type max -max_paths 20 \
    -file [file join $build_root reports timing_synth.rpt]

opt_design
place_design -directive RuntimeOptimized
route_design -directive RuntimeOptimized
write_checkpoint -force [file join $build_root boolean_post_route.dcp]
report_utilization -file [file join $build_root reports utilization_implemented.rpt]
report_timing_summary -delay_type min_max -max_paths 50 \
    -file [file join $build_root reports timing_implemented.rpt]
report_drc -file [file join $build_root reports drc_implemented.rpt]
report_methodology -file [file join $build_root reports methodology_implemented.rpt]

set bit_file [file join $build_root boolean_accelerator_wrapper.bit]
write_bitstream -force -bin_file $bit_file
set payload_file [file join $build_root flash boolean_model_images.bin]
set mcs_file [file join $build_root posit_cnn_accelerator_boolean.mcs]
if {![file exists $bit_file]} {
    error "Bitstream was not generated: $bit_file"
}
if {![file exists $payload_file]} {
    error "Flash payload was not generated: $payload_file"
}
write_cfgmem -force -format mcs -size 16 -interface SPIx4 \
    -loadbit "up 0x00000000 $bit_file" \
    -loaddata "up 0x00400000 $payload_file" \
    -file $mcs_file

puts "Boolean-board build complete."
puts "BIT=$bit_file"
puts "MCS=$mcs_file"
