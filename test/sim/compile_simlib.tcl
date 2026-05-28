# Vivado Tcl script to compile simulation libraries for ModelSim
# Only compiles the XPM library needed for xpm_fifo_sync / xpm_fifo_async.
if {$argc < 2} {
    puts "Error: Missing arguments. Usage: vivado -mode batch -source compile_simlib.tcl -tclargs <modelsim_bin_path> <local_simlib_dir>"
    exit 1
}
set modelsim_bin_path [lindex $argv 0]
set local_simlib_dir [lindex $argv 1]
compile_simlib -simulator modelsim -simulator_exec_path $modelsim_bin_path -library xpm -language verilog -no_ip_compile -dir $local_simlib_dir
