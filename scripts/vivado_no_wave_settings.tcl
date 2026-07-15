# Source this in the Vivado Tcl Console before a long behavioral simulation:
#
#   source C:/Users/Oishik\ Ganguli/FPGA_projects/posit_cnn_accelerator/scripts/vivado_no_wave_settings.tcl
#
# It prevents the usual GUI habit of recursively logging every signal into a
# giant waveform database. It does not change RTL or testbench behavior.

if {[llength [get_filesets -quiet sim_1]]} {
    catch {set_property xsim.simulate.log_all_signals false [get_filesets sim_1]}
    catch {set_property xsim.elaborate.debug_level off [get_filesets sim_1]}
    catch {set_property xsim.simulate.runtime all [get_filesets sim_1]}
}

catch {remove_wave -all}
catch {close_wave_config}

puts "No-wave simulation settings applied."
puts "For long inference runs, avoid Add to Wave -> All Objects."
puts "Best path: run scripts/run_mem_inference_no_wave.ps1 from PowerShell."
