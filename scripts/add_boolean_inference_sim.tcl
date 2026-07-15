# Add the end-to-end ten-image inference test to an existing Boolean project.
if {![info exists ::env(POSIT_CNN_PROJECT_DIR)]} {
    error "Set POSIT_CNN_PROJECT_DIR to the accelerator repository root."
}

set repo_dir [string map {\\ /} $::env(POSIT_CNN_PROJECT_DIR)]
set build_root D:/BooleanBuild/posit_cnn_accelerator_boolean
if {[info exists ::env(BOOLEAN_BUILD_DIR)]} {
    set build_root [string map {\\ /} $::env(BOOLEAN_BUILD_DIR)]
}
set project_file [file join $build_root posit_cnn_accelerator_boolean.xpr]
set payload_mem [file join $build_root flash boolean_model_images.mem]

if {![file exists $project_file]} {
    error "Boolean Vivado project not found: $project_file"
}
if {![file exists $payload_mem]} {
    error "Simulation flash payload not found: $payload_mem"
}

open_project $project_file
set sim_snapshot_dir [file join $build_root imported_sources sim]
file mkdir $sim_snapshot_dir

if {[file exists [file join $repo_dir tb cnn tb_boolean_accelerator_10_image_inference.v]]} {
    set tb_src [file join $repo_dir tb cnn tb_boolean_accelerator_10_image_inference.v]
    set labels_src [file join $repo_dir tb cnn mnist_expected_labels.vh]
} else {
    set tb_src [file join $repo_dir verilog top tb_boolean_accelerator_10_image_inference.v]
    set labels_src [file join $repo_dir verilog integrated mnist_expected_labels.vh]
}
set tb_dst [file join $sim_snapshot_dir [file tail $tb_src]]
set labels_dst [file join $sim_snapshot_dir [file tail $labels_src]]
file copy -force $tb_src $tb_dst
file copy -force $labels_src $labels_dst

add_files -fileset sim_1 -norecurse [list $tb_dst $labels_dst $payload_mem]
set_property file_type {Verilog Header} [get_files $labels_dst]
set_property file_type {Memory File} [get_files $payload_mem]
set_property include_dirs [list $sim_snapshot_dir] [get_filesets sim_1]
set_property top tb_boolean_accelerator_10_image_inference [get_filesets sim_1]
set_property xsim.elaborate.debug_level off [get_filesets sim_1]
set_property xsim.simulate.log_all_signals false [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
update_compile_order -fileset sim_1
close_project

puts "Added ten-image Boolean inference simulation."
puts "Simulation top: tb_boolean_accelerator_10_image_inference"
