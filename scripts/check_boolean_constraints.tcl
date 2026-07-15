set repo_dir [file normalize [file join [file dirname [info script]] ..]]
set build_root D:/BooleanBuild/posit_cnn_accelerator_boolean
if {[info exists ::env(BOOLEAN_BUILD_DIR)]} {
    set build_root [string map {\\ /} $::env(BOOLEAN_BUILD_DIR)]
}
open_checkpoint [file join $build_root posit_cnn_accelerator_boolean.runs impl_1 \
    boolean_accelerator_wrapper_routed.dcp]
read_xdc [file join $repo_dir constraints boolean_accelerator.xdc]

report_timing_summary -delay_type min_max -check_timing_verbose \
    -file [file join $build_root boolean_constraints_timing_check.rpt]
report_drc -file [file join $build_root boolean_constraints_drc_check.rpt]

close_design
exit
