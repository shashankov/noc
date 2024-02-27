/**
 * @file axis_router.sv
 *
 * @brief AXI-Stream Router (Single Switch)
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

 module axis_router #(
    parameter RESET_SYNC_EXTEND_CYCLES = 2,
    parameter RESET_NUM_OUTPUT_REGISTERS = 1,

    parameter NUM_INPUTS = 4,
    parameter NUM_OUTPUTS = 4,

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
    parameter ROUTING_TABLE_PREFIX = "routing_tables/router_4x4/",

    parameter bit ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter bit ROUTER_PIPELINE_ARBITER = 0,
    parameter bit ROUTER_PIPELINE_OUTPUT = 0,
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
    localparam FLIT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR / CLKCROSS_FACTOR;
    localparam DEST_WIDTH = TDEST_WIDTH + TID_WIDTH;

    // Declarations
    logic   rst_n_noc_sync, rst_n_usr_sync;
    logic   rst_noc_sync, rst_usr_sync;

    logic   [FLIT_WIDTH - 1 : 0]    data_in     [NUM_INPUTS];
    logic   [DEST_WIDTH  - 1 : 0]   dest_in     [NUM_INPUTS];
    logic                           is_tail_in  [NUM_INPUTS];
    logic                           send_in     [NUM_INPUTS];
    logic                           credit_out  [NUM_INPUTS];

    logic   [FLIT_WIDTH - 1 : 0]    data_out    [NUM_OUTPUTS];
    logic   [DEST_WIDTH - 1 : 0]    dest_out    [NUM_OUTPUTS];
    logic                           is_tail_out [NUM_OUTPUTS];
    logic                           send_out    [NUM_OUTPUTS];
    logic                           credit_in   [NUM_OUTPUTS];

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
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin: for_inputs
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
        end

        for (j = 0; j < NUM_OUTPUTS; j = j + 1) begin: for_outputs
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

                .axis_tvalid    (axis_out_tvalid[j]),
                .axis_tready    (axis_out_tready[j]),
                .axis_tdata     (axis_out_tdata[j]),
                .axis_tlast     (axis_out_tlast[j]),
                .axis_tdest     ({axis_out_tid[j], axis_out_tdest[j]}),

                .data_in        (data_out[j]),
                .dest_in        (dest_out[j]),
                .is_tail_in     (is_tail_out[j]),
                .send_in        (send_out[j]),
                .credit_out     (credit_in[j])
            );
        end
    end
    endgenerate

    localparam string routing_table = $sformatf("%s/table.hex", ROUTING_TABLE_PREFIX);
    bit DISABLE_TURNS[NUM_INPUTS][NUM_OUTPUTS];
    always_comb begin
        for (int i = 0; i < NUM_INPUTS; i = i + 1) begin
            for (int j = 0; j < NUM_OUTPUTS; j = j + 1) begin
                DISABLE_TURNS[i][j] = 0;
            end
        end
    end

    router #(
        .NOC_NUM_ENDPOINTS      (NUM_OUTPUTS),
        .ROUTING_TABLE_HEX      (routing_table),
        .NUM_INPUTS             (NUM_INPUTS),
        .NUM_OUTPUTS            (NUM_OUTPUTS),
        .DEST_WIDTH             (DEST_WIDTH),
        .FLIT_WIDTH             (FLIT_WIDTH),
        .FLIT_BUFFER_DEPTH      (FLIT_BUFFER_DEPTH),
        .PIPELINE_ROUTE_COMPUTE (ROUTER_PIPELINE_ROUTE_COMPUTE),
        .PIPELINE_ARBITER       (ROUTER_PIPELINE_ARBITER),
        .PIPELINE_OUTPUT        (ROUTER_PIPELINE_OUTPUT),
        .FORCE_MLAB             (ROUTER_FORCE_MLAB)
    ) router_inst (
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
        .credit_in      (credit_in),

        .DISABLE_TURNS  (DISABLE_TURNS)
    );

endmodule: axis_router
