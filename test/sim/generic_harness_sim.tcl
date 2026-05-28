----------------------------------------
# TOP-LEVEL TEMPLATE - BEGIN
#
# QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# construct paths to the files required to simulate the IP in your Quartus
# project. By default, the IP script assumes that you are launching the
# simulator from the IP script location. If launching from another
# location, set QSYS_SIMDIR to the output directory you specified when you
# generated the IP script, relative to the directory from which you launch
# the simulator.
#
set QSYS_SIMDIR /home/sobla/workspace/noc/rtl/test/sim/
#
# Source the generated IP simulation script.
source $QSYS_SIMDIR/msim_setup.tcl
#
# Set any compilation options you require (this is unusual).
# set USER_DEFINED_COMPILE_OPTIONS <compilation options>
# set USER_DEFINED_VHDL_COMPILE_OPTIONS <compilation options for VHDL>
# set USER_DEFINED_VERILOG_COMPILE_OPTIONS <compilation options for Verilog>
#
# Call command to compile the Quartus EDA simulation library.
dev_com
#
# Call command to compile the Quartus-generated IP simulation files.
# com
#
set vlog_defines [list]
if {[info exists QUARTUS_FIFO] && $QUARTUS_FIFO} {
    lappend vlog_defines "+define+QUARTUS_FIFO"
}
if {[info exists VIVADO_FIFO] && $VIVADO_FIFO} {
    lappend vlog_defines "+define+VIVADO_FIFO"
    
    set local_simlib_dir [file normalize "$QSYS_SIMDIR/../libraries"]
    
    set modelsim_bin_path [file dirname [info nameofexecutable]]
    puts "--- Precompiling Vivado XPM simulation library to $local_simlib_dir ---"
    puts "--- Running Vivado Tcl script to compile libraries... ---"
    file mkdir $local_simlib_dir
    
    # Prevent Vivado from creating .Xil cache directory
    set ::env(XILINX_LOCAL_USER_DATA) NONE
    
    if {[catch {
        exec vivado -mode batch -nojournal -nolog \
            -source "$QSYS_SIMDIR/compile_simlib.tcl" \
            -tclargs $modelsim_bin_path $local_simlib_dir
    } compile_output]} {
        puts "Vivado compile_simlib output: $compile_output"
    } else {
        puts $compile_output
    }
    
    # Map the precompiled XPM library if it exists
    if {[file exists "$local_simlib_dir/modelsim.ini"]} {
        puts "--- Mapping precompiled Vivado XPM library from $local_simlib_dir ---"
        vmap -modelsimini "$local_simlib_dir/modelsim.ini"
        lappend logical_libraries "xpm"
    } else {
        error "Error: Vivado XPM simulation library could not be compiled/located. Simulation cannot proceed."
    }
}

vlog {*}$vlog_defines $QSYS_SIMDIR/../generic_harness_tb_sim.sv $QSYS_SIMDIR/../axis_topology_wrapper.sv $QSYS_SIMDIR/../../src/*.sv $QSYS_SIMDIR/../../src/topologies/*.sv $QSYS_SIMDIR/../../src/fifos/*.sv $QSYS_SIMDIR/../harness/*sv
#
# Set the top-level simulation or testbench module/entity name, which is
# used by the elab command to elaborate the top level.
#
set TOP_LEVEL_NAME generic_harness_tb_sim
#
# When using Vivado/Xilinx FIFOs, the XPM CDC models reference glbl.GSR,
# so glbl must be elaborated as a second top-level module.
if {[info exists VIVADO_FIFO] && $VIVADO_FIFO} {
    set TOP_LEVEL_NAME "generic_harness_tb_sim glbl"
}
#
# Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
#
# Call command to elaborate your design and testbench.
elab

# Run the simulation.
run -a

# Report success/failure to the shell.
if {[catch {examine -radix decimal /generic_harness_tb_sim/total_errors} total_errors]} {
    puts "Error: Could not examine /generic_harness_tb_sim/total_errors"
    exit -code 1
}

if {$total_errors != 0} {
    puts "Simulation failed with $total_errors errors."
    exit -code 1
} else {
    puts "Simulation passed."
    exit -code 0
}

# TOP-LEVEL TEMPLATE - END
