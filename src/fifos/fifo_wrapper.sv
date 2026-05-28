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
module  fifo_wrapper #(
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

`ifdef QUARTUS_FIFO
    `ifdef VIVADO_FIFO
        initial begin
            $fatal(1, "Both QUARTUS_FIFO and VIVADO_FIFO are defined.");
        end
    `endif
`endif

`ifdef VIVADO_FIFO
    localparam XILINX_DEPTH = (DEPTH < 16) ? 16 : DEPTH;
    wire [$clog2(XILINX_DEPTH) : 0] xil_usedw;
    assign usedw = xil_usedw[$clog2(DEPTH)-1:0];

    wire xil_full;
    wire wr_rst_busy;
    assign full = xil_full || wr_rst_busy;

    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE    (FORCE_MLAB ? "distributed" : "auto"),
        .FIFO_WRITE_DEPTH    (XILINX_DEPTH),
        .WRITE_DATA_WIDTH    (WIDTH),
        .READ_DATA_WIDTH     (WIDTH),
        .READ_MODE           ((SHOWAHEAD == "ON") ? "fwft" : "std"),
        .FIFO_READ_LATENCY   ((SHOWAHEAD == "ON") ? 0 : 1),
        .ECC_MODE            ("no_ecc"),
        .USE_ADV_FEATURES    ("0505"),
        .WR_DATA_COUNT_WIDTH ($clog2(XILINX_DEPTH) + 1)
    ) xpm_fifo_sync_inst (
        .wr_clk        (clock),
        .rst           (sclr),
        .din           (data),
        .wr_en         (wrreq),
        .rd_en         (rdreq),
        .dout          (q),
        .empty         (empty),
        .full          (xil_full),
        .wr_data_count (xil_usedw),
        .sleep         (1'b0),
        .injectsbiterr (1'b0),
        .injectdbiterr (1'b0),
        .sbiterr       (),
        .dbiterr       (),
        .rd_rst_busy   (),
        .wr_rst_busy   (wr_rst_busy),
        .almost_full   (),
        .almost_empty  (),
        .prog_full     (),
        .prog_empty    (),
        .wr_ack        (),
        .overflow      (),
        .underflow     (),
        .data_valid    (),
        .rd_data_count ()
    );
`elsif QUARTUS_FIFO

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
    localparam [$clog2(DEPTH)-1:0] DEPTH_MINUS_1 = ($clog2(DEPTH))'(DEPTH - 1);
    localparam [$clog2(DEPTH):0] DEPTH_VAL = ($clog2(DEPTH)+1)'(DEPTH);

    logic [WIDTH - 1 : 0] mem [DEPTH - 1 : 0];
    logic [$clog2(DEPTH) - 1 : 0] front_index, back_index;
    logic [$clog2(DEPTH) : 0] count;
    logic [$clog2(DEPTH) : 0] count_next;
    logic [WIDTH - 1 : 0] q_reg;
    logic doing_write, doing_read;

    assign doing_write = wrreq && (!full || rdreq);
    assign doing_read = rdreq && !empty;

    always_comb begin
        count_next = count;
        if (doing_write && !doing_read) begin
            count_next = count + 1'b1;
        end else if (doing_read && !doing_write) begin
            count_next = count - 1'b1;
        end
    end

    logic has_been_reset = 1'b0;

    always_ff @(posedge clock) begin
        if (sclr == 1'b1) begin
            front_index <= '0;
            back_index <= '0;
            count <= '0;
            empty <= 1'b1;
            full <= 1'b0;
            q_reg <= '0;
            has_been_reset <= 1'b1;
        end else begin
            if (doing_write) begin
                mem[back_index] <= data;
                back_index <= (back_index == DEPTH_MINUS_1) ? '0 : back_index + 1'b1;
            end
            if (doing_read) begin
                q_reg <= mem[front_index];
                front_index <= (front_index == DEPTH_MINUS_1) ? '0 : front_index + 1'b1;
            end

            count <= count_next;
            empty <= (count_next == '0);
            full <= (count_next == DEPTH_VAL);

            if (wrreq && full && !rdreq) begin
                $warning("Overflow in FIFO");
            end
            if (rdreq && empty && has_been_reset) begin
                $warning("Underflow in FIFO");
            end
        end
    end

    assign q = (SHOWAHEAD == "ON") ? mem[front_index] : q_reg;
    assign usedw = count[$clog2(DEPTH) - 1 : 0];

`endif

endmodule: fifo_wrapper

