`timescale 1ns / 1ps
// Implements uniform random traffic generation

module axis_checker #(
    parameter COUNT_WIDTH = 32,
    parameter TDEST = 0,

    parameter TDATA_WIDTH = 512,
    parameter TDEST_WIDTH = 2,
    parameter TID_WIDTH = 2) (
    input   wire                                clk,
    input   wire                                rst_n,

    input   wire    [TDATA_WIDTH / 2 - 1 : 0]   ticks,
    output  logic   [COUNT_WIDTH - 1 : 0]       recv_packets[2 ** TID_WIDTH],
    output  logic                               error,

    input   wire                                axis_in_tvalid,
    output  logic                               axis_in_tready,
    input   wire    [TDATA_WIDTH - 1 : 0]       axis_in_tdata,
    input   wire                                axis_in_tlast,
    input   wire    [TID_WIDTH - 1 : 0]         axis_in_tid,
    input   wire    [TDEST_WIDTH - 1 : 0]       axis_in_tdest
);
    logic [TDATA_WIDTH / 2 - 1 : 0] sent_tick;
    logic [COUNT_WIDTH - 1 : 0] sent_count;

    assign sent_tick = axis_in_tdata[TDATA_WIDTH - 1 : TDATA_WIDTH / 2];
    assign sent_count = axis_in_tdata[COUNT_WIDTH - 1 : 0];
    assign axis_in_tready = 1'b1;

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            for (int i = 0; i < 2 ** TID_WIDTH; i = i + 1) begin
                recv_packets[i] <= '0;
            end
            error <= 1'b0;
        end else begin
            if (axis_in_tvalid) begin
                recv_packets[axis_in_tid] <= recv_packets[axis_in_tid] + 1'b1;
                if ((sent_count != recv_packets[axis_in_tid]) || (axis_in_tdest != TDEST)) begin
                    error <= 1'b1;
                end
            end
        end
    end

endmodule: axis_checker