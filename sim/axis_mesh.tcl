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
set QSYS_SIMDIR /home/sobla/workspace/noc/rtl/sim/
#
# Source the generated IP simulation script.
source $QSYS_SIMDIR/mentor/msim_setup.tcl
#
# Set any compilation options you require (this is unusual).
# set USER_DEFINED_COMPILE_OPTIONS <compilation options>
# set USER_DEFINED_VHDL_COMPILE_OPTIONS <compilation options for VHDL>
# set USER_DEFINED_VERILOG_COMPILE_OPTIONS <compilation options for Verilog>
#
# Call command to compile the Quartus EDA simulation library.
# dev_com
#
# Call command to compile the Quartus-generated IP simulation files.
# com
#
# Add commands to compile all design files and testbench files, including
# the top level. (These are all the files required for simulation other
# than the files compiled by the Quartus-generated IP simulation script)
#
vlog +acc $QSYS_SIMDIR/../testbench/axis_mesh_tb.sv $QSYS_SIMDIR/../*sv
#
# Set the top-level simulation or testbench module/entity name, which is
# used by the elab command to elaborate the top level.
#
set TOP_LEVEL_NAME axis_mesh_tb
#
# Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
#
# Call command to elaborate your design and testbench.
elab_debug
#
add wave -position insertpoint  \
sim:/axis_mesh_tb/clk \
sim:/axis_mesh_tb/rst_n \
sim:/axis_mesh_tb/axis_in_tvalid \
sim:/axis_mesh_tb/axis_in_tready \
sim:/axis_mesh_tb/axis_in_tdata \
sim:/axis_mesh_tb/axis_in_tlast \
sim:/axis_mesh_tb/axis_in_tdest \
sim:/axis_mesh_tb/axis_out_tvalid \
sim:/axis_mesh_tb/axis_out_tready \
sim:/axis_mesh_tb/axis_out_tdata \
sim:/axis_mesh_tb/axis_out_tlast \
sim:/axis_mesh_tb/axis_out_tdest

add wave -position insertpoint  \
sim:/axis_mesh_tb/dut/noc/send_router_in \
sim:/axis_mesh_tb/dut/noc/send_router_out

add wave -position insertpoint  \
sim:/axis_mesh_tb/dut/noc/send_in \
sim:/axis_mesh_tb/dut/noc/send_out \
sim:/axis_mesh_tb/dut/noc/send_north \
sim:/axis_mesh_tb/dut/noc/send_south \
sim:/axis_mesh_tb/dut/noc/send_east \
sim:/axis_mesh_tb/dut/noc/send_west
# Run the simulation.
run -a
#
# Report success to the shell.
# exit -code 0
#
# TOP-LEVEL TEMPLATE - END