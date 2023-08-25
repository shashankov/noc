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
vlog +acc $QSYS_SIMDIR/../testbench/router_reg_tb.sv $QSYS_SIMDIR/../*sv
#
# Set the top-level simulation or testbench module/entity name, which is
# used by the elab command to elaborate the top level.
#
set TOP_LEVEL_NAME router_reg_tb
#
# Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
#
# Call command to elaborate your design and testbench.
elab_debug
#

add wave -position insertpoint  \
sim:/router_reg_tb/clk \
sim:/router_reg_tb/rst_n \
sim:/router_reg_tb/send \
sim:/router_reg_tb/recv \
sim:/router_reg_tb/credit_out \
sim:/router_reg_tb/data_in \
sim:/router_reg_tb/data_out \
sim:/router_reg_tb/dest_in \
sim:/router_reg_tb/dest_out \
sim:/router_reg_tb/is_tail_in \
sim:/router_reg_tb/is_tail_out
add wave -position insertpoint  \
sim:/router_reg_tb/dut/NOC_NUM_ENDPOINTS \
sim:/router_reg_tb/dut/ROUTING_TABLE_HEX \
sim:/router_reg_tb/dut/NUM_INPUTS \
sim:/router_reg_tb/dut/NUM_OUTPUTS \
sim:/router_reg_tb/dut/DEST_WIDTH \
sim:/router_reg_tb/dut/FLIT_WIDTH \
sim:/router_reg_tb/dut/FLIT_BUFFER_DEPTH \
sim:/router_reg_tb/dut/clk \
sim:/router_reg_tb/dut/rst_n \
sim:/router_reg_tb/dut/data_in \
sim:/router_reg_tb/dut/dest_in \
sim:/router_reg_tb/dut/is_tail_in \
sim:/router_reg_tb/dut/send_in \
sim:/router_reg_tb/dut/credit_out \
sim:/router_reg_tb/dut/data_out \
sim:/router_reg_tb/dut/dest_out \
sim:/router_reg_tb/dut/is_tail_out \
sim:/router_reg_tb/dut/send_out \
sim:/router_reg_tb/dut/credit_in \
sim:/router_reg_tb/dut/route_table \
sim:/router_reg_tb/dut/route_table_out \
sim:/router_reg_tb/dut/route_table_select \
sim:/router_reg_tb/dut/receiving_packet \
sim:/router_reg_tb/dut/transiting_packet \
sim:/router_reg_tb/dut/dest_buffer_out \
sim:/router_reg_tb/dut/dest_buffer_empty \
sim:/router_reg_tb/dut/dest_buffer_rdreq \
sim:/router_reg_tb/dut/flit_buffer_out \
sim:/router_reg_tb/dut/flit_buffer_is_tail_out \
sim:/router_reg_tb/dut/flit_buffer_empty \
sim:/router_reg_tb/dut/flit_buffer_rdreq \
sim:/router_reg_tb/dut/flit_buffer_valid \
sim:/router_reg_tb/dut/request \
sim:/router_reg_tb/dut/hold \
sim:/router_reg_tb/dut/grant \
sim:/router_reg_tb/dut/flit_reg0 \
sim:/router_reg_tb/dut/flit_reg0_valid \
sim:/router_reg_tb/dut/pipeline_enable \
sim:/router_reg_tb/dut/data_out_packed \
sim:/router_reg_tb/dut/flit_out_valid \
sim:/router_reg_tb/dut/credit_counter

# add wave -position insertpoint  \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/NUM_INPUTS} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/clk} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/rst_n} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/request} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/hold} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/grant} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/matrix} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/enable} \
# {sim:/router_reg_tb/dut/genblk4/genblk1[0]/arbiter_inst/deactivate}

# Run the simulation.
run -a
#
# Report success to the shell.
# exit -code 0
#
# TOP-LEVEL TEMPLATE - END