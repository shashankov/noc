// (C) 2001-2023 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other
// software and tools, and its AMPP partner logic functions, and any output
// files from any of the foregoing (including device programming or simulation
// files), and any associated documentation or information are expressly subject
// to the terms and conditions of the Intel Program License Subscription
// Agreement, Intel FPGA IP License Agreement, or other applicable
// license agreement, including, without limitation, that your use is for the
// sole purpose of programming logic devices manufactured by Intel and sold by
// Intel or its authorized distributors.  Please refer to the applicable
// agreement for further details.



// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module  dcfifo_mixed_width_agilex7 #(
    parameter WIDTH_IN = 512,
    parameter WIDTH_OUT = 128,
    parameter DEPTH = 8,
    parameter EXTRA_SYNC_STAGES = 0,
    parameter SHOWAHEAD = "OFF"
) (
    aclr,
    data,
    rdclk,
    rdreq,
    wrclk,
    wrreq,
    q,
    rdempty,
    wrfull,
    wrusedw);

    input    aclr;
    input  [WIDTH_IN-1:0]  data;
    input    rdclk;
    input    rdreq;
    input    wrclk;
    input    wrreq;
    output [WIDTH_OUT-1:0]  q;
    output   rdempty;
    output   wrfull;
    output [$clog2(DEPTH):0]  wrusedw;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
    tri0     aclr;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [WIDTH_OUT-1:0] sub_wire0;
    wire  sub_wire1;
    wire  sub_wire2;
    wire [WIDTH_OUT-1:0] q = sub_wire0[WIDTH_OUT-1:0];
    wire  rdempty = sub_wire1;
    wire  wrfull = sub_wire2;

    dcfifo_mixed_widths  dcfifo_mixed_widths_component (
                .aclr (aclr),
                .data (data),
                .rdclk (rdclk),
                .rdreq (rdreq),
                .wrclk (wrclk),
                .wrreq (wrreq),
                .q (sub_wire0),
                .rdempty (sub_wire1),
                .wrfull (sub_wire2),
                .eccstatus (),
                .rdfull (),
                .rdusedw (),
                .wrempty (),
                .wrusedw (wrusedw));
    defparam
        dcfifo_mixed_widths_component.add_usedw_msb_bit  = "ON",
        dcfifo_mixed_widths_component.enable_ecc  = "FALSE",
        dcfifo_mixed_widths_component.intended_device_family  = "Agilex 7",
        dcfifo_mixed_widths_component.lpm_hint  = "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE",
        dcfifo_mixed_widths_component.lpm_numwords  = DEPTH,
        dcfifo_mixed_widths_component.lpm_showahead  = SHOWAHEAD,
        dcfifo_mixed_widths_component.lpm_type  = "dcfifo_mixed_widths",
        dcfifo_mixed_widths_component.lpm_width  = WIDTH_IN,
        dcfifo_mixed_widths_component.lpm_widthu  = $clog2(DEPTH) + 1,
        dcfifo_mixed_widths_component.lpm_widthu_r  = $clog2(DEPTH * WIDTH_IN / WIDTH_OUT) + 1,
        dcfifo_mixed_widths_component.lpm_width_r  = WIDTH_OUT,
        dcfifo_mixed_widths_component.overflow_checking  = "OFF",
        dcfifo_mixed_widths_component.rdsync_delaypipe  = 4 + EXTRA_SYNC_STAGES,
        dcfifo_mixed_widths_component.read_aclr_synch  = "ON",
        dcfifo_mixed_widths_component.underflow_checking  = "OFF",
        dcfifo_mixed_widths_component.use_eab  = "ON",
        dcfifo_mixed_widths_component.write_aclr_synch  = "ON",
        dcfifo_mixed_widths_component.wrsync_delaypipe  = 4 + EXTRA_SYNC_STAGES;


endmodule


