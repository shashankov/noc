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
vlog $QSYS_SIMDIR/../testbench/axis_dtorus_harness_tb_sim.sv $QSYS_SIMDIR/../*sv $QSYS_SIMDIR/../test_harness/*sv
#
# Set the top-level simulation or testbench module/entity name, which is
# used by the elab command to elaborate the top level.
#
set TOP_LEVEL_NAME axis_dtorus_harness_tb_sim
#
# Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
#
# Call command to elaborate your design and testbench.
elab
#
# add wave -position insertpoint  \
# sim:/axis_dtorus_harness_tb_sim/dut/clk_noc \
# sim:/axis_dtorus_harness_tb_sim/dut/clk_usr \
# sim:/axis_dtorus_harness_tb_sim/dut/rst_n \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_in_tvalid \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_in_tready \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_in_tdata \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_in_tlast \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_in_tid \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_in_tdest \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_out_tvalid \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_out_tready \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_out_tdata \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_out_tlast \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_out_tid \
# sim:/axis_dtorus_harness_tb_sim/dut/axis_out_tdest \
# sim:/axis_dtorus_harness_tb_sim/dut/rst_n_noc_sync \
# sim:/axis_dtorus_harness_tb_sim/dut/rst_n_usr_sync \
# sim:/axis_dtorus_harness_tb_sim/dut/rst_noc_sync \
# sim:/axis_dtorus_harness_tb_sim/dut/rst_usr_sync \
# sim:/axis_dtorus_harness_tb_sim/dut/data_in \
# sim:/axis_dtorus_harness_tb_sim/dut/dest_in \
# sim:/axis_dtorus_harness_tb_sim/dut/is_tail_in \
# sim:/axis_dtorus_harness_tb_sim/dut/send_in \
# sim:/axis_dtorus_harness_tb_sim/dut/credit_out \
# sim:/axis_dtorus_harness_tb_sim/dut/data_out \
# sim:/axis_dtorus_harness_tb_sim/dut/dest_out \
# sim:/axis_dtorus_harness_tb_sim/dut/is_tail_out \
# sim:/axis_dtorus_harness_tb_sim/dut/send_out \
# sim:/axis_dtorus_harness_tb_sim/dut/credit_in

# Run the simulation.
run -a
#
# Report success to the shell.
# exit -code 0
#
# TOP-LEVEL TEMPLATE - END