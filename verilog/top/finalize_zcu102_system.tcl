# Regenerate the ZCU102 block-design products after an RTL change.
# Source this from the open posit_cnn_accelerator_zcu102 project.

if {[current_project -quiet] eq ""} {
    error "Open the ZCU102 deployment project before sourcing this script."
}
if {[get_property PART [current_project]] ne "xczu9eg-ffvb1156-2-e"} {
    error "This script requires the ZCU102 part xczu9eg-ffvb1156-2-e."
}

set bd_name cnn_zcu102_system
set bd_file [get_files -quiet ${bd_name}.bd]
if {[llength $bd_file] == 0} {
    error "${bd_name}.bd is not present. Run scripts/create_zcu102_deployment_project.tcl once first."
}

set_property synth_checkpoint_mode None $bd_file
reset_target all $bd_file
generate_target all $bd_file

set project_dir [get_property DIRECTORY [current_project]]
set project_name [get_property NAME [current_project]]
set wrapper_file [file join $project_dir ${project_name}.gen sources_1 bd $bd_name hdl ${bd_name}_wrapper.v]
if {![file exists $wrapper_file]} {
    error "Generate Output Products for ${bd_name} did not create $wrapper_file"
}

if {[llength [get_files -quiet $wrapper_file]] == 0} {
    add_files -norecurse $wrapper_file
}
set_property top ${bd_name}_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
save_project

puts "Regenerated ${bd_name}; implementation top is ${bd_name}_wrapper."
