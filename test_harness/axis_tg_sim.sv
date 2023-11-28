`timescale 1ns / 1ps
// Implements uniform random traffic generation

module axis_tg_sim #(
    parameter SEED = 0,

    parameter COUNT_WIDTH = 32,
    parameter TID = 0,

    parameter TDATA_WIDTH = 512,
    parameter TDEST_WIDTH = 2,
    parameter TID_WIDTH = 2,
    parameter NUM_ROUTERS = 4) (
    input   wire                                clk,
    input   wire                                rst_n,

    input   wire    [15 : 0]                    load,
    input   wire    [COUNT_WIDTH - 1 : 0]       num_packets,

    input   wire                                start,
    input   wire    [TDATA_WIDTH / 2 - 1 : 0]   ticks,
    output  logic                               done,
    output  logic   [COUNT_WIDTH - 1 : 0]       sent_packets[NUM_ROUTERS],
    output  logic   [COUNT_WIDTH - 1 : 0]       total_sent_packets,

    output  logic                               axis_out_tvalid,
    input   wire                                axis_out_tready,
    output  logic   [TDATA_WIDTH - 1 : 0]       axis_out_tdata,
    output  logic                               axis_out_tlast,
    output  logic   [TID_WIDTH - 1 : 0]         axis_out_tid,
    output  logic   [TDEST_WIDTH - 1 : 0]       axis_out_tdest
);

    logic [$clog2(NUM_ROUTERS) - 1 : 0] dest_lfsr_out;
    logic [15 : 0] load_lfsr_out;
    initial begin
        if (SEED != 0) begin
            $display("%m: Using seed %0d", SEED);
            dest_lfsr_out = $urandom(SEED);
        end

        forever begin
            @(posedge clk);

            dest_lfsr_out = $urandom % NUM_ROUTERS;
            load_lfsr_out = $urandom;
        end
    end

    logic   [TDATA_WIDTH - 1 : 0]       axis_fifo_tdata;
    logic   [TID_WIDTH - 1 : 0]         axis_fifo_tid;
    logic   [TDEST_WIDTH - 1 : 0]       axis_fifo_tdest;

    logic   fifo_write, fifo_empty, fifo_full;

    assign axis_fifo_tdata = {ticks, {(TDATA_WIDTH / 2 - COUNT_WIDTH){1'b0}}, sent_packets[axis_fifo_tdest]};
    assign axis_fifo_tid = TID;
    assign axis_fifo_tdest = dest_lfsr_out[TDEST_WIDTH - 1 : 0];
    assign axis_out_tvalid = ~fifo_empty;
    assign axis_out_tlast = 1'b1;

    enum {
        IDLE,
        RUNNING
    } state, next_state;

    always_ff @(posedge clk) begin
        if (rst_n == 1'b0) begin
            total_sent_packets <= '0;
            for (int i = 0; i < NUM_ROUTERS; i++) begin
                sent_packets[i] <= '0;
            end
        end else begin
            if (fifo_write && ~fifo_full) begin
                total_sent_packets <= total_sent_packets + 1'b1;
                sent_packets[axis_fifo_tdest] <= sent_packets[axis_fifo_tdest] + 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n == 1'b0) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        done = 1'b0;
        fifo_write = 1'b0;

        case (state)
            IDLE: begin
                done = 1'b1;
                if (start) begin
                    next_state = RUNNING;
                end
            end
            RUNNING: begin
                // Making an assumption that ready is always high
                // otherwise load produced will be lower than required
                if (load_lfsr_out < load) begin
                    fifo_write = 1'b1;
                    if (fifo_full) begin
                        $display("@%0t Warning: FIFO is full at tg id %d\n", $time, TID);
                    end
                end
                if (total_sent_packets >= num_packets) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    fifo_agilex7 #(
        .DEPTH(4*1024*1024),
        .WIDTH(TDATA_WIDTH + TID_WIDTH + TDEST_WIDTH),
        .SHOWAHEAD("ON"),
        .FORCE_MLAB(0)
    ) buffer (
        .clock  (clk),
        .data   ({axis_fifo_tdata, axis_fifo_tid, axis_fifo_tdest}),
        .rdreq  (axis_out_tready & axis_out_tvalid),
        .sclr   (~rst_n),
        .wrreq  (fifo_write & ~fifo_full),
        .empty  (fifo_empty),
        .full   (fifo_full),
        .q      ({axis_out_tdata, axis_out_tid, axis_out_tdest})
    );

endmodule: axis_tg_sim
