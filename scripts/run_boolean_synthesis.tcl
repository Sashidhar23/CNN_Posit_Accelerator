# Run synthesis only for the Real Digital Boolean-board deployment project.

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
set report_dir [file join $build_root reports]
file mkdir $report_dir
set_param general.maxThreads 10
update_compile_order -fileset sources_1
synth_design -top boolean_accelerator_wrapper -part xc7s50csga324-1 \
    -directive AreaOptimized_high
write_checkpoint -force [file join $build_root boolean_post_synth.dcp]
report_utilization -file [file join $report_dir utilization_synth.rpt]
report_timing_summary -delay_type max -max_paths 20 \
    -file [file join $report_dir timing_synth.rpt]
report_drc -file [file join $report_dir drc_synth.rpt]
puts "Boolean-board direct synthesis completed."
puts "UTILIZATION=[file join $report_dir utilization_synth.rpt]"
