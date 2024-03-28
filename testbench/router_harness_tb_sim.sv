`timescale 1ns / 1ps

module router_harness_tb_sim();
    localparam FLIT_BUFFER_DEPTH = 8;
    localparam DATA_WIDTH = 64;
    localparam TDEST_WIDTH = 1;
    localparam TID_WIDTH = 1;
    localparam COUNT_WIDTH = 32;
    localparam PACKET_COUNT = 1 << 16;

    localparam SERIALIZATION_FACTOR = 1;
    localparam CLKCROSS_FACTOR = 1;

    localparam SINGLE_CLOCK = ((CLKCROSS_FACTOR == 1) ? 1 : 0);

    localparam USR_CLK_PERIOD = real'(10);
    localparam NOC_CLK_PERIOD = USR_CLK_PERIOD / CLKCROSS_FACTOR;

    localparam USR_CLK_SWITCH = USR_CLK_PERIOD / 2;
    localparam NOC_CLK_SWITCH = NOC_CLK_PERIOD / 2;

    localparam NUM_ENDPOINTS = 2;

    logic clk, clk_noc, rst_n;
    logic [DATA_WIDTH / 2 - 1 : 0] ticks;

    logic                       axis_in_tvalid  [NUM_ENDPOINTS];
    logic                       axis_in_tready  [NUM_ENDPOINTS];
    logic [DATA_WIDTH - 1 : 0]  axis_in_tdata   [NUM_ENDPOINTS];
    logic                       axis_in_tlast   [NUM_ENDPOINTS];
    logic [TDEST_WIDTH - 1 : 0] axis_in_tdest   [NUM_ENDPOINTS];
    logic [TID_WIDTH - 1 : 0]   axis_in_tid     [NUM_ENDPOINTS];

    logic [DATA_WIDTH - 1 : 0]  data_in [NUM_ENDPOINTS];
    logic [TDEST_WIDTH + TID_WIDTH - 1 : 0] dest_in [NUM_ENDPOINTS];
    logic is_tail_in [NUM_ENDPOINTS];
    logic send_in [NUM_ENDPOINTS];
    logic credit_out [NUM_ENDPOINTS];

    logic [DATA_WIDTH - 1 : 0]  data_out [NUM_ENDPOINTS];
    logic [TDEST_WIDTH + TID_WIDTH - 1 : 0] dest_out [NUM_ENDPOINTS];
    logic is_tail_out [NUM_ENDPOINTS];
    logic send_out [NUM_ENDPOINTS];
    logic credit_in [NUM_ENDPOINTS];

    logic                       axis_out_tvalid [NUM_ENDPOINTS];
    logic                       axis_out_tready [NUM_ENDPOINTS];
    logic [DATA_WIDTH - 1 : 0]  axis_out_tdata  [NUM_ENDPOINTS];
    logic                       axis_out_tlast  [NUM_ENDPOINTS];
    logic [TDEST_WIDTH - 1 : 0] axis_out_tdest  [NUM_ENDPOINTS];
    logic [TID_WIDTH - 1 : 0]   axis_out_tid    [NUM_ENDPOINTS];

    logic                       done            [NUM_ENDPOINTS];
    logic                       start           [NUM_ENDPOINTS];
    logic [COUNT_WIDTH - 1 : 0] sent_packets    [NUM_ENDPOINTS][NUM_ENDPOINTS];
    logic [COUNT_WIDTH - 1 : 0] recv_packets    [NUM_ENDPOINTS][NUM_ENDPOINTS];
    logic                       error           [NUM_ENDPOINTS];

    logic [COUNT_WIDTH - 1 : 0] total_recv_packets[NUM_ENDPOINTS], total_sent_packets[NUM_ENDPOINTS];
    logic [COUNT_WIDTH - 1 : 0] sum_recv_packets, sum_sent_packets;

    always_comb begin
        sum_recv_packets = '0;
        sum_sent_packets = '0;
        for (int i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
            sum_recv_packets = sum_recv_packets + total_recv_packets[i];
            sum_sent_packets = sum_sent_packets + total_sent_packets[i];
        end
    end

    always_ff @(posedge clk) begin
        if (rst_n == 0) begin
            ticks <= 0;
        end else begin
            ticks <= ticks + 1'b1;
        end
    end

    initial begin
        clk = 1'b0;
        forever begin
            #USR_CLK_SWITCH clk = ~clk;
        end
    end

    logic all_done;
    logic [15 : 0] load;
    // real sweep_load[] = {0.1, 0.2, 0.3, 0.4, 0.5, 0.525, 0.55, 0.56, 0.57, 0.575, 0.58, 0.585, 0.59, 0.6};
    // real sweep_load[] = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.65, 0.66, 0.67, 0.675, 0.68, 0.685, 0.69, 0.7};
    real sweep_load[] = {0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.65, 0.68, 0.69, 0.7};
    // real sweep_load[] = {0.001, 0.002, 0.003, 0.004, 0.005, 0.006, 0.007, 0.008, 0.009, 0.01};

    initial begin
        rst_n = 1'b0;
        for (int i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
            start[i] = 1'b0;
        end
        for (int load_idx = 0; load_idx < 11; load_idx = load_idx + 1) begin
            load =  int'(((1 << 16) - 1) * sweep_load[load_idx]);
            @(negedge clk);
            $display("Load = %f", $itor(load) / $itor((1 << 16) - 1));
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            rst_n = 1'b1;
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            for (int i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                start[i] = 1'b1;
            end
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);

            forever begin
                @(negedge clk);
                all_done = 1'b1;
                for (int i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                    if (done[i] == 0) begin
                        all_done = 1'b0;
                    end else begin
                        start[i] = 1'b0;
                    end
                end
                if (all_done && (sum_recv_packets == sum_sent_packets)) begin
                    $display("All done! Errors: %d, %d", error[0], error[1]);
                    $fflush;
                    break;
                end else if (ticks >= (1 << 31)) begin
                    $display("Timeout!");
                    break;
                end
            end
            @(negedge clk);
            @(negedge clk);
            @(negedge clk);
            rst_n = 1'b0;
            @(negedge clk);
            @(negedge clk);
        end
        $finish;
    end

    generate begin: harness_gen
        genvar i, j;
        for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin: for_routers
            axis_tg_sim #(
                .SEED           (i * 5 + 2),

                .COUNT_WIDTH    (COUNT_WIDTH),
                .TID            (i),

                .TDATA_WIDTH    (DATA_WIDTH),
                .TDEST_WIDTH    (TDEST_WIDTH),
                .TID_WIDTH      (TID_WIDTH),
                .NUM_ROUTERS    (NUM_ENDPOINTS))
            tg_inst (
                .clk,
                .rst_n,

                .load           (load),
                .num_packets    (PACKET_COUNT),

                .start          (start[i]),
                .ticks,
                .done           (done[i]),
                .sent_packets   (sent_packets[i]),
                .total_sent_packets (total_sent_packets[i]),

                .axis_out_tvalid    (axis_in_tvalid[i]),
                .axis_out_tready    (axis_in_tready[i]),
                .axis_out_tdata     (axis_in_tdata[i]),
                .axis_out_tlast     (axis_in_tlast[i]),
                .axis_out_tid       (axis_in_tid[i]),
                .axis_out_tdest     (axis_in_tdest[i])
            );

            axis_checker #(
                .COUNT_WIDTH    (COUNT_WIDTH),
                .TDEST          (i),

                .TDATA_WIDTH    (DATA_WIDTH),
                .TDEST_WIDTH    (TDEST_WIDTH),
                .TID_WIDTH      (TID_WIDTH),
                .NUM_ROUTERS    (NUM_ENDPOINTS))
            checker_inst (
                .clk,
                .rst_n,

                .ticks,
                .recv_packets       (recv_packets[i]),
                .total_recv_packets (total_recv_packets[i]),
                .error              (error[i]),

                .axis_in_tvalid     (axis_out_tvalid[i]),
                .axis_in_tready     (axis_out_tready[i]),
                .axis_in_tdata      (axis_out_tdata[i]),
                .axis_in_tlast      (axis_out_tlast[i]),
                .axis_in_tid        (axis_out_tid[i]),
                .axis_in_tdest      (axis_out_tdest[i])
            );

            axis_serializer_shim_in #(
                .TDEST_WIDTH(TDEST_WIDTH + TID_WIDTH),
                .TDATA_WIDTH(DATA_WIDTH),
                .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                .SINGLE_CLOCK(SINGLE_CLOCK),
                .BUFFER_DEPTH(16),
                .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                .EXTRA_SYNC_STAGES(0),
                .FORCE_MLAB(1)
            ) shim_in (
                .clk_usr(clk),
                .clk_noc(clk),

                .rst_n_usr_sync(rst_n),
                .rst_n_noc_sync(rst_n),

                .axis_tvalid(axis_in_tvalid[i]),
                .axis_tready(axis_in_tready[i]),
                .axis_tdata(axis_in_tdata[i]),
                .axis_tlast(axis_in_tlast[i]),
                .axis_tdest({axis_in_tid[i], axis_in_tdest[i]}),

                .data_out(data_in[i]),
                .dest_out(dest_in[i]),
                .is_tail_out(is_tail_in[i]),
                .send_out(send_in[i]),
                .credit_in(credit_out[i])
            );

            axis_deserializer_shim_out #(
                .TDEST_WIDTH(TDEST_WIDTH + TID_WIDTH),
                .TDATA_WIDTH(DATA_WIDTH),
                .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                .SINGLE_CLOCK(SINGLE_CLOCK),
                .BUFFER_DEPTH(16),
                .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                .EXTRA_SYNC_STAGES(0),
                .FORCE_MLAB(1)
            ) shim_out (
                .clk_usr(clk),
                .clk_noc(clk),

                .rst_n_usr_sync(rst_n),
                .rst_n_noc_sync(rst_n),

                .axis_tvalid(axis_out_tvalid[i]),
                .axis_tready(axis_out_tready[i]),
                .axis_tdata(axis_out_tdata[i]),
                .axis_tlast(axis_out_tlast[i]),
                .axis_tdest({axis_out_tid[i], axis_out_tdest[i]}),

                .data_in(data_out[i]),
                .dest_in(dest_out[i]),
                .is_tail_in(is_tail_out[i]),
                .send_in(send_out[i]),
                .credit_out(credit_in[i])
            );
        end
    end
    endgenerate

    router #(
        .NOC_NUM_ENDPOINTS(NUM_ENDPOINTS),
        .ROUTING_TABLE_HEX("routing_tables/router_tb_2x2.hex"),
        .NUM_INPUTS(NUM_ENDPOINTS),
        .NUM_OUTPUTS(NUM_ENDPOINTS),
        .DEST_WIDTH(TDEST_WIDTH + TID_WIDTH),
        .FLIT_WIDTH(DATA_WIDTH),
        .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
        .PIPELINE_ROUTE_COMPUTE(1),
        .PIPELINE_ARBITER(1),
        .PIPELINE_OUTPUT(1),
        .DISABLE_SELFLOOP(0),
        .FORCE_MLAB(1)
    ) dut (
        .clk,
        .rst_n,

        .data_in        (data_in),
        .dest_in        (dest_in),
        .is_tail_in     (is_tail_in),
        .send_in        (send_in),
        .credit_out     (credit_out),

        .data_out       (data_out),
        .dest_out       (dest_out),
        .is_tail_out    (is_tail_out),
        .send_out       (send_out),
        .credit_in      (credit_in)
    );

endmodule: router_harness_tb_sim