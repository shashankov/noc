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
vlog +acc $QSYS_SIMDIR/../testbench/router_harness_tb_sim.sv $QSYS_SIMDIR/../*sv $QSYS_SIMDIR/../test_harness/*sv
#
# Set the top-level simulation or testbench module/entity name, which is
# used by the elab command to elaborate the top level.
#
set TOP_LEVEL_NAME router_harness_tb_sim
#
# Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
#
# Call command to elaborate your design and testbench.
elab_debug

add wave -position insertpoint  \
sim:/router_harness_tb_sim/clk \
sim:/router_harness_tb_sim/clk_noc \
sim:/router_harness_tb_sim/rst_n \
sim:/router_harness_tb_sim/ticks \
sim:/router_harness_tb_sim/axis_in_tvalid \
sim:/router_harness_tb_sim/axis_in_tready \
sim:/router_harness_tb_sim/axis_in_tdata \
sim:/router_harness_tb_sim/axis_in_tlast \
sim:/router_harness_tb_sim/axis_in_tdest \
sim:/router_harness_tb_sim/axis_in_tid \
sim:/router_harness_tb_sim/data_in \
sim:/router_harness_tb_sim/dest_in \
sim:/router_harness_tb_sim/is_tail_in \
sim:/router_harness_tb_sim/send_in \
sim:/router_harness_tb_sim/credit_out \
sim:/router_harness_tb_sim/data_out \
sim:/router_harness_tb_sim/dest_out \
sim:/router_harness_tb_sim/is_tail_out \
sim:/router_harness_tb_sim/send_out \
sim:/router_harness_tb_sim/credit_in \
sim:/router_harness_tb_sim/axis_out_tvalid \
sim:/router_harness_tb_sim/axis_out_tready \
sim:/router_harness_tb_sim/axis_out_tdata \
sim:/router_harness_tb_sim/axis_out_tlast \
sim:/router_harness_tb_sim/axis_out_tdest \
sim:/router_harness_tb_sim/axis_out_tid \
sim:/router_harness_tb_sim/done \
sim:/router_harness_tb_sim/start \
sim:/router_harness_tb_sim/sent_packets \
sim:/router_harness_tb_sim/recv_packets \
sim:/router_harness_tb_sim/error

add wave -position insertpoint  \
sim:/router_harness_tb_sim/dut/clk \
sim:/router_harness_tb_sim/dut/rst_n \
sim:/router_harness_tb_sim/dut/data_in \
sim:/router_harness_tb_sim/dut/dest_in \
sim:/router_harness_tb_sim/dut/is_tail_in \
sim:/router_harness_tb_sim/dut/send_in \
sim:/router_harness_tb_sim/dut/credit_out \
sim:/router_harness_tb_sim/dut/data_out \
sim:/router_harness_tb_sim/dut/dest_out \
sim:/router_harness_tb_sim/dut/is_tail_out \
sim:/router_harness_tb_sim/dut/send_out \
sim:/router_harness_tb_sim/dut/credit_in \
sim:/router_harness_tb_sim/dut/route_table \
sim:/router_harness_tb_sim/dut/route_table_out \
sim:/router_harness_tb_sim/dut/route_sa_reg \
sim:/router_harness_tb_sim/dut/route_table_select \
sim:/router_harness_tb_sim/dut/receiving_packet \
sim:/router_harness_tb_sim/dut/transiting_packet \
sim:/router_harness_tb_sim/dut/dest_buffer_out \
sim:/router_harness_tb_sim/dut/dest_buffer_empty \
sim:/router_harness_tb_sim/dut/dest_buffer_rdreq \
sim:/router_harness_tb_sim/dut/flit_buffer_out \
sim:/router_harness_tb_sim/dut/flit_buffer_is_tail_out \
sim:/router_harness_tb_sim/dut/flit_buffer_empty \
sim:/router_harness_tb_sim/dut/flit_buffer_rdreq \
sim:/router_harness_tb_sim/dut/flit_buffer_valid \
sim:/router_harness_tb_sim/dut/request \
sim:/router_harness_tb_sim/dut/hold \
sim:/router_harness_tb_sim/dut/grant \
sim:/router_harness_tb_sim/dut/grant_mask \
sim:/router_harness_tb_sim/dut/grant_reg \
sim:/router_harness_tb_sim/dut/grant_input \
sim:/router_harness_tb_sim/dut/flit_rc_reg_flit \
sim:/router_harness_tb_sim/dut/flit_rc_reg_dest \
sim:/router_harness_tb_sim/dut/flit_rc_reg_is_tail \
sim:/router_harness_tb_sim/dut/rc_reg_credit_proxy \
sim:/router_harness_tb_sim/dut/flit_rc_reg_valid \
sim:/router_harness_tb_sim/dut/rc_pipeline_enable \
sim:/router_harness_tb_sim/dut/flit_sa_reg \
sim:/router_harness_tb_sim/dut/flit_sa_reg_flit \
sim:/router_harness_tb_sim/dut/flit_sa_reg_dest \
sim:/router_harness_tb_sim/dut/flit_sa_reg_is_tail \
sim:/router_harness_tb_sim/dut/flit_sa_reg_valid \
sim:/router_harness_tb_sim/dut/data_out_packed \
sim:/router_harness_tb_sim/dut/data_out_flit \
sim:/router_harness_tb_sim/dut/data_out_dest \
sim:/router_harness_tb_sim/dut/data_out_is_tail \
sim:/router_harness_tb_sim/dut/flit_out_valid \
sim:/router_harness_tb_sim/dut/data_out_reg \
sim:/router_harness_tb_sim/dut/data_out_reg_flit \
sim:/router_harness_tb_sim/dut/data_out_reg_dest \
sim:/router_harness_tb_sim/dut/data_out_reg_is_tail \
sim:/router_harness_tb_sim/dut/data_out_reg_valid \
sim:/router_harness_tb_sim/dut/credit_counter \
sim:/router_harness_tb_sim/dut/credit_counter_in \
sim:/router_harness_tb_sim/dut/credit_counter_plus \
sim:/router_harness_tb_sim/dut/grant_pipeline_in \
sim:/router_harness_tb_sim/dut/grant_pipeline_out

# Run the simulation.
run -a
#
# Report success to the shell.
# exit -code 0
#
# TOP-LEVEL TEMPLATE - END