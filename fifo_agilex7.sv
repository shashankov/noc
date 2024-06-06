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
module  fifo_agilex7 #(
    parameter DEPTH = 4,
    parameter WIDTH = 32,
    parameter SHOWAHEAD = "OFF",
    parameter bit FORCE_MLAB = 0
) (
    clock,
    data,
    rdreq,
    sclr,
    wrreq,
    empty,
    full,
    q,
    usedw);

    input    clock;
    input  [WIDTH-1:0]  data;
    input    rdreq;
    input    sclr;
    input    wrreq;
    output   empty;
    output   full;
    output [WIDTH-1:0]  q;
    output [$clog2(DEPTH) - 1 : 0] usedw;

// always @(posedge clock) begin
//     if (sclr == 1'b0) $display("FIFO %m: clock=%d, data=%h, rdreq=%d, sclr=%d, wrreq=%d", clock, data, rdreq, sclr, wrreq);
// end

`ifndef SIMULATION
    wire  sub_wire0;
    wire  sub_wire1;
    wire [WIDTH-1:0] sub_wire2;
    wire  empty = sub_wire0;
    wire  full = sub_wire1;
    wire [WIDTH-1:0] q = sub_wire2[WIDTH-1:0];

    scfifo  scfifo_component (
                .clock (clock),
                .data (data),
                .rdreq (rdreq),
                .sclr (sclr),
                .wrreq (wrreq),
                .empty (sub_wire0),
                .full (sub_wire1),
                .q (sub_wire2),
                .aclr (1'b0),
                .almost_empty (),
                .almost_full (),
                .eccstatus (),
                .usedw (usedw));
    defparam
        scfifo_component.add_ram_output_register  = "ON",
        scfifo_component.enable_ecc  = "FALSE",
        scfifo_component.intended_device_family  = "Agilex 7",
        scfifo_component.lpm_hint  = (FORCE_MLAB == 1) ? "RAM_BLOCK_TYPE=MLAB" : "RAM_BLOCK_TYPE=AUTO",
        scfifo_component.lpm_numwords  = DEPTH,
        scfifo_component.lpm_showahead  = SHOWAHEAD,
        scfifo_component.lpm_type  = "scfifo",
        scfifo_component.lpm_width  = WIDTH,
        scfifo_component.lpm_widthu  = $clog2(DEPTH),
        scfifo_component.overflow_checking  = "OFF",
        scfifo_component.underflow_checking  = "OFF",
        scfifo_component.use_eab  = "ON";
`else

    logic empty, full;
    logic [WIDTH - 1 : 0] mem [DEPTH : 0];
    logic [$clog2(DEPTH) : 0] front_index, back_index, front_index_next, back_index_next;

    assign front_index_next = (rdreq == 1'b1) ? ((front_index == (DEPTH)) ? '0 : (front_index + 1)) : front_index;
    assign back_index_next = (wrreq == 1'b1) ? ((back_index == (DEPTH)) ? '0 : (back_index + 1)) : back_index;

    always @(posedge clock) begin
        if (sclr == 1'b1) begin
            front_index <= '0;
            back_index <= '0;
            empty <= 1'b1;
            full <= 1'b0;
        end else begin
            front_index <= front_index_next;
            back_index <= back_index_next;
            if (wrreq == 1'b1) begin
                // $display("@%d: FIFO %m: Writing data %b to index %d", $time, data, back_index);
                mem[back_index] <= data;
                empty <= 1'b0;
                if (back_index_next == front_index_next) begin
                    full <= 1'b1;
                end
                if (full == 1'b1) begin
                    $warning("Overflow in FIFO");
                end
            end
            if (rdreq == 1'b1) begin
                // $display("@%d: FIFO %m: Reading data %b from index %d", $time, mem[front_index], front_index);
                full <= 1'b0;
                if (front_index_next == back_index_next) begin
                    empty <= 1'b1;
                end
                if (empty == 1'b1) begin
                    $warning("Underflow in FIFO");
                end
            end
        end
    end

    assign q = mem[(SHOWAHEAD == "ON") ? front_index : (front_index == '0 ? (DEPTH) : (front_index - 1))];
    assign usedw = (back_index > front_index) ? (back_index - front_index) : (DEPTH + 1 + back_index - front_index);

`endif

endmodule: fifo_agilex7
