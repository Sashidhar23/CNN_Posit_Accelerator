# Run inside the already-open Boolean Vivado project.
set build_root D:/BooleanBuild/posit_cnn_accelerator_boolean
set sim_dir [file join $build_root imported_sources sim]
set tb_file [file join $sim_dir tb_boolean_accelerator_10_image_inference.v]
set labels_file [file join $sim_dir mnist_expected_labels.vh]
set payload_file [file join $build_root flash boolean_model_images.mem]

foreach required_file [list $tb_file $labels_file $payload_file] {
    if {![file exists $required_file]} {
        error "Required simulation file is missing: $required_file"
    }
}

add_files -fileset sim_1 -norecurse [list $tb_file $labels_file $payload_file]
set_property file_type {Verilog Header} [get_files $labels_file]
set_property file_type {Memory File} [get_files $payload_file]
set_property include_dirs [list $sim_dir] [get_filesets sim_1]
set_property top tb_boolean_accelerator_10_image_inference [get_filesets sim_1]
set_property xsim.elaborate.debug_level off [get_filesets sim_1]
set_property xsim.simulate.log_all_signals false [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
update_compile_order -fileset sim_1

puts "REFRESH_OK: [get_property top [get_filesets sim_1]]"
puts "REFRESH_FILE: [get_files -of_objects [get_filesets sim_1] *tb_boolean_accelerator_10_image_inference.v]"
