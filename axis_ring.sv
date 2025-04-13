/**
 * @file axis_ring.sv
 *
 * @brief AXI-Stream Ring NoC
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

 module axis_ring #(
    parameter RESET_SYNC_EXTEND_CYCLES = 2,
    parameter RESET_NUM_OUTPUT_REGISTERS = 1,

    parameter NUM_ROUTERS = 4,
    parameter PIPELINE_LINKS = 0,

    parameter TID_WIDTH = 2,
    parameter TDEST_WIDTH = 4,
    parameter TDATA_WIDTH = 512,

    parameter SERIALIZATION_FACTOR = 4,
    parameter CLKCROSS_FACTOR = 1,
    parameter bit SINGLE_CLOCK = 0,
    parameter SERDES_IN_BUFFER_DEPTH = 4,
    parameter SERDES_OUT_BUFFER_DEPTH = 4,
    parameter SERDES_EXTRA_SYNC_STAGES = 0,
    parameter SERDES_FORCE_MLAB = 0,

    parameter FLIT_BUFFER_DEPTH = 4,
    parameter ROUTING_TABLE_PREFIX = "routing_tables/ring_4/",
    parameter bit DISABLE_SELFLOOP = 1,

    parameter bit ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter bit ROUTER_PIPELINE_ARBITER = 0,
    parameter bit ROUTER_PIPELINE_OUTPUT = 0,
    parameter bit ROUTER_FORCE_MLAB = 0
) (
    input   wire    clk_noc,
    input   wire    clk_usr,
    input   wire    rst_n,

    input   wire                            axis_in_tvalid  [NUM_ROUTERS],
    output  logic                           axis_in_tready  [NUM_ROUTERS],
    input   wire    [TDATA_WIDTH - 1 : 0]   axis_in_tdata   [NUM_ROUTERS],
    input   wire                            axis_in_tlast   [NUM_ROUTERS],
    input   wire    [TID_WIDTH - 1 : 0]     axis_in_tid     [NUM_ROUTERS],
    input   wire    [TDEST_WIDTH - 1 : 0]   axis_in_tdest   [NUM_ROUTERS],

    output  logic                           axis_out_tvalid [NUM_ROUTERS],
    input   wire                            axis_out_tready [NUM_ROUTERS],
    output  logic   [TDATA_WIDTH - 1 : 0]   axis_out_tdata  [NUM_ROUTERS],
    output  logic                           axis_out_tlast  [NUM_ROUTERS],
    output  logic   [TID_WIDTH - 1 : 0]     axis_out_tid    [NUM_ROUTERS],
    output  logic   [TDEST_WIDTH - 1 : 0]   axis_out_tdest  [NUM_ROUTERS]
);
    localparam FLIT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR / CLKCROSS_FACTOR;
    localparam DEST_WIDTH = TDEST_WIDTH + TID_WIDTH;

    // Declarations
    logic   rst_n_noc_sync, rst_n_usr_sync;
    logic   rst_noc_sync, rst_usr_sync;

    logic   [FLIT_WIDTH - 1 : 0]    data_in     [NUM_ROUTERS];
    logic   [DEST_WIDTH  - 1 : 0]   dest_in     [NUM_ROUTERS];
    logic                           is_tail_in  [NUM_ROUTERS];
    logic                           send_in     [NUM_ROUTERS];
    logic                           credit_out  [NUM_ROUTERS];

    logic   [FLIT_WIDTH - 1 : 0]    data_out    [NUM_ROUTERS];
    logic   [DEST_WIDTH - 1 : 0]    dest_out    [NUM_ROUTERS];
    logic                           is_tail_out [NUM_ROUTERS];
    logic                           send_out    [NUM_ROUTERS];
    logic                           credit_in   [NUM_ROUTERS];

    // Assign resets
    assign rst_n_noc_sync = ~rst_noc_sync;
    assign rst_n_usr_sync = ~rst_usr_sync;

    // Instantiations
    reset_synchronizer #(
        .NUM_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
        .NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS)
    ) usr_sync (
        .reset_async    (~rst_n),
        .sync_clk       (clk_usr),
        .reset_sync     (rst_usr_sync)
    );

    reset_synchronizer #(
        .NUM_EXTEND_CYCLES(RESET_SYNC_EXTEND_CYCLES),
        .NUM_OUTPUT_REGISTERS(RESET_NUM_OUTPUT_REGISTERS)
    ) noc_sync (
        .reset_async    (~rst_n),
        .sync_clk       (clk_noc),
        .reset_sync     (rst_noc_sync)
    );

    generate begin: shim_gen
        genvar i, j;
        for (i = 0; i < NUM_ROUTERS; i = i + 1) begin: for_routers
            axis_serializer_shim_in #(
                .TDEST_WIDTH            (DEST_WIDTH),
                .TDATA_WIDTH            (TDATA_WIDTH),
                .SERIALIZATION_FACTOR   (SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR        (CLKCROSS_FACTOR),
                .SINGLE_CLOCK           (SINGLE_CLOCK),
                .BUFFER_DEPTH           (SERDES_IN_BUFFER_DEPTH),
                .FLIT_BUFFER_DEPTH      (FLIT_BUFFER_DEPTH),
                .EXTRA_SYNC_STAGES      (SERDES_EXTRA_SYNC_STAGES),
                .FORCE_MLAB             (SERDES_FORCE_MLAB)
            ) shim_in (
                .clk_usr,
                .clk_noc,

                .rst_n_usr_sync,
                .rst_n_noc_sync,

                .axis_tvalid    (axis_in_tvalid[i]),
                .axis_tready    (axis_in_tready[i]),
                .axis_tdata     (axis_in_tdata[i]),
                .axis_tlast     (axis_in_tlast[i]),
                .axis_tdest     ({axis_in_tid[i], axis_in_tdest[i]}),

                .data_out       (data_in[i]),
                .dest_out       (dest_in[i]),
                .is_tail_out    (is_tail_in[i]),
                .send_out       (send_in[i]),
                .credit_in      (credit_out[i])
            );

            axis_deserializer_shim_out #(
                .TDEST_WIDTH            (DEST_WIDTH),
                .TDATA_WIDTH            (TDATA_WIDTH),
                .SERIALIZATION_FACTOR   (SERIALIZATION_FACTOR),
                .CLKCROSS_FACTOR        (CLKCROSS_FACTOR),
                .SINGLE_CLOCK           (SINGLE_CLOCK),
                .BUFFER_DEPTH           (SERDES_OUT_BUFFER_DEPTH),
                .FLIT_BUFFER_DEPTH      (FLIT_BUFFER_DEPTH),
                .EXTRA_SYNC_STAGES      (SERDES_EXTRA_SYNC_STAGES),
                .FORCE_MLAB             (SERDES_FORCE_MLAB)
            ) shim_out (
                .clk_usr,
                .clk_noc,

                .rst_n_usr_sync,
                .rst_n_noc_sync,

                .axis_tvalid    (axis_out_tvalid[i]),
                .axis_tready    (axis_out_tready[i]),
                .axis_tdata     (axis_out_tdata[i]),
                .axis_tlast     (axis_out_tlast[i]),
                .axis_tdest     ({axis_out_tid[i], axis_out_tdest[i]}),

                .data_in        (data_out[i]),
                .dest_in        (dest_out[i]),
                .is_tail_in     (is_tail_out[i]),
                .send_in        (send_out[i]),
                .credit_out     (credit_in[i])
            );
        end
    end
    endgenerate

    ring #(
        .NUM_ROUTERS                    (NUM_ROUTERS),
        .DEST_WIDTH                     (DEST_WIDTH),
        .FLIT_WIDTH                     (FLIT_WIDTH),
        .FLIT_BUFFER_DEPTH              (FLIT_BUFFER_DEPTH),
        .PIPELINE_LINKS                 (PIPELINE_LINKS),
        .ROUTING_TABLE_PREFIX           (ROUTING_TABLE_PREFIX),
        .DISABLE_SELFLOOP               (DISABLE_SELFLOOP),
        .ROUTER_PIPELINE_ROUTE_COMPUTE  (ROUTER_PIPELINE_ROUTE_COMPUTE),
        .ROUTER_PIPELINE_ARBITER        (ROUTER_PIPELINE_ARBITER),
        .ROUTER_PIPELINE_OUTPUT         (ROUTER_PIPELINE_OUTPUT),
        .ROUTER_FORCE_MLAB              (ROUTER_FORCE_MLAB)
    ) noc (
        .clk            (clk_noc),
        .rst_n          (rst_n_noc_sync),

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

endmodule: axis_ring
