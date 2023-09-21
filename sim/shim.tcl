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
vlog +acc $QSYS_SIMDIR/../testbench/shim_tb.sv $QSYS_SIMDIR/../*sv
#
# Set the top-level simulation or testbench module/entity name, which is
# used by the elab command to elaborate the top level.
#
set TOP_LEVEL_NAME shim_tb
#
# Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
#
# Call command to elaborate your design and testbench.
elab_debug
#

add wave -position insertpoint  \
sim:/shim_tb/clk_usr \
sim:/shim_tb/clk_noc \
sim:/shim_tb/rst_n \
sim:/shim_tb/axis_tvalid_in \
sim:/shim_tb/axis_tready_in \
sim:/shim_tb/axis_tlast_in \
sim:/shim_tb/axis_tdata_in \
sim:/shim_tb/axis_tdest_in \
sim:/shim_tb/axis_tvalid_out \
sim:/shim_tb/axis_tready_out \
sim:/shim_tb/axis_tlast_out \
sim:/shim_tb/axis_tdata_out \
sim:/shim_tb/axis_tdest_out \
sim:/shim_tb/data \
sim:/shim_tb/dest \
sim:/shim_tb/is_tail \
sim:/shim_tb/send \
sim:/shim_tb/credit

# add wave -position insertpoint  \
# sim:/shim_tb/shim_in/dest_buffer_out \
# sim:/shim_tb/shim_in/data_buffer_wrfull \
# sim:/shim_tb/shim_in/data_buffer_rdempty \
# sim:/shim_tb/shim_in/data_buffer_rdreq \
# sim:/shim_tb/shim_in/credit_count \
# sim:/shim_tb/shim_in/ser_count \
# sim:/shim_tb/shim_in/dest_buffer_rdreq \
# sim:/shim_tb/shim_in/dest_buffer_rdempty

# add wave -position insertpoint  \
# sim:/shim_tb/shim_out/dest_buffer_out \
# sim:/shim_tb/shim_out/dest_buffer_rdempty \
# sim:/shim_tb/shim_out/dest_buffer_wrreq \
# sim:/shim_tb/shim_out/data_buffer_rdempty \
# sim:/shim_tb/shim_out/data_buffer_wrusedw \
# sim:/shim_tb/shim_out/credit_count \
# sim:/shim_tb/shim_out/ser_count \
# sim:/shim_tb/shim_out/credit_count_reg

# add wave -position insertpoint  \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/data \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/rdclk \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/wrclk \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/aclr \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/rdreq \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/wrreq \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/rdfull \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/wrfull \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/rdempty \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/wrempty \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/rdusedw \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/wrusedw \
# sim:/shim_tb/shim_out/data_buffer/dcfifo_mixed_widths_component/q

# Run the simulation.
run -a
#
# Report success to the shell.
# exit -code 0
#
# TOP-LEVEL TEMPLATE - END