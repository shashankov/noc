`timescale 1ns / 1ns

module generic_harness_tb_sim();
    // ========================================================================
    // Topology / DUT Parameters (override from command line for any topology)
    // ========================================================================
    parameter string TOPOLOGY    = "router";
    parameter NUM_INPUTS  = 4;
    parameter NUM_OUTPUTS = 4;
    parameter string ROUTING_TABLE_PREFIX = "routing_tables/router_4x4/";
    parameter NUM_ROWS    = 2;
    parameter NUM_COLS    = 2;
    parameter K           = 2;
    parameter N           = 2;
    parameter string OPTIMIZE_FOR_ROUTING = "XY";
    parameter bit DISABLE_SELFLOOP = 0;

    // ========================================================================
    // Data Path Parameters
    // ========================================================================
    parameter DATA_WIDTH  = 64;
    parameter TDEST_WIDTH = $clog2(NUM_OUTPUTS);
    parameter TID_WIDTH   = $clog2(NUM_INPUTS);
    parameter COUNT_WIDTH = 32;

    // ========================================================================
    // Load, Packet Count & Timeout Parameters
    // ========================================================================
    parameter PACKET_COUNT      = 1 << 10;
    parameter real LOAD         = 0.5;
    parameter TIMEOUT_CYCLES    = PACKET_COUNT * 200 + 100000;

    // ========================================================================
    // SerDes / Clock Crossing Parameters
    // ========================================================================
    parameter SERIALIZATION_FACTOR = 1;
    parameter CLKCROSS_FACTOR      = 1;
    parameter SINGLE_CLOCK = ((CLKCROSS_FACTOR == 1) ? 1 : 0);
    parameter SERDES_IN_BUFFER_DEPTH = 4;
    parameter SERDES_OUT_BUFFER_DEPTH = 32;
    parameter SERDES_EXTRA_SYNC_STAGES = 0;
    parameter bit SERDES_FORCE_MLAB = 0;
    parameter RESET_SYNC_EXTEND_CYCLES = 2;
    parameter RESET_NUM_OUTPUT_REGISTERS = 1;
    parameter PIPELINE_LINKS = 0;
    parameter EXTRA_PIPELINE_LONG_LINKS = 0;

    // ========================================================================
    // Router Microarchitecture Parameters
    // ========================================================================
    parameter FLIT_BUFFER_DEPTH              = 8;
    parameter ROUTER_PIPELINE_ROUTE_COMPUTE  = 1;
    parameter ROUTER_PIPELINE_ARBITER        = 0;
    parameter ROUTER_PIPELINE_OUTPUT         = 1;
    parameter ROUTER_FORCE_MLAB              = 0;

    // ========================================================================
    // Clock Parameters
    // ========================================================================
    localparam USR_CLK_PERIOD = real'(10);
    localparam NOC_CLK_PERIOD = USR_CLK_PERIOD / CLKCROSS_FACTOR;

    localparam USR_CLK_SWITCH = USR_CLK_PERIOD / 2;
    localparam NOC_CLK_SWITCH = NOC_CLK_PERIOD / 2;

    // ========================================================================
    // Signals
    // ========================================================================
    logic clk, clk_noc, rst_n;
    logic [DATA_WIDTH / 2 - 1 : 0] ticks;

    // AXI-Stream input interface (from traffic generators to DUT)
    logic                       axis_in_tvalid  [NUM_INPUTS];
    logic                       axis_in_tready  [NUM_INPUTS];
    logic [DATA_WIDTH - 1 : 0]  axis_in_tdata   [NUM_INPUTS];
    logic                       axis_in_tlast   [NUM_INPUTS];
    logic [TDEST_WIDTH - 1 : 0] axis_in_tdest   [NUM_INPUTS];
    logic [TID_WIDTH - 1 : 0]   axis_in_tid     [NUM_INPUTS];

    // AXI-Stream output interface (from DUT to checkers)
    logic                       axis_out_tvalid [NUM_OUTPUTS];
    logic                       axis_out_tready [NUM_OUTPUTS];
    logic [DATA_WIDTH - 1 : 0]  axis_out_tdata  [NUM_OUTPUTS];
    logic                       axis_out_tlast  [NUM_OUTPUTS];
    logic [TDEST_WIDTH - 1 : 0] axis_out_tdest  [NUM_OUTPUTS];
    logic [TID_WIDTH - 1 : 0]   axis_out_tid    [NUM_OUTPUTS];

    // Traffic generator / checker control signals
    logic                       done            [NUM_INPUTS];
    logic                       start           [NUM_INPUTS];
    logic [COUNT_WIDTH - 1 : 0] sent_packets    [NUM_INPUTS][NUM_OUTPUTS];
    logic [COUNT_WIDTH - 1 : 0] recv_packets    [NUM_OUTPUTS][NUM_INPUTS];
    logic                       error           [NUM_OUTPUTS];

    logic [COUNT_WIDTH - 1 : 0] total_recv_packets[NUM_OUTPUTS];
    logic [COUNT_WIDTH - 1 : 0] total_sent_packets[NUM_INPUTS];
    logic [COUNT_WIDTH - 1 : 0] sum_recv_packets, sum_sent_packets;

    // ========================================================================
    // Packet Sum Logic
    // ========================================================================
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

    // ========================================================================
    // Tick Counter
    // ========================================================================
    always_ff @(posedge clk) begin
        if (rst_n == 0) begin
            ticks <= 0;
        end else begin
            ticks <= ticks + 1'b1;
        end
    end

    // ========================================================================
    // Clock Generation
    // ========================================================================
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

    // ========================================================================
    // Load Control
    // ========================================================================
    logic all_done;
    logic [15 : 0] load;
    logic any_error;
    int   total_errors;

    // ========================================================================
    // Main Test Sequence
    // ========================================================================
    initial begin
        $display("=============================================================");
        $display("Generic Harness Testbench");
        $display("  PACKET_COUNT   = %0d", PACKET_COUNT);
        $display("  LOAD           = %f", LOAD);
        $display("  TIMEOUT_CYCLES = %0d", TIMEOUT_CYCLES);
        if (SERIALIZATION_FACTOR > 1 || CLKCROSS_FACTOR > 1) begin
            $display("  SERIALIZATION_FACTOR       = %0d", SERIALIZATION_FACTOR);
            $display("  CLKCROSS_FACTOR            = %0d", CLKCROSS_FACTOR);
            $display("  SINGLE_CLOCK               = %0d", SINGLE_CLOCK);
            $display("  SERDES_IN_BUFFER_DEPTH     = %0d", SERDES_IN_BUFFER_DEPTH);
            $display("  SERDES_OUT_BUFFER_DEPTH    = %0d", SERDES_OUT_BUFFER_DEPTH);
            $display("  SERDES_EXTRA_SYNC_STAGES   = %0d", SERDES_EXTRA_SYNC_STAGES);
            $display("  SERDES_FORCE_MLAB          = %0d", SERDES_FORCE_MLAB);
        end
        $display("  RESET_SYNC_EXTEND_CYCLES   = %0d", RESET_SYNC_EXTEND_CYCLES);
        $display("  RESET_NUM_OUTPUT_REGISTERS = %0d", RESET_NUM_OUTPUT_REGISTERS);
        $display("  PIPELINE_LINKS             = %0d", PIPELINE_LINKS);
        $display("  EXTRA_PIPELINE_LONG_LINKS  = %0d", EXTRA_PIPELINE_LONG_LINKS);
        $display("=============================================================");

        total_errors = 0;
        rst_n = 1'b0;
        for (int i = 0; i < NUM_INPUTS; i = i + 1) begin
            start[i] = 1'b0;
        end

        load = int'(((1 << 16) - 1) * LOAD);
        @(negedge clk);
        $display("-------------------------------------------------------------");
        $display("Testing Load = %f", $itor(load) / $itor((1 << 16) - 1));
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
                any_error = 1'b0;
                $write("All done! Errors: ");
                for (int j = 0; j < NUM_OUTPUTS; j = j + 1) begin
                    $write("%1d: %1d ", j, error[j]);
                    if (error[j]) begin
                        any_error = 1'b1;
                        total_errors = total_errors + 1;
                    end
                end
                $write("\n");
                if (any_error)
                    $display("  ** FAIL **");
                else
                    $display("  PASS");
                $fflush;
                break;
            end else if (ticks >= TIMEOUT_CYCLES) begin
                $display("Timeout!");
                total_errors = total_errors + 1;
                break;
            end
        end
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b0;
        @(negedge clk);
        @(negedge clk);

        $display("=============================================================");
        if (total_errors == 0)
            $display("TEST PASSED");
        else
            $error("FAILURES DETECTED: %0d total errors", total_errors);
        $display("=============================================================");
        $finish;

    end

    // ========================================================================
    // Traffic Generators (one per input port)
    // ========================================================================
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

        // ==================================================================
        // Checkers (one per output port)
        // ==================================================================
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

    // ========================================================================
    // DUT: axis_topology_wrapper (standardized topology wrapper)
    // ========================================================================
    axis_topology_wrapper #(
        .TOPOLOGY                       (TOPOLOGY),
        .NUM_INPUTS                     (NUM_INPUTS),
        .NUM_OUTPUTS                    (NUM_OUTPUTS),
        .NUM_ROWS                       (NUM_ROWS),
        .NUM_COLS                       (NUM_COLS),
        .K                              (K),
        .N                              (N),

        .TID_WIDTH                      (TID_WIDTH),
        .TDEST_WIDTH                    (TDEST_WIDTH),
        .TDATA_WIDTH                    (DATA_WIDTH),
        .RESET_SYNC_EXTEND_CYCLES       (RESET_SYNC_EXTEND_CYCLES),
        .RESET_NUM_OUTPUT_REGISTERS     (RESET_NUM_OUTPUT_REGISTERS),
        .PIPELINE_LINKS                 (PIPELINE_LINKS),
        .EXTRA_PIPELINE_LONG_LINKS      (EXTRA_PIPELINE_LONG_LINKS),

        .SERIALIZATION_FACTOR           (SERIALIZATION_FACTOR),
        .CLKCROSS_FACTOR                (CLKCROSS_FACTOR),
        .SINGLE_CLOCK                   (SINGLE_CLOCK),
        .SERDES_IN_BUFFER_DEPTH         (SERDES_IN_BUFFER_DEPTH),
        .SERDES_OUT_BUFFER_DEPTH        (SERDES_OUT_BUFFER_DEPTH),
        .SERDES_EXTRA_SYNC_STAGES       (SERDES_EXTRA_SYNC_STAGES),
        .SERDES_FORCE_MLAB              (SERDES_FORCE_MLAB),

        .FLIT_BUFFER_DEPTH              (FLIT_BUFFER_DEPTH),
        .ROUTING_TABLE_PREFIX           (ROUTING_TABLE_PREFIX),
        .OPTIMIZE_FOR_ROUTING           (OPTIMIZE_FOR_ROUTING),
        .DISABLE_SELFLOOP               (DISABLE_SELFLOOP),
        .ROUTER_PIPELINE_ROUTE_COMPUTE  (ROUTER_PIPELINE_ROUTE_COMPUTE),
        .ROUTER_PIPELINE_ARBITER        (ROUTER_PIPELINE_ARBITER),
        .ROUTER_PIPELINE_OUTPUT         (ROUTER_PIPELINE_OUTPUT),
        .ROUTER_FORCE_MLAB              (ROUTER_FORCE_MLAB)
    ) dut (
        .clk_noc(clk_noc),
        .clk_usr(clk),
        .rst_n,

        .axis_in_tvalid,
        .axis_in_tready,
        .axis_in_tdata,
        .axis_in_tlast,
        .axis_in_tid,
        .axis_in_tdest,

        .axis_out_tvalid,
        .axis_out_tready,
        .axis_out_tdata,
        .axis_out_tlast,
        .axis_out_tid,
        .axis_out_tdest
    );

endmodule: generic_harness_tb_sim
