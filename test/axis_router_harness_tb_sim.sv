`timescale 1ns / 1ns

module axis_router_harness_tb_sim();
    localparam NUM_INPUTS = 4;
    localparam NUM_OUTPUTS = 10;
    localparam ROUTING_TABLE_PREFIX = "routing_tables/router_4x10/";
    localparam DATA_WIDTH = 64;
    localparam TDEST_WIDTH = $clog2(NUM_OUTPUTS);
    localparam TID_WIDTH = $clog2(NUM_INPUTS);
    localparam COUNT_WIDTH = 32;
    localparam PACKET_COUNT = 1 << 16;

    localparam SERIALIZATION_FACTOR = 1;
    localparam CLKCROSS_FACTOR = 1;

    localparam SINGLE_CLOCK = ((CLKCROSS_FACTOR == 1) ? 1 : 0);

    localparam USR_CLK_PERIOD = real'(10);
    localparam NOC_CLK_PERIOD = USR_CLK_PERIOD / CLKCROSS_FACTOR;

    localparam USR_CLK_SWITCH = USR_CLK_PERIOD / 2;
    localparam NOC_CLK_SWITCH = NOC_CLK_PERIOD / 2;

    logic clk, clk_noc, rst_n;
    logic [DATA_WIDTH / 2 - 1 : 0] ticks;

    logic                       axis_in_tvalid  [NUM_INPUTS];
    logic                       axis_in_tready  [NUM_INPUTS];
    logic [DATA_WIDTH - 1 : 0]  axis_in_tdata   [NUM_INPUTS];
    logic                       axis_in_tlast   [NUM_INPUTS];
    logic [TDEST_WIDTH - 1 : 0] axis_in_tdest   [NUM_INPUTS];
    logic [TID_WIDTH - 1 : 0]   axis_in_tid     [NUM_INPUTS];

    logic                       axis_out_tvalid [NUM_OUTPUTS];
    logic                       axis_out_tready [NUM_OUTPUTS];
    logic [DATA_WIDTH - 1 : 0]  axis_out_tdata  [NUM_OUTPUTS];
    logic                       axis_out_tlast  [NUM_OUTPUTS];
    logic [TDEST_WIDTH - 1 : 0] axis_out_tdest  [NUM_OUTPUTS];
    logic [TID_WIDTH - 1 : 0]   axis_out_tid    [NUM_OUTPUTS];

    logic                       done            [NUM_INPUTS];
    logic                       start           [NUM_INPUTS];
    logic [COUNT_WIDTH - 1 : 0] sent_packets    [NUM_INPUTS][NUM_OUTPUTS];
    logic [COUNT_WIDTH - 1 : 0] recv_packets    [NUM_OUTPUTS][NUM_INPUTS];
    logic                       error           [NUM_OUTPUTS];

    logic [COUNT_WIDTH - 1 : 0] total_recv_packets[NUM_OUTPUTS], total_sent_packets[NUM_INPUTS];
    logic [COUNT_WIDTH - 1 : 0] sum_recv_packets, sum_sent_packets;

    always_comb begin
        sum_recv_packets = '0;
        sum_sent_packets = '0;
        for (int j = 0; j < NUM_OUTPUTS; j = j + 1) begin
            sum_recv_packets = sum_recv_packets + total_recv_packets[j];
        end
        for (int i = 0; i < NUM_INPUTS; i = i + 1) begin
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

    initial begin
        clk_noc = 1'b0;
        forever begin
            #NOC_CLK_SWITCH clk_noc = ~clk_noc;
        end
    end

    logic all_done;
    logic [15 : 0] load;
    // real sweep_load[] = {0.1, 0.2, 0.3, 0.4, 0.5, 0.525, 0.55, 0.56, 0.57, 0.575, 0.58, 0.585, 0.59, 0.6};
    // real sweep_load[] = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.65, 0.66, 0.67, 0.675, 0.68, 0.685, 0.69, 0.7};
    real sweep_load[] = {0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.65, 0.68, 0.69, 0.7, 0.8};
    // real sweep_load[] = {0.001, 0.002, 0.003, 0.004, 0.005, 0.006, 0.007, 0.008, 0.009, 0.01};

    initial begin
        rst_n = 1'b0;
        for (int i = 0; i < NUM_INPUTS; i = i + 1) begin
            start[i] = 1'b0;
        end
        for (int load_idx = 0; load_idx < 12; load_idx = load_idx + 1) begin
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
            for (int i = 0; i < NUM_INPUTS; i = i + 1) begin
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
                for (int i = 0; i < NUM_INPUTS; i = i + 1) begin
                    if (done[i] == 0) begin
                        all_done = 1'b0;
                    end else begin
                        start[i] = 1'b0;
                    end
                end
                if (all_done && (sum_recv_packets == sum_sent_packets)) begin
                    $write("All done! Errors: ");
                    for (int j = 0; j < NUM_OUTPUTS; j = j + 1) begin
                        $write("%1d: %1d ", j, error[j]);
                    end
                    $write("\n");
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
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin: for_inputs
            axis_tg_sim #(
                .SEED           (i * 5 + 2),

                .COUNT_WIDTH    (COUNT_WIDTH),
                .TID            (i),

                .TDATA_WIDTH    (DATA_WIDTH),
                .TDEST_WIDTH    (TDEST_WIDTH),
                .TID_WIDTH      (TID_WIDTH),
                .NUM_ROUTERS    (NUM_OUTPUTS))
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
        end
        for (j = 0; j < NUM_OUTPUTS; j = j + 1) begin: for_outputs
            axis_checker #(
                .COUNT_WIDTH    (COUNT_WIDTH),
                .TDEST          (j),

                .TDATA_WIDTH    (DATA_WIDTH),
                .TDEST_WIDTH    (TDEST_WIDTH),
                .TID_WIDTH      (TID_WIDTH),
                .NUM_ROUTERS    (NUM_INPUTS))
            checker_inst (
                .clk,
                .rst_n,

                .ticks,
                .recv_packets       (recv_packets[j]),
                .total_recv_packets (total_recv_packets[j]),
                .error              (error[j]),

                .axis_in_tvalid     (axis_out_tvalid[j]),
                .axis_in_tready     (axis_out_tready[j]),
                .axis_in_tdata      (axis_out_tdata[j]),
                .axis_in_tlast      (axis_out_tlast[j]),
                .axis_in_tid        (axis_out_tid[j]),
                .axis_in_tdest      (axis_out_tdest[j])
            );
        end
    end
    endgenerate

    axis_router #(
        .NUM_INPUTS                     (NUM_INPUTS),
        .NUM_OUTPUTS                    (NUM_OUTPUTS),

        .TID_WIDTH                      (TID_WIDTH),
        .TDEST_WIDTH                    (TDEST_WIDTH),
        .TDATA_WIDTH                    (DATA_WIDTH),
        .SERIALIZATION_FACTOR           (SERIALIZATION_FACTOR),
        .CLKCROSS_FACTOR                (CLKCROSS_FACTOR),
        .SINGLE_CLOCK                   (SINGLE_CLOCK),
        .SERDES_IN_BUFFER_DEPTH         (4),
        .SERDES_OUT_BUFFER_DEPTH        (32),
        .SERDES_EXTRA_SYNC_STAGES       (0),

        .FLIT_BUFFER_DEPTH              (8),
        .ROUTING_TABLE_PREFIX           (ROUTING_TABLE_PREFIX),
        .ROUTER_PIPELINE_ROUTE_COMPUTE  (1),
        .ROUTER_PIPELINE_ARBITER        (0),
        .ROUTER_PIPELINE_OUTPUT         (1),
        .ROUTER_FORCE_MLAB              (0)
    ) dut (
        .clk_noc(clk_noc),
        .clk_usr(clk),
        .rst_n,

        .axis_in_tvalid ,
        .axis_in_tready ,
        .axis_in_tdata  ,
        .axis_in_tlast  ,
        .axis_in_tid    ,
        .axis_in_tdest  ,

        .axis_out_tvalid,
        .axis_out_tready,
        .axis_out_tdata ,
        .axis_out_tlast ,
        .axis_out_tid   ,
        .axis_out_tdest
    );

endmodule: axis_router_harness_tb_sim
