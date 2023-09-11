`timescale 1ns / 1ps
// Implements uniform random traffic generation

module axis_tg #(
    parameter DEST_SEED = 64'h48D34421DF9848B,
    parameter LOAD_SEED = 16'h92DA,

    parameter COUNT_WIDTH = 32,
    parameter TID = 0,

    parameter TDATA_WIDTH = 512,
    parameter TDEST_WIDTH = 2,
    parameter TID_WIDTH = 2) (
    input   wire                                clk,
    input   wire                                rst_n,

    input   wire    [15 : 0]                    load,
    input   wire    [COUNT_WIDTH - 1 : 0]       num_packets,

    input   wire                                start,
    input   wire    [TDATA_WIDTH / 2 - 1 : 0]   ticks,
    output  logic                               done,
    output  logic   [COUNT_WIDTH - 1 : 0]       sent_packets[2**TDEST_WIDTH],

    output  logic                               axis_out_tvalid,
    input   wire                                axis_out_tready,
    output  logic   [TDATA_WIDTH - 1 : 0]       axis_out_tdata,
    output  logic                               axis_out_tlast,
    output  logic   [TID_WIDTH - 1 : 0]         axis_out_tid,
    output  logic   [TDEST_WIDTH - 1 : 0]       axis_out_tdest
);
    logic [63 : 0] dest_lfsr_out;
    logic [15 : 0] load_lfsr_out;
    logic [COUNT_WIDTH - 1 : 0] total_sent_packets;

    assign axis_out_tdata = {ticks, {(TDATA_WIDTH / 2 - COUNT_WIDTH){1'b0}}, sent_packets[axis_out_tdest]};
    assign axis_out_tlast = 1'b1;
    assign axis_out_tid = TID;
    assign axis_out_tdest = dest_lfsr_out[TDEST_WIDTH - 1 : 0];

    enum {
        IDLE,
        RUNNING
    } state, next_state;

    always @(posedge clk) begin
        if (rst_n == 1'b0 || state == IDLE) begin
            total_sent_packets <= '0;
            for (int i = 0; i < 2**TDEST_WIDTH; i++) begin
                sent_packets[i] <= '0;
            end
        end else begin
            if (axis_out_tready & axis_out_tvalid) begin
                total_sent_packets <= total_sent_packets + 1'b1;
                sent_packets[axis_out_tdest] <= sent_packets[axis_out_tdest] + 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        axis_out_tvalid = 1'b0;
        done = 1'b0;

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
                    axis_out_tvalid = 1'b1;
                end
                if (total_sent_packets >= num_packets) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    lfsr_64 #(.SEED(DEST_SEED)) dest_lfsr_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .ena    (axis_out_tready & axis_out_tvalid),
        .q      (dest_lfsr_out)
    );

    lfsr_16 #(.SEED(LOAD_SEED)) load_lfsr_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .ena    (1'b1),
        .q      (load_lfsr_out)
    );

endmodule: axis_tg

module lfsr_64 #(
    parameter SEED = 64'h48D34421DF9848B) (
    input   wire            clk,
    input   wire            rst_n,

    input   wire            ena,
    output  logic [63 : 0]  q
);

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            q <= SEED;
        end else begin
            if (ena) begin
                q[63 : 1] <= q[62 : 0];
                q[0] <= ~(q[63] ^ q[62] ^ q[60] ^ q[59]);
            end
        end
    end

endmodule: lfsr_64

module lfsr_16 #(
    parameter SEED = 16'h92DA) (
    input   wire            clk,
    input   wire            rst_n,

    input   wire            ena,
    output  logic [15 : 0]  q
);

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            q <= SEED;
        end else begin
            if (ena) begin
                q[15 : 1] <= q[14 : 0];
                q[0] <= ~(q[15] ^ q[14] ^ q[12] ^ q[3]);
            end
        end
    end

endmodule: lfsr_16