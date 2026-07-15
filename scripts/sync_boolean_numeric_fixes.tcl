# Refresh an existing Boolean-board project with the repository's corrected RTL.
# Required: POSIT_CNN_PROJECT_DIR. Optional: BOOLEAN_BUILD_DIR.

if {![info exists ::env(POSIT_CNN_PROJECT_DIR)]} {
    error "Set POSIT_CNN_PROJECT_DIR to the accelerator repository root."
}

set repo_dir [string map {\\ /} $::env(POSIT_CNN_PROJECT_DIR)]
set build_root D:/BooleanBuild/posit_cnn_accelerator_boolean
if {[info exists ::env(BOOLEAN_BUILD_DIR)]} {
    set build_root [string map {\\ /} $::env(BOOLEAN_BUILD_DIR)]
}

set project_file [file join $build_root posit_cnn_accelerator_boolean.xpr]
if {![file exists $project_file]} {
    error "Boolean project was not found at $project_file."
}
file copy -force $project_file ${project_file}.pre_numeric_sync

set opened_here 0
if {[llength [get_projects -quiet]] == 0} {
    open_project $project_file
    set opened_here 1
}

set snapshot_dir [file join $build_root imported_sources]
set snapshot_rtl_dir [file join $snapshot_dir rtl]
if {[file isdirectory [file join $repo_dir rtl]]} {
    set rtl_files [glob -nocomplain \
        [file join $repo_dir rtl cnn *.v] \
        [file join $repo_dir rtl Controller *.v] \
        [file join $repo_dir rtl pe *.v] \
        [file join $repo_dir rtl posit *.v] \
        [file join $repo_dir rtl systolic *.v]]
    set source_tb [file join $repo_dir tb cnn tb_boolean_accelerator_10_image_inference.v]
    set source_labels [file join $repo_dir tb cnn mnist_expected_labels.vh]
} else {
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
    set source_tb [file join $repo_dir verilog top tb_boolean_accelerator_10_image_inference.v]
    set source_labels [file join $repo_dir verilog integrated mnist_expected_labels.vh]
}
if {[llength $rtl_files] == 0} {
    error "No RTL files found under $repo_dir/rtl."
}

set snapshot_rtl_files {}
foreach rtl_file $rtl_files {
    set rtl_group [file tail [file dirname $rtl_file]]
    set rtl_group_dir [file join $snapshot_rtl_dir $rtl_group]
    file mkdir $rtl_group_dir
    set snapshot_file [file join $rtl_group_dir [file tail $rtl_file]]
    file copy -force $rtl_file $snapshot_file
    lappend snapshot_rtl_files $snapshot_file
}
add_files -fileset sources_1 -norecurse $snapshot_rtl_files
update_compile_order -fileset sources_1

set snapshot_sim_dir [file join $snapshot_dir sim]
file mkdir $snapshot_sim_dir
set snapshot_tb [file join $snapshot_sim_dir [file tail $source_tb]]
set snapshot_labels [file join $snapshot_sim_dir [file tail $source_labels]]
file copy -force $source_tb $snapshot_tb
file copy -force $source_labels $snapshot_labels
add_files -fileset sim_1 -norecurse [list $snapshot_tb $snapshot_labels]
set_property file_type {Verilog Header} [get_files $snapshot_labels]
set_property include_dirs [list $snapshot_sim_dir] [get_filesets sim_1]
set_property top tb_boolean_accelerator_10_image_inference [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "Refreshed Boolean RTL snapshot from $repo_dir"
puts "Added exact arithmetic and full-quire modules to sources_1."
puts "Refreshed the ten-image inference testbench in sim_1."

if {$opened_here} {
    close_project
}
