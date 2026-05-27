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

`ifndef SIMULATION
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
`else

    localparam RATIO = (WIDTH_IN >= WIDTH_OUT) ? (WIDTH_IN / WIDTH_OUT) : (WIDTH_OUT / WIDTH_IN);
    localparam UNIT_WIDTH = (WIDTH_IN < WIDTH_OUT) ? WIDTH_IN : WIDTH_OUT;
    localparam TOTAL_DEPTH = (WIDTH_IN >= WIDTH_OUT) ? (DEPTH * RATIO) : DEPTH;
    localparam ADDR_WIDTH = $clog2(TOTAL_DEPTH);
    localparam PTR_WIDTH = ADDR_WIDTH + 1;
    localparam SYNC_STAGES = 4 + EXTRA_SYNC_STAGES;
    localparam write_increment = (WIDTH_IN >= WIDTH_OUT) ? RATIO : 1;
    localparam read_increment = (WIDTH_IN >= WIDTH_OUT) ? 1 : RATIO;

    logic [UNIT_WIDTH-1:0] mem [TOTAL_DEPTH-1:0];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    logic [PTR_WIDTH-1:0] wr_ptr_sync [SYNC_STAGES-1:0];
    logic [PTR_WIDTH-1:0] rd_ptr_sync [SYNC_STAGES-1:0];

    logic [PTR_WIDTH-1:0] diff_rd;
    logic [PTR_WIDTH-1:0] diff_wr;

    // Synchronize wr_ptr to rdclk domain
    always_ff @(posedge rdclk or posedge aclr) begin
        if (aclr) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                wr_ptr_sync[i] <= '0;
            end
        end else begin
            wr_ptr_sync[0] <= wr_ptr;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                wr_ptr_sync[i] <= wr_ptr_sync[i-1];
            end
        end
    end

    // Synchronize rd_ptr to wrclk domain
    always_ff @(posedge wrclk or posedge aclr) begin
        if (aclr) begin
            for (int i = 0; i < SYNC_STAGES; i++) begin
                rd_ptr_sync[i] <= '0;
            end
        end else begin
            rd_ptr_sync[0] <= rd_ptr;
            for (int i = 1; i < SYNC_STAGES; i++) begin
                rd_ptr_sync[i] <= rd_ptr_sync[i-1];
            end
        end
    end

    assign diff_rd = wr_ptr_sync[SYNC_STAGES-1] - rd_ptr;
    assign diff_wr = wr_ptr - rd_ptr_sync[SYNC_STAGES-1];

    assign rdempty = (diff_rd < PTR_WIDTH'(read_increment));
    assign wrfull  = (diff_wr > PTR_WIDTH'(TOTAL_DEPTH - write_increment));

    // wrusedw is in terms of WIDTH_IN words
    if (WIDTH_IN >= WIDTH_OUT) begin : g_wrusedw_dec
        assign wrusedw = ($clog2(DEPTH)+1)'(diff_wr / PTR_WIDTH'(RATIO));
    end else begin : g_wrusedw_direct
        assign wrusedw = ($clog2(DEPTH)+1)'(diff_wr);
    end

    // Write pointer update
    always_ff @(posedge wrclk or posedge aclr) begin
        if (aclr) begin
            wr_ptr <= '0;
        end else begin
            if (wrreq && !wrfull) begin
                wr_ptr <= wr_ptr + PTR_WIDTH'(write_increment);
            end
            if (wrreq && wrfull) begin
                $warning("Overflow in DCFIFO");
            end
        end
    end

    // Memory write block
    if (WIDTH_IN >= WIDTH_OUT) begin : g_write_wide
        always_ff @(posedge wrclk) begin
            if (wrreq && !wrfull) begin
                for (int i = 0; i < RATIO; i++) begin
                    mem[ADDR_WIDTH'(wr_ptr + PTR_WIDTH'(i))] <= data[i * WIDTH_OUT +: WIDTH_OUT];
                end
            end
        end
    end else begin : g_write_narrow
        always_ff @(posedge wrclk) begin
            if (wrreq && !wrfull) begin
                mem[ADDR_WIDTH'(wr_ptr)] <= data;
            end
        end
    end

    // Read logic
    logic [WIDTH_OUT-1:0] q_reg;
    
    // Read pointer update
    always_ff @(posedge rdclk or posedge aclr) begin
        if (aclr) begin
            rd_ptr <= '0;
        end else begin
            if (rdreq && !rdempty) begin
                rd_ptr <= rd_ptr + PTR_WIDTH'(read_increment);
            end
            if (rdreq && rdempty) begin
                $warning("Underflow in DCFIFO");
            end
        end
    end

    // Memory read block (registered)
    if (WIDTH_IN >= WIDTH_OUT) begin : g_read_wide
        always_ff @(posedge rdclk or posedge aclr) begin
            if (aclr) begin
                q_reg <= '0;
            end else begin
                if (rdreq && !rdempty) begin
                    q_reg <= mem[ADDR_WIDTH'(rd_ptr)];
                end
            end
        end
    end else begin : g_read_narrow
        always_ff @(posedge rdclk or posedge aclr) begin
            if (aclr) begin
                q_reg <= '0;
            end else begin
                if (rdreq && !rdempty) begin
                    for (int i = 0; i < RATIO; i++) begin
                        q_reg[i * WIDTH_IN +: WIDTH_IN] <= mem[ADDR_WIDTH'(rd_ptr + PTR_WIDTH'(i))];
                    end
                end
            end
        end
    end

    if (SHOWAHEAD == "ON") begin : g_showahead
        if (WIDTH_IN >= WIDTH_OUT) begin : g_sa_wide
            assign q = mem[ADDR_WIDTH'(rd_ptr)];
        end else begin : g_sa_narrow
            logic [WIDTH_OUT-1:0] q_comb;
            always_comb begin
                for (int i = 0; i < RATIO; i++) begin
                    q_comb[i * WIDTH_IN +: WIDTH_IN] = mem[ADDR_WIDTH'(rd_ptr + PTR_WIDTH'(i))];
                end
            end
            assign q = q_comb;
        end
    end else begin : g_normal
        assign q = q_reg;
    end

`endif


endmodule


