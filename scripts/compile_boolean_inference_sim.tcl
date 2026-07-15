set build_root D:/BooleanBuild/posit_cnn_accelerator_boolean
if {[info exists ::env(BOOLEAN_BUILD_DIR)]} {
    set build_root [string map {\\ /} $::env(BOOLEAN_BUILD_DIR)]
}

open_project [file join $build_root posit_cnn_accelerator_boolean.xpr]
set_property top tb_boolean_accelerator_10_image_inference [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral -step compile
launch_simulation -simset sim_1 -mode behavioral -step elaborate
close_project
puts "Boolean ten-image inference testbench compiled and elaborated successfully."
