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
if {[info exists SIMULATION] && $SIMULATION} {
    vlog +define+SIMULATION $QSYS_SIMDIR/../generic_harness_tb_sim.sv $QSYS_SIMDIR/../axis_topology_wrapper.sv $QSYS_SIMDIR/../../src/*.sv $QSYS_SIMDIR/../../src/topologies/*.sv $QSYS_SIMDIR/../../src/fifos/*.sv $QSYS_SIMDIR/../harness/*sv
} else {
    vlog $QSYS_SIMDIR/../generic_harness_tb_sim.sv $QSYS_SIMDIR/../axis_topology_wrapper.sv $QSYS_SIMDIR/../../src/*.sv $QSYS_SIMDIR/../../src/topologies/*.sv $QSYS_SIMDIR/../../src/fifos/*.sv $QSYS_SIMDIR/../harness/*sv
}
#
# Set the top-level simulation or testbench module/entity name, which is
# used by the elab command to elaborate the top level.
#
set TOP_LEVEL_NAME generic_harness_tb_sim
#
# Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
#
# Call command to elaborate your design and testbench.
elab

# Run the simulation.
run -a
#
# Report success to the shell.
# exit -code 0
#
# TOP-LEVEL TEMPLATE - END
