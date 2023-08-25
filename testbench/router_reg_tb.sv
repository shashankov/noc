`timescale 1ns / 1ps

module router_reg_tb ();

    logic clk, rst_n;

    logic send[2], recv[2], credit_out[2], credit_in[2];
    logic [31:0] data_in[2], data_out[2];
    logic [0:0] dest_in[2], dest_out[2];
    logic is_tail_in[2], is_tail_out[2];

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (rst_n == 1'b0)
            data_in[0] <= 32'h1;
        else if (recv[0] == 1'b1)
            data_in[0] <= data_in[0] + 1'b1;
    end

    initial begin
        data_in[1] = 'x;
        recv[1] = 1'b0;
        recv[0] = 1'b0;
        is_tail_in[1] = 'x;
        is_tail_in[0] = 1'b1;
        dest_in[1] = 'x;
        dest_in[0] = 1'b0;
        rst_n = 1'b0;
        credit_in[0] = 1'b0;
        credit_in[1] = 1'b0;

        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        rst_n = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        recv[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        recv[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        recv[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        recv[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        is_tail_in[0] = 1'b0;
        recv[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        recv[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        recv[0] = 1'b1;
        is_tail_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        is_tail_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        is_tail_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        is_tail_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        is_tail_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        is_tail_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        dest_in[0] = 1'b0;
        recv[0] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        recv[0] = 1'b1;
        recv[1] = 1'b1;
        dest_in[1] = 1'b1;
        is_tail_in[1] = 1'b1;
        data_in[1] = 32'hDEADBEEF;
        is_tail_in[0] = 1'b0;
        is_tail_in[1] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        is_tail_in[1] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b0;
        is_tail_in[1] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        is_tail_in[1] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b0;
        is_tail_in[1] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        is_tail_in[0] = 1'b1;
        is_tail_in[1] = 1'b1;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        recv[0] = 1'b0;
        recv[1] = 1'b0;
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];

        recv[0] = 1'b1;
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        recv[0] = 1'b0;
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b0; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b1; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b1; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b1; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = 1'b1; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];
        @(negedge clk); credit_in[0] = send[0]; credit_in[1] = send[1];

        $finish;
    end

    router #(
        .NOC_NUM_ENDPOINTS  (2),
        .ROUTING_TABLE_HEX  ("routing_tables/router_tb_2x2.hex"),
        .NUM_INPUTS         (2),
        .NUM_OUTPUTS        (2),
        .DEST_WIDTH         (1),
        .FLIT_WIDTH         (32),
        .FLIT_BUFFER_DEPTH  (4),
        .PIPELINE_OUTPUT    (1)
    ) dut (
        .clk,
        .rst_n,

        .data_in     (data_in),
        .dest_in     (dest_in),
        .is_tail_in  (is_tail_in),
        .send_in     (recv),
        .credit_out  (credit_out),

        .data_out    (data_out),
        .dest_out    (dest_out),
        .is_tail_out (is_tail_out),
        .send_out    (send),
        .credit_in   (credit_in)
    );

endmodule: router_reg_tb