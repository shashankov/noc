/**
 * @file axis_mesh.sv
 *
 * @brief AXI-Stream Mesh NoC
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

module axis_mesh #(
    parameter RESET_SYNC_EXTEND_CYCLES = 2,
    parameter RESET_NUM_OUTPUT_REGISTERS = 1,

    parameter NUM_ROWS = 4,
    parameter NUM_COLS = 4,
    parameter PIPELINE_LINKS = 0,

    parameter TID_WIDTH = 2,
    parameter TDEST_WIDTH = 4,
    parameter TDATA_WIDTH = 512,

    parameter SERIALIZATION_FACTOR = 4,
    parameter CLKCROSS_FACTOR = 1,
    parameter bit SINGLE_CLOCK = 0,
    parameter SERDES_IN_BUFFER_DEPTH = 2,
    parameter SERDES_OUT_BUFFER_DEPTH = 2,
    parameter SERDES_EXTRA_SYNC_STAGES = 0,
    parameter bit SERDES_FORCE_MLAB = 0,

    parameter FLIT_BUFFER_DEPTH = 4,
    parameter ROUTING_TABLE_PREFIX = "routing_tables/mesh_4x4/",
    parameter OPTIMIZE_FOR_ROUTING = "XY",
    parameter bit DISABLE_SELFLOOP = 1,

    parameter bit ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter bit ROUTER_PIPELINE_ARBITER = 0,
    parameter bit ROUTER_PIPELINE_OUTPUT = 1,
    parameter bit ROUTER_FORCE_MLAB = 0
) (
    input   wire    clk_noc,
    input   wire    clk_usr,
    input   wire    rst_n,

    input   wire                            axis_in_tvalid  [NUM_ROWS][NUM_COLS],
    output  logic                           axis_in_tready  [NUM_ROWS][NUM_COLS],
    input   wire    [TDATA_WIDTH - 1 : 0]   axis_in_tdata   [NUM_ROWS][NUM_COLS],
    input   wire                            axis_in_tlast   [NUM_ROWS][NUM_COLS],
    input   wire    [TID_WIDTH - 1 : 0]     axis_in_tid     [NUM_ROWS][NUM_COLS],
    input   wire    [TDEST_WIDTH - 1 : 0]   axis_in_tdest   [NUM_ROWS][NUM_COLS],

    output  logic                           axis_out_tvalid [NUM_ROWS][NUM_COLS],
    input   wire                            axis_out_tready [NUM_ROWS][NUM_COLS],
    output  logic   [TDATA_WIDTH - 1 : 0]   axis_out_tdata  [NUM_ROWS][NUM_COLS],
    output  logic                           axis_out_tlast  [NUM_ROWS][NUM_COLS],
    output  logic   [TID_WIDTH - 1 : 0]     axis_out_tid    [NUM_ROWS][NUM_COLS],
    output  logic   [TDEST_WIDTH - 1 : 0]   axis_out_tdest  [NUM_ROWS][NUM_COLS]
);
    localparam FLIT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR / CLKCROSS_FACTOR;
    localparam DEST_WIDTH = TDEST_WIDTH + TID_WIDTH;

    // Declarations
    logic   rst_n_noc_sync, rst_n_usr_sync;
    logic   rst_noc_sync, rst_usr_sync;

    logic   [FLIT_WIDTH - 1 : 0]    data_in     [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH  - 1 : 0]   dest_in     [NUM_ROWS][NUM_COLS];
    logic                           is_tail_in  [NUM_ROWS][NUM_COLS];
    logic                           send_in     [NUM_ROWS][NUM_COLS];
    logic                           credit_out  [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]    data_out    [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]    dest_out    [NUM_ROWS][NUM_COLS];
    logic                           is_tail_out [NUM_ROWS][NUM_COLS];
    logic                           send_out    [NUM_ROWS][NUM_COLS];
    logic                           credit_in   [NUM_ROWS][NUM_COLS];

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
        for (i = 0; i < NUM_ROWS; i = i + 1) begin: for_rows
            for (j = 0; j < NUM_COLS; j = j + 1) begin: for_cols
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

                    .axis_tvalid    (axis_in_tvalid[i][j]),
                    .axis_tready    (axis_in_tready[i][j]),
                    .axis_tdata     (axis_in_tdata[i][j]),
                    .axis_tlast     (axis_in_tlast[i][j]),
                    .axis_tdest     ({axis_in_tid[i][j], axis_in_tdest[i][j]}),

                    .data_out       (data_in[i][j]),
                    .dest_out       (dest_in[i][j]),
                    .is_tail_out    (is_tail_in[i][j]),
                    .send_out       (send_in[i][j]),
                    .credit_in      (credit_out[i][j])
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

                    .axis_tvalid    (axis_out_tvalid[i][j]),
                    .axis_tready    (axis_out_tready[i][j]),
                    .axis_tdata     (axis_out_tdata[i][j]),
                    .axis_tlast     (axis_out_tlast[i][j]),
                    .axis_tdest     ({axis_out_tid[i][j], axis_out_tdest[i][j]}),

                    .data_in        (data_out[i][j]),
                    .dest_in        (dest_out[i][j]),
                    .is_tail_in     (is_tail_out[i][j]),
                    .send_in        (send_out[i][j]),
                    .credit_out     (credit_in[i][j])
                );
            end
        end
    end
    endgenerate

    mesh #(
        .NUM_ROWS                       (NUM_ROWS),
        .NUM_COLS                       (NUM_COLS),
        .PIPELINE_LINKS                 (PIPELINE_LINKS),
        .DEST_WIDTH                     (DEST_WIDTH),
        .FLIT_WIDTH                     (FLIT_WIDTH),
        .FLIT_BUFFER_DEPTH              (FLIT_BUFFER_DEPTH),
        .OPTIMIZE_FOR_ROUTING           (OPTIMIZE_FOR_ROUTING),
        .DISABLE_SELFLOOP               (DISABLE_SELFLOOP),
        .ROUTING_TABLE_PREFIX           (ROUTING_TABLE_PREFIX),
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

endmodule: axis_mesh