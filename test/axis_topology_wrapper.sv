`timescale 1ns / 1ns

module axis_topology_wrapper #(
    parameter string TOPOLOGY = "router",
    parameter NUM_INPUTS = 4,
    parameter NUM_OUTPUTS = 4,
    
    // Topology geometry parameters
    parameter NUM_ROWS = 2,
    parameter NUM_COLS = 2,
    parameter K = 2,
    parameter N = 2,
    
    parameter RESET_SYNC_EXTEND_CYCLES = 2,
    parameter RESET_NUM_OUTPUT_REGISTERS = 1,
    parameter PIPELINE_LINKS = 0,
    parameter EXTRA_PIPELINE_LONG_LINKS = 0,
    
    parameter TID_WIDTH = 2,
    parameter TDEST_WIDTH = 4,
    parameter TDATA_WIDTH = 64,
    
    parameter SERIALIZATION_FACTOR = 1,
    parameter CLKCROSS_FACTOR = 1,
    parameter bit SINGLE_CLOCK = 1,
    parameter SERDES_IN_BUFFER_DEPTH = 4,
    parameter SERDES_OUT_BUFFER_DEPTH = 4,
    parameter SERDES_EXTRA_SYNC_STAGES = 0,
    parameter bit SERDES_FORCE_MLAB = 0,
    
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter string ROUTING_TABLE_PREFIX = "routing_tables/router_4x4/",
    parameter string OPTIMIZE_FOR_ROUTING = "XY",
    parameter bit DISABLE_SELFLOOP = 1,
    
    parameter bit ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter bit ROUTER_PIPELINE_ARBITER = 0,
    parameter bit ROUTER_PIPELINE_OUTPUT = 1,
    parameter bit ROUTER_FORCE_MLAB = 0
) (
    input   wire    clk_noc,
    input   wire    clk_usr,
    input   wire    rst_n,

    input   wire                            axis_in_tvalid  [NUM_INPUTS],
    output  logic                           axis_in_tready  [NUM_INPUTS],
    input   wire    [TDATA_WIDTH - 1 : 0]   axis_in_tdata   [NUM_INPUTS],
    input   wire                            axis_in_tlast   [NUM_INPUTS],
    input   wire    [TID_WIDTH - 1 : 0]     axis_in_tid     [NUM_INPUTS],
    input   wire    [TDEST_WIDTH - 1 : 0]   axis_in_tdest   [NUM_INPUTS],

    output  logic                           axis_out_tvalid [NUM_OUTPUTS],
    input   wire                            axis_out_tready [NUM_OUTPUTS],
    output  logic   [TDATA_WIDTH - 1 : 0]   axis_out_tdata  [NUM_OUTPUTS],
    output  logic                           axis_out_tlast  [NUM_OUTPUTS],
    output  logic   [TID_WIDTH - 1 : 0]     axis_out_tid    [NUM_OUTPUTS],
    output  logic   [TDEST_WIDTH - 1 : 0]   axis_out_tdest  [NUM_OUTPUTS]
);

    initial begin
        // Parameter validation checks
        if (TOPOLOGY == "ring" || TOPOLOGY == "double_ring") begin
            if (NUM_INPUTS != NUM_OUTPUTS) begin
                $fatal(1, "Error: Ring/Double Ring topologies require NUM_INPUTS (%0d) == NUM_OUTPUTS (%0d)", NUM_INPUTS, NUM_OUTPUTS);
            end
        end else if (TOPOLOGY == "butterfly") begin
            if (NUM_INPUTS > K ** N) begin
                $fatal(1, "Error: Butterfly topology requires NUM_INPUTS (%0d) <= K ** N (%0d)", NUM_INPUTS, K ** N);
            end
            if (NUM_OUTPUTS > K ** N) begin
                $fatal(1, "Error: Butterfly topology requires NUM_OUTPUTS (%0d) <= K ** N (%0d)", NUM_OUTPUTS, K ** N);
            end
        end else if (TOPOLOGY == "mesh" || TOPOLOGY == "torus" || TOPOLOGY == "directional_torus") begin
            if (NUM_INPUTS > NUM_ROWS * NUM_COLS) begin
                $fatal(1, "Error: %s topology requires NUM_INPUTS (%0d) <= NUM_ROWS * NUM_COLS (%0d)", TOPOLOGY, NUM_INPUTS, NUM_ROWS * NUM_COLS);
            end
            if (NUM_OUTPUTS > NUM_ROWS * NUM_COLS) begin
                $fatal(1, "Error: %s topology requires NUM_OUTPUTS (%0d) <= NUM_ROWS * NUM_COLS (%0d)", TOPOLOGY, NUM_OUTPUTS, NUM_ROWS * NUM_COLS);
            end
        end

        $display("=============================================================");
        $display("NoC Topology Wrapper Configuration");
        $display("  TOPOLOGY             = %s", TOPOLOGY);
        $display("  NUM_INPUTS           = %0d", NUM_INPUTS);
        $display("  NUM_OUTPUTS          = %0d", NUM_OUTPUTS);
        if (TOPOLOGY == "router") begin
            $display("  ROUTING_TABLE_PREFIX = %s", ROUTING_TABLE_PREFIX);
        end else if (TOPOLOGY == "ring") begin
            $display("  NUM_ROUTERS          = %0d", NUM_INPUTS);
            $display("  PIPELINE_LINKS       = %0d", PIPELINE_LINKS);
            $display("  ROUTING_TABLE_PREFIX = %s", ROUTING_TABLE_PREFIX);
        end else if (TOPOLOGY == "double_ring") begin
            $display("  NUM_ROUTERS          = %0d", NUM_INPUTS);
            $display("  ROUTING_TABLE_PREFIX = %s", ROUTING_TABLE_PREFIX);
        end else if (TOPOLOGY == "butterfly") begin
            $display("  K                    = %0d", K);
            $display("  N                    = %0d", N);
            $display("  BUTTERFLY_PORTS      = %0d", K ** N);
            $display("  ROUTING_TABLE_PREFIX = %s", ROUTING_TABLE_PREFIX);
        end else if (TOPOLOGY == "mesh") begin
            $display("  NUM_ROWS             = %0d", NUM_ROWS);
            $display("  NUM_COLS             = %0d", NUM_COLS);
            $display("  PIPELINE_LINKS       = %0d", PIPELINE_LINKS);
            $display("  OPTIMIZE_FOR_ROUTING = %s", OPTIMIZE_FOR_ROUTING);
            $display("  ROUTING_TABLE_PREFIX = %s", ROUTING_TABLE_PREFIX);
        end else if (TOPOLOGY == "torus") begin
            $display("  NUM_ROWS             = %0d", NUM_ROWS);
            $display("  NUM_COLS             = %0d", NUM_COLS);
            $display("  PIPELINE_LINKS       = %0d", PIPELINE_LINKS);
            $display("  EXTRA_PIPELINE_LONG  = %0d", EXTRA_PIPELINE_LONG_LINKS);
            $display("  OPTIMIZE_FOR_ROUTING = %s", OPTIMIZE_FOR_ROUTING);
            $display("  ROUTING_TABLE_PREFIX = %s", ROUTING_TABLE_PREFIX);
        end else if (TOPOLOGY == "directional_torus") begin
            $display("  NUM_ROWS             = %0d", NUM_ROWS);
            $display("  NUM_COLS             = %0d", NUM_COLS);
            $display("  PIPELINE_LINKS       = %0d", PIPELINE_LINKS);
            $display("  EXTRA_PIPELINE_LONG  = %0d", EXTRA_PIPELINE_LONG_LINKS);
            $display("  OPTIMIZE_FOR_ROUTING = %s", OPTIMIZE_FOR_ROUTING);
            $display("  ROUTING_TABLE_PREFIX = %s", ROUTING_TABLE_PREFIX);
        end
        $display("  FLIT_BUFFER_DEPTH    = %0d", FLIT_BUFFER_DEPTH);
        if (SERIALIZATION_FACTOR > 1 || CLKCROSS_FACTOR > 1) begin
            $display("  SERIALIZATION_FACTOR = %0d", SERIALIZATION_FACTOR);
            $display("  CLKCROSS_FACTOR      = %0d", CLKCROSS_FACTOR);
            $display("  SINGLE_CLOCK         = %0d", SINGLE_CLOCK);
        end
        $display("=============================================================");
    end

    generate
        if (TOPOLOGY == "router") begin: g_router
            logic                            router_in_tvalid   [NUM_INPUTS];
            logic                            router_in_tready   [NUM_INPUTS];
            logic [TDATA_WIDTH - 1 : 0]      router_in_tdata    [NUM_INPUTS];
            logic                            router_in_tlast    [NUM_INPUTS];
            logic [TID_WIDTH - 1 : 0]        router_in_tid      [NUM_INPUTS];
            logic [TDEST_WIDTH - 1 : 0]      router_in_tdest    [NUM_INPUTS];

            logic                            router_out_tvalid  [NUM_OUTPUTS];
            logic                            router_out_tready  [NUM_OUTPUTS];
            logic [TDATA_WIDTH - 1 : 0]      router_out_tdata   [NUM_OUTPUTS];
            logic                            router_out_tlast   [NUM_OUTPUTS];
            logic [TID_WIDTH - 1 : 0]        router_out_tid     [NUM_OUTPUTS];
            logic [TDEST_WIDTH - 1 : 0]      router_out_tdest   [NUM_OUTPUTS];

            genvar i, j;
            for (i = 0; i < NUM_INPUTS; i = i + 1) begin: map_in
                assign router_in_tvalid[i] = axis_in_tvalid[i];
                assign axis_in_tready[i]   = router_in_tready[i];
                assign router_in_tdata[i]  = axis_in_tdata[i];
                assign router_in_tlast[i]  = axis_in_tlast[i];
                assign router_in_tid[i]    = axis_in_tid[i];
                assign router_in_tdest[i]  = axis_in_tdest[i];
            end
            for (j = 0; j < NUM_OUTPUTS; j = j + 1) begin: map_out
                assign axis_out_tvalid[j]   = router_out_tvalid[j];
                assign router_out_tready[j] = axis_out_tready[j];
                assign axis_out_tdata[j]    = router_out_tdata[j];
                assign axis_out_tlast[j]    = router_out_tlast[j];
                assign axis_out_tid[j]      = router_out_tid[j];
                assign axis_out_tdest[j]    = router_out_tdest[j];
            end

            axis_router #(
                .RESET_SYNC_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
                .RESET_NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS),
                .NUM_INPUTS(NUM_INPUTS),
                .NUM_OUTPUTS(NUM_OUTPUTS),
                .TID_WIDTH(TID_WIDTH),
                .TDEST_WIDTH(TDEST_WIDTH),
                .TDATA_WIDTH(TDATA_WIDTH),
                .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                .SINGLE_CLOCK(SINGLE_CLOCK),
                .SERDES_IN_BUFFER_DEPTH(SERDES_IN_BUFFER_DEPTH),
                .SERDES_OUT_BUFFER_DEPTH(SERDES_OUT_BUFFER_DEPTH),
                .SERDES_EXTRA_SYNC_STAGES(SERDES_EXTRA_SYNC_STAGES),
                .SERDES_FORCE_MLAB(SERDES_FORCE_MLAB),
                .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                .ROUTING_TABLE_PREFIX(ROUTING_TABLE_PREFIX),
                .ROUTER_PIPELINE_ROUTE_COMPUTE(ROUTER_PIPELINE_ROUTE_COMPUTE),
                .ROUTER_PIPELINE_ARBITER(ROUTER_PIPELINE_ARBITER),
                .ROUTER_PIPELINE_OUTPUT(ROUTER_PIPELINE_OUTPUT),
                .ROUTER_FORCE_MLAB(ROUTER_FORCE_MLAB)
            ) router_inst (
                .clk_noc,
                .clk_usr,
                .rst_n,
                .axis_in_tvalid(router_in_tvalid),
                .axis_in_tready(router_in_tready),
                .axis_in_tdata(router_in_tdata),
                .axis_in_tlast(router_in_tlast),
                .axis_in_tid(router_in_tid),
                .axis_in_tdest(router_in_tdest),
                .axis_out_tvalid(router_out_tvalid),
                .axis_out_tready(router_out_tready),
                .axis_out_tdata(router_out_tdata),
                .axis_out_tlast(router_out_tlast),
                .axis_out_tid(router_out_tid),
                .axis_out_tdest(router_out_tdest)
            );
        end
        else if (TOPOLOGY == "ring") begin: g_ring
            logic                            ring_in_tvalid   [NUM_INPUTS];
            logic                            ring_in_tready   [NUM_INPUTS];
            logic [TDATA_WIDTH - 1 : 0]      ring_in_tdata    [NUM_INPUTS];
            logic                            ring_in_tlast    [NUM_INPUTS];
            logic [TID_WIDTH - 1 : 0]        ring_in_tid      [NUM_INPUTS];
            logic [TDEST_WIDTH - 1 : 0]      ring_in_tdest    [NUM_INPUTS];

            logic                            ring_out_tvalid  [NUM_OUTPUTS];
            logic                            ring_out_tready  [NUM_OUTPUTS];
            logic [TDATA_WIDTH - 1 : 0]      ring_out_tdata   [NUM_OUTPUTS];
            logic                            ring_out_tlast   [NUM_OUTPUTS];
            logic [TID_WIDTH - 1 : 0]        ring_out_tid     [NUM_OUTPUTS];
            logic [TDEST_WIDTH - 1 : 0]      ring_out_tdest   [NUM_OUTPUTS];

            genvar i;
            for (i = 0; i < NUM_INPUTS; i = i + 1) begin: map_ring
                assign ring_in_tvalid[i] = axis_in_tvalid[i];
                assign axis_in_tready[i] = ring_in_tready[i];
                assign ring_in_tdata[i]  = axis_in_tdata[i];
                assign ring_in_tlast[i]  = axis_in_tlast[i];
                assign ring_in_tid[i]    = axis_in_tid[i];
                assign ring_in_tdest[i]  = axis_in_tdest[i];

                assign axis_out_tvalid[i] = ring_out_tvalid[i];
                assign ring_out_tready[i] = axis_out_tready[i];
                assign axis_out_tdata[i]  = ring_out_tdata[i];
                assign axis_out_tlast[i]  = ring_out_tlast[i];
                assign axis_out_tid[i]    = ring_out_tid[i];
                assign axis_out_tdest[i]  = ring_out_tdest[i];
            end

            axis_ring #(
                .RESET_SYNC_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
                .RESET_NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS),
                .NUM_ROUTERS(NUM_INPUTS),
                .PIPELINE_LINKS(PIPELINE_LINKS),
                .TID_WIDTH(TID_WIDTH),
                .TDEST_WIDTH(TDEST_WIDTH),
                .TDATA_WIDTH(TDATA_WIDTH),
                .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                .SINGLE_CLOCK(SINGLE_CLOCK),
                .SERDES_IN_BUFFER_DEPTH(SERDES_IN_BUFFER_DEPTH),
                .SERDES_OUT_BUFFER_DEPTH(SERDES_OUT_BUFFER_DEPTH),
                .SERDES_EXTRA_SYNC_STAGES(SERDES_EXTRA_SYNC_STAGES),
                .SERDES_FORCE_MLAB(SERDES_FORCE_MLAB),
                .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                .ROUTING_TABLE_PREFIX(ROUTING_TABLE_PREFIX),
                .DISABLE_SELFLOOP(DISABLE_SELFLOOP),
                .ROUTER_PIPELINE_ROUTE_COMPUTE(ROUTER_PIPELINE_ROUTE_COMPUTE),
                .ROUTER_PIPELINE_ARBITER(ROUTER_PIPELINE_ARBITER),
                .ROUTER_PIPELINE_OUTPUT(ROUTER_PIPELINE_OUTPUT),
                .ROUTER_FORCE_MLAB(ROUTER_FORCE_MLAB)
            ) ring_inst (
                .clk_noc,
                .clk_usr,
                .rst_n,
                .axis_in_tvalid(ring_in_tvalid),
                .axis_in_tready(ring_in_tready),
                .axis_in_tdata(ring_in_tdata),
                .axis_in_tlast(ring_in_tlast),
                .axis_in_tid(ring_in_tid),
                .axis_in_tdest(ring_in_tdest),
                .axis_out_tvalid(ring_out_tvalid),
                .axis_out_tready(ring_out_tready),
                .axis_out_tdata(ring_out_tdata),
                .axis_out_tlast(ring_out_tlast),
                .axis_out_tid(ring_out_tid),
                .axis_out_tdest(ring_out_tdest)
            );
        end
        else if (TOPOLOGY == "double_ring") begin: g_double_ring
            logic                            dring_in_tvalid   [NUM_INPUTS];
            logic                            dring_in_tready   [NUM_INPUTS];
            logic [TDATA_WIDTH - 1 : 0]      dring_in_tdata    [NUM_INPUTS];
            logic                            dring_in_tlast    [NUM_INPUTS];
            logic [TID_WIDTH - 1 : 0]        dring_in_tid      [NUM_INPUTS];
            logic [TDEST_WIDTH - 1 : 0]      dring_in_tdest    [NUM_INPUTS];

            logic                            dring_out_tvalid  [NUM_OUTPUTS];
            logic                            dring_out_tready  [NUM_OUTPUTS];
            logic [TDATA_WIDTH - 1 : 0]      dring_out_tdata   [NUM_OUTPUTS];
            logic                            dring_out_tlast   [NUM_OUTPUTS];
            logic [TID_WIDTH - 1 : 0]        dring_out_tid     [NUM_OUTPUTS];
            logic [TDEST_WIDTH - 1 : 0]      dring_out_tdest   [NUM_OUTPUTS];

            genvar i;
            for (i = 0; i < NUM_INPUTS; i = i + 1) begin: map_dring
                assign dring_in_tvalid[i] = axis_in_tvalid[i];
                assign axis_in_tready[i]  = dring_in_tready[i];
                assign dring_in_tdata[i]  = axis_in_tdata[i];
                assign dring_in_tlast[i]  = axis_in_tlast[i];
                assign dring_in_tid[i]    = axis_in_tid[i];
                assign dring_in_tdest[i]  = axis_in_tdest[i];

                assign axis_out_tvalid[i] = dring_out_tvalid[i];
                assign dring_out_tready[i] = axis_out_tready[i];
                assign axis_out_tdata[i]  = dring_out_tdata[i];
                assign axis_out_tlast[i]  = dring_out_tlast[i];
                assign axis_out_tid[i]    = dring_out_tid[i];
                assign axis_out_tdest[i]  = dring_out_tdest[i];
            end

            axis_double_ring #(
                .RESET_SYNC_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
                .RESET_NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS),
                .NUM_ROUTERS(NUM_INPUTS),
                .TID_WIDTH(TID_WIDTH),
                .TDEST_WIDTH(TDEST_WIDTH),
                .TDATA_WIDTH(TDATA_WIDTH),
                .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                .SINGLE_CLOCK(SINGLE_CLOCK),
                .SERDES_IN_BUFFER_DEPTH(SERDES_IN_BUFFER_DEPTH),
                .SERDES_OUT_BUFFER_DEPTH(SERDES_OUT_BUFFER_DEPTH),
                .SERDES_EXTRA_SYNC_STAGES(SERDES_EXTRA_SYNC_STAGES),
                .SERDES_FORCE_MLAB(SERDES_FORCE_MLAB),
                .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                .ROUTING_TABLE_PREFIX(ROUTING_TABLE_PREFIX),
                .DISABLE_SELFLOOP(DISABLE_SELFLOOP),
                .ROUTER_PIPELINE_ROUTE_COMPUTE(ROUTER_PIPELINE_ROUTE_COMPUTE),
                .ROUTER_PIPELINE_ARBITER(ROUTER_PIPELINE_ARBITER),
                .ROUTER_PIPELINE_OUTPUT(ROUTER_PIPELINE_OUTPUT),
                .ROUTER_FORCE_MLAB(ROUTER_FORCE_MLAB)
            ) double_ring_inst (
                .clk_noc,
                .clk_usr,
                .rst_n,
                .axis_in_tvalid(dring_in_tvalid),
                .axis_in_tready(dring_in_tready),
                .axis_in_tdata(dring_in_tdata),
                .axis_in_tlast(dring_in_tlast),
                .axis_in_tid(dring_in_tid),
                .axis_in_tdest(dring_in_tdest),
                .axis_out_tvalid(dring_out_tvalid),
                .axis_out_tready(dring_out_tready),
                .axis_out_tdata(dring_out_tdata),
                .axis_out_tlast(dring_out_tlast),
                .axis_out_tid(dring_out_tid),
                .axis_out_tdest(dring_out_tdest)
            );
        end
        else if (TOPOLOGY == "butterfly") begin: g_butterfly
            localparam BUTTERFLY_PORTS = K ** N;

            logic                            bf_in_tvalid   [BUTTERFLY_PORTS];
            logic                            bf_in_tready   [BUTTERFLY_PORTS];
            logic [TDATA_WIDTH - 1 : 0]      bf_in_tdata    [BUTTERFLY_PORTS];
            logic                            bf_in_tlast    [BUTTERFLY_PORTS];
            logic [TID_WIDTH - 1 : 0]        bf_in_tid      [BUTTERFLY_PORTS];
            logic [TDEST_WIDTH - 1 : 0]      bf_in_tdest    [BUTTERFLY_PORTS];

            logic                            bf_out_tvalid  [BUTTERFLY_PORTS];
            logic                            bf_out_tready  [BUTTERFLY_PORTS];
            logic [TDATA_WIDTH - 1 : 0]      bf_out_tdata   [BUTTERFLY_PORTS];
            logic                            bf_out_tlast   [BUTTERFLY_PORTS];
            logic [TID_WIDTH - 1 : 0]        bf_out_tid     [BUTTERFLY_PORTS];
            logic [TDEST_WIDTH - 1 : 0]      bf_out_tdest   [BUTTERFLY_PORTS];

            genvar i;
            for (i = 0; i < BUTTERFLY_PORTS; i = i + 1) begin: map_bf
                if (i < NUM_INPUTS) begin
                    assign bf_in_tvalid[i]   = axis_in_tvalid[i];
                    assign axis_in_tready[i] = bf_in_tready[i];
                    assign bf_in_tdata[i]    = axis_in_tdata[i];
                    assign bf_in_tlast[i]    = axis_in_tlast[i];
                    assign bf_in_tid[i]      = axis_in_tid[i];
                    assign bf_in_tdest[i]    = axis_in_tdest[i];
                end else begin
                    assign bf_in_tvalid[i] = 1'b0;
                    assign bf_in_tdata[i]  = '0;
                    assign bf_in_tlast[i]  = 1'b0;
                    assign bf_in_tid[i]    = '0;
                    assign bf_in_tdest[i]  = '0;
                end

                if (i < NUM_OUTPUTS) begin
                    assign axis_out_tvalid[i] = bf_out_tvalid[i];
                    assign bf_out_tready[i]   = axis_out_tready[i];
                    assign axis_out_tdata[i]  = bf_out_tdata[i];
                    assign axis_out_tlast[i]  = bf_out_tlast[i];
                    assign axis_out_tid[i]    = bf_out_tid[i];
                    assign axis_out_tdest[i]  = bf_out_tdest[i];
                end else begin
                    assign bf_out_tready[i]   = 1'b1;
                end
            end

            axis_butterfly #(
                .RESET_SYNC_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
                .RESET_NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS),
                .K(K),
                .N(N),
                .TID_WIDTH(TID_WIDTH),
                .TDEST_WIDTH(TDEST_WIDTH),
                .TDATA_WIDTH(TDATA_WIDTH),
                .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                .SINGLE_CLOCK(SINGLE_CLOCK),
                .SERDES_IN_BUFFER_DEPTH(SERDES_IN_BUFFER_DEPTH),
                .SERDES_OUT_BUFFER_DEPTH(SERDES_OUT_BUFFER_DEPTH),
                .SERDES_EXTRA_SYNC_STAGES(SERDES_EXTRA_SYNC_STAGES),
                .SERDES_FORCE_MLAB(SERDES_FORCE_MLAB),
                .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                .ROUTING_TABLE_PREFIX(ROUTING_TABLE_PREFIX),
                .ROUTER_PIPELINE_ROUTE_COMPUTE(ROUTER_PIPELINE_ROUTE_COMPUTE),
                .ROUTER_PIPELINE_ARBITER(ROUTER_PIPELINE_ARBITER),
                .ROUTER_PIPELINE_OUTPUT(ROUTER_PIPELINE_OUTPUT),
                .ROUTER_FORCE_MLAB(ROUTER_FORCE_MLAB)
            ) butterfly_inst (
                .clk_noc,
                .clk_usr,
                .rst_n,
                .axis_in_tvalid(bf_in_tvalid),
                .axis_in_tready(bf_in_tready),
                .axis_in_tdata(bf_in_tdata),
                .axis_in_tlast(bf_in_tlast),
                .axis_in_tid(bf_in_tid),
                .axis_in_tdest(bf_in_tdest),
                .axis_out_tvalid(bf_out_tvalid),
                .axis_out_tready(bf_out_tready),
                .axis_out_tdata(bf_out_tdata),
                .axis_out_tlast(bf_out_tlast),
                .axis_out_tid(bf_out_tid),
                .axis_out_tdest(bf_out_tdest)
            );
        end
        else if (TOPOLOGY == "mesh" || TOPOLOGY == "torus" || TOPOLOGY == "directional_torus") begin: g_2d
            logic                            mesh_in_tvalid   [NUM_ROWS][NUM_COLS];
            logic                            mesh_in_tready   [NUM_ROWS][NUM_COLS];
            logic [TDATA_WIDTH - 1 : 0]      mesh_in_tdata    [NUM_ROWS][NUM_COLS];
            logic                            mesh_in_tlast    [NUM_ROWS][NUM_COLS];
            logic [TID_WIDTH - 1 : 0]        mesh_in_tid      [NUM_ROWS][NUM_COLS];
            logic [TDEST_WIDTH - 1 : 0]      mesh_in_tdest    [NUM_ROWS][NUM_COLS];

            logic                            mesh_out_tvalid  [NUM_ROWS][NUM_COLS];
            logic                            mesh_out_tready  [NUM_ROWS][NUM_COLS];
            logic [TDATA_WIDTH - 1 : 0]      mesh_out_tdata   [NUM_ROWS][NUM_COLS];
            logic                            mesh_out_tlast   [NUM_ROWS][NUM_COLS];
            logic [TID_WIDTH - 1 : 0]        mesh_out_tid     [NUM_ROWS][NUM_COLS];
            logic [TDEST_WIDTH - 1 : 0]      mesh_out_tdest   [NUM_ROWS][NUM_COLS];

            genvar r, c;
            for (r = 0; r < NUM_ROWS; r = r + 1) begin: r_loop
                for (c = 0; c < NUM_COLS; c = c + 1) begin: c_loop
                    localparam idx = r * NUM_COLS + c;
                    if (idx < NUM_INPUTS) begin
                        assign mesh_in_tvalid[r][c] = axis_in_tvalid[idx];
                        assign axis_in_tready[idx]  = mesh_in_tready[r][c];
                        assign mesh_in_tdata[r][c]  = axis_in_tdata[idx];
                        assign mesh_in_tlast[r][c]  = axis_in_tlast[idx];
                        assign mesh_in_tid[r][c]    = axis_in_tid[idx];
                        assign mesh_in_tdest[r][c]  = axis_in_tdest[idx];
                    end else begin
                        assign mesh_in_tvalid[r][c] = 1'b0;
                        assign mesh_in_tdata[r][c]  = '0;
                        assign mesh_in_tlast[r][c]  = 1'b0;
                        assign mesh_in_tid[r][c]    = '0;
                        assign mesh_in_tdest[r][c]  = '0;
                    end
                    
                    if (idx < NUM_OUTPUTS) begin
                        assign axis_out_tvalid[idx]  = mesh_out_tvalid[r][c];
                        assign mesh_out_tready[r][c] = axis_out_tready[idx];
                        assign axis_out_tdata[idx]   = mesh_out_tdata[r][c];
                        assign axis_out_tlast[idx]   = mesh_out_tlast[r][c];
                        assign axis_out_tid[idx]     = mesh_out_tid[r][c];
                        assign axis_out_tdest[idx]   = mesh_out_tdest[r][c];
                    end else begin
                        assign mesh_out_tready[r][c] = 1'b1;
                    end
                end
            end

            if (TOPOLOGY == "mesh") begin: g_mesh
                axis_mesh #(
                    .RESET_SYNC_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
                    .RESET_NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS),
                    .NUM_ROWS(NUM_ROWS),
                    .NUM_COLS(NUM_COLS),
                    .PIPELINE_LINKS(PIPELINE_LINKS),
                    .TID_WIDTH(TID_WIDTH),
                    .TDEST_WIDTH(TDEST_WIDTH),
                    .TDATA_WIDTH(TDATA_WIDTH),
                    .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                    .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                    .SINGLE_CLOCK(SINGLE_CLOCK),
                    .SERDES_IN_BUFFER_DEPTH(SERDES_IN_BUFFER_DEPTH),
                    .SERDES_OUT_BUFFER_DEPTH(SERDES_OUT_BUFFER_DEPTH),
                    .SERDES_EXTRA_SYNC_STAGES(SERDES_EXTRA_SYNC_STAGES),
                    .SERDES_FORCE_MLAB(SERDES_FORCE_MLAB),
                    .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                    .ROUTING_TABLE_PREFIX(ROUTING_TABLE_PREFIX),
                    .OPTIMIZE_FOR_ROUTING(OPTIMIZE_FOR_ROUTING),
                    .DISABLE_SELFLOOP(DISABLE_SELFLOOP),
                    .ROUTER_PIPELINE_ROUTE_COMPUTE(ROUTER_PIPELINE_ROUTE_COMPUTE),
                    .ROUTER_PIPELINE_ARBITER(ROUTER_PIPELINE_ARBITER),
                    .ROUTER_PIPELINE_OUTPUT(ROUTER_PIPELINE_OUTPUT),
                    .ROUTER_FORCE_MLAB(ROUTER_FORCE_MLAB)
                ) mesh_inst (
                    .clk_noc,
                    .clk_usr,
                    .rst_n,
                    .axis_in_tvalid(mesh_in_tvalid),
                    .axis_in_tready(mesh_in_tready),
                    .axis_in_tdata(mesh_in_tdata),
                    .axis_in_tlast(mesh_in_tlast),
                    .axis_in_tid(mesh_in_tid),
                    .axis_in_tdest(mesh_in_tdest),
                    .axis_out_tvalid(mesh_out_tvalid),
                    .axis_out_tready(mesh_out_tready),
                    .axis_out_tdata(mesh_out_tdata),
                    .axis_out_tlast(mesh_out_tlast),
                    .axis_out_tid(mesh_out_tid),
                    .axis_out_tdest(mesh_out_tdest)
                );
            end
            else if (TOPOLOGY == "torus") begin: g_torus
                axis_torus #(
                    .RESET_SYNC_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
                    .RESET_NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS),
                    .NUM_ROWS(NUM_ROWS),
                    .NUM_COLS(NUM_COLS),
                    .PIPELINE_LINKS(PIPELINE_LINKS),
                    .EXTRA_PIPELINE_LONG_LINKS(EXTRA_PIPELINE_LONG_LINKS),
                    .TID_WIDTH(TID_WIDTH),
                    .TDEST_WIDTH(TDEST_WIDTH),
                    .TDATA_WIDTH(TDATA_WIDTH),
                    .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                    .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                    .SINGLE_CLOCK(SINGLE_CLOCK),
                    .SERDES_IN_BUFFER_DEPTH(SERDES_IN_BUFFER_DEPTH),
                    .SERDES_OUT_BUFFER_DEPTH(SERDES_OUT_BUFFER_DEPTH),
                    .SERDES_EXTRA_SYNC_STAGES(SERDES_EXTRA_SYNC_STAGES),
                    .SERDES_FORCE_MLAB(SERDES_FORCE_MLAB),
                    .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                    .ROUTING_TABLE_PREFIX(ROUTING_TABLE_PREFIX),
                    .DISABLE_SELFLOOP(DISABLE_SELFLOOP),
                    .OPTIMIZE_FOR_ROUTING(OPTIMIZE_FOR_ROUTING),
                    .ROUTER_PIPELINE_ROUTE_COMPUTE(ROUTER_PIPELINE_ROUTE_COMPUTE),
                    .ROUTER_PIPELINE_ARBITER(ROUTER_PIPELINE_ARBITER),
                    .ROUTER_PIPELINE_OUTPUT(ROUTER_PIPELINE_OUTPUT),
                    .ROUTER_FORCE_MLAB(ROUTER_FORCE_MLAB)
                ) torus_inst (
                    .clk_noc,
                    .clk_usr,
                    .rst_n,
                    .axis_in_tvalid(mesh_in_tvalid),
                    .axis_in_tready(mesh_in_tready),
                    .axis_in_tdata(mesh_in_tdata),
                    .axis_in_tlast(mesh_in_tlast),
                    .axis_in_tid(mesh_in_tid),
                    .axis_in_tdest(mesh_in_tdest),
                    .axis_out_tvalid(mesh_out_tvalid),
                    .axis_out_tready(mesh_out_tready),
                    .axis_out_tdata(mesh_out_tdata),
                    .axis_out_tlast(mesh_out_tlast),
                    .axis_out_tid(mesh_out_tid),
                    .axis_out_tdest(mesh_out_tdest)
                );
            end
            else if (TOPOLOGY == "directional_torus") begin: g_dtorus
                axis_directional_torus #(
                    .RESET_SYNC_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
                    .RESET_NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS),
                    .NUM_ROWS(NUM_ROWS),
                    .NUM_COLS(NUM_COLS),
                    .PIPELINE_LINKS(PIPELINE_LINKS),
                    .EXTRA_PIPELINE_LONG_LINKS(EXTRA_PIPELINE_LONG_LINKS),
                    .TID_WIDTH(TID_WIDTH),
                    .TDEST_WIDTH(TDEST_WIDTH),
                    .TDATA_WIDTH(TDATA_WIDTH),
                    .SERIALIZATION_FACTOR(SERIALIZATION_FACTOR),
                    .CLKCROSS_FACTOR(CLKCROSS_FACTOR),
                    .SINGLE_CLOCK(SINGLE_CLOCK),
                    .SERDES_IN_BUFFER_DEPTH(SERDES_IN_BUFFER_DEPTH),
                    .SERDES_OUT_BUFFER_DEPTH(SERDES_OUT_BUFFER_DEPTH),
                    .SERDES_EXTRA_SYNC_STAGES(SERDES_EXTRA_SYNC_STAGES),
                    .SERDES_FORCE_MLAB(SERDES_FORCE_MLAB),
                    .FLIT_BUFFER_DEPTH(FLIT_BUFFER_DEPTH),
                    .ROUTING_TABLE_PREFIX(ROUTING_TABLE_PREFIX),
                    .DISABLE_SELFLOOP(DISABLE_SELFLOOP),
                    .OPTIMIZE_FOR_ROUTING(OPTIMIZE_FOR_ROUTING),
                    .ROUTER_PIPELINE_ROUTE_COMPUTE(ROUTER_PIPELINE_ROUTE_COMPUTE),
                    .ROUTER_PIPELINE_ARBITER(ROUTER_PIPELINE_ARBITER),
                    .ROUTER_PIPELINE_OUTPUT(ROUTER_PIPELINE_OUTPUT),
                    .ROUTER_FORCE_MLAB(ROUTER_FORCE_MLAB)
                ) dtorus_inst (
                    .clk_noc,
                    .clk_usr,
                    .rst_n,
                    .axis_in_tvalid(mesh_in_tvalid),
                    .axis_in_tready(mesh_in_tready),
                    .axis_in_tdata(mesh_in_tdata),
                    .axis_in_tlast(mesh_in_tlast),
                    .axis_in_tid(mesh_in_tid),
                    .axis_in_tdest(mesh_in_tdest),
                    .axis_out_tvalid(mesh_out_tvalid),
                    .axis_out_tready(mesh_out_tready),
                    .axis_out_tdata(mesh_out_tdata),
                    .axis_out_tlast(mesh_out_tlast),
                    .axis_out_tid(mesh_out_tid),
                    .axis_out_tdest(mesh_out_tdest)
                );
            end
        end
    endgenerate

endmodule: axis_topology_wrapper
