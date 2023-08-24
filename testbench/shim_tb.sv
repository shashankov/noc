`timescale 1ns / 1ps

module shim_tb ();

    logic clk_usr, clk_noc, rst_n;

    initial begin
        clk_noc = 1'b1;
        forever #2 clk_noc = ~clk_noc;
    end

    initial begin
        clk_usr = 1'b0;
        forever #8 clk_usr = ~clk_usr;
    end

    logic axis_tvalid_in, axis_tready_in, axis_tlast_in;
    logic [511:0] axis_tdata_in;
    logic [2:0] axis_tdest_in;

    logic axis_tvalid_out, axis_tready_out, axis_tlast_out;
    logic [511:0] axis_tdata_out;
    logic [2:0] axis_tdest_out;

    logic [127:0] data;
    logic [2:0] dest;
    logic is_tail, send;
    logic credit;

    initial begin
        axis_tvalid_in = 1'b0;
        axis_tlast_in = 1'b0;
        axis_tdata_in = 512'h0;
        axis_tdest_in = 3'h0;
        axis_tready_out = 1'b1;
        rst_n = 1'b0;

        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        rst_n = 1'b1;
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        axis_tvalid_in = 1'b1;
        axis_tdata_in = 512'h1;
        axis_tlast_in = 1'b1;
        @(negedge clk_usr);
        axis_tdata_in = 512'h2;
        @(negedge clk_usr);
        axis_tvalid_in = 1'b0;
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        @(negedge clk_usr);
        $finish;
    end

    axis_serializer_shim_in #(
        .TDEST_WIDTH            (3),
        .TDATA_WIDTH            (512),
        .SERIALIZATION_FACTOR   (4),
        .BUFFER_DEPTH           (2),
        .FLIT_BUFFER_DEPTH      (4)
    ) shim_in (
        .clk_usr,
        .clk_noc,

        .rst_n_usr_sync(rst_n),
        .rst_n_noc_sync(rst_n),

        .axis_tvalid(axis_tvalid_in),
        .axis_tready(axis_tready_in),
        .axis_tdata(axis_tdata_in),
        .axis_tlast(axis_tlast_in),
        .axis_tdest(axis_tdest_in),

        .data_out(data),
        .dest_out(dest),
        .is_tail_out(is_tail),
        .send_out(send),
        .credit_in(credit)
    );

    axis_deserializer_shim_out #(
        .TDEST_WIDTH            (3),
        .TDATA_WIDTH            (512),
        .SERIALIZATION_FACTOR   (4),
        .BUFFER_DEPTH           (2),
        .FLIT_BUFFER_DEPTH      (4)
    ) shim_out (
        .clk_usr,
        .clk_noc,

        .rst_n_usr_sync(rst_n),
        .rst_n_noc_sync(rst_n),

        .axis_tvalid(axis_tvalid_out),
        .axis_tready(axis_tready_out),
        .axis_tdata(axis_tdata_out),
        .axis_tlast(axis_tlast_out),
        .axis_tdest(axis_tdest_out),

        .data_in(data),
        .dest_in(dest),
        .is_tail_in(is_tail),
        .send_in(send),
        .credit_out(credit)
    );

endmodule: shim_tb