/**
 * @file double_ring.sv
 *
 * @brief Double-Ring NoC with native interface
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

module double_ring #(
    parameter NUM_ROUTERS = 4,
    parameter DEST_WIDTH = 4,
    parameter FLIT_WIDTH = 256,
    parameter FLIT_BUFFER_DEPTH = 2,
    parameter ROUTING_TABLE_PREFIX = "routing_tables/double_ring_4/",
    parameter ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter ROUTER_PIPELINE_ARBITER = 0,
    parameter ROUTER_PIPELINE_OUTPUT = 0,
    parameter ROUTER_DISABLE_SELFLOOP = 0,
    parameter ROUTER_FORCE_MLAB = 0
) (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [FLIT_WIDTH - 1 : 0]    data_in     [NUM_ROUTERS],
    input   wire    [DEST_WIDTH - 1 : 0]    dest_in     [NUM_ROUTERS],
    input   wire                            is_tail_in  [NUM_ROUTERS],
    input   wire                            send_in     [NUM_ROUTERS],
    output  logic                           credit_out  [NUM_ROUTERS],

    output  logic   [FLIT_WIDTH - 1 : 0]    data_out    [NUM_ROUTERS],
    output  logic   [DEST_WIDTH - 1 : 0]    dest_out    [NUM_ROUTERS],
    output  logic                           is_tail_out [NUM_ROUTERS],
    output  logic                           send_out    [NUM_ROUTERS],
    input   wire                            credit_in   [NUM_ROUTERS]
);

    // Declare all intermediate signals of routers
    logic   [FLIT_WIDTH - 1 : 0]       data_clock       [NUM_ROUTERS];
    logic   [DEST_WIDTH - 1 : 0]       dest_clock       [NUM_ROUTERS];
    logic                           is_tail_clock       [NUM_ROUTERS];
    logic                              send_clock       [NUM_ROUTERS];
    logic                            credit_clock       [NUM_ROUTERS];

    logic   [FLIT_WIDTH - 1 : 0]       data_anticlock   [NUM_ROUTERS];
    logic   [DEST_WIDTH - 1 : 0]       dest_anticlock   [NUM_ROUTERS];
    logic                           is_tail_anticlock   [NUM_ROUTERS];
    logic                              send_anticlock   [NUM_ROUTERS];
    logic                            credit_anticlock   [NUM_ROUTERS];

    // Declare packed router input and output ports
    logic   [FLIT_WIDTH - 1 : 0]       data_router_in   [NUM_ROUTERS][3];
    logic   [DEST_WIDTH - 1 : 0]       dest_router_in   [NUM_ROUTERS][3];
    logic                           is_tail_router_in   [NUM_ROUTERS][3];
    logic                              send_router_in   [NUM_ROUTERS][3];
    logic                            credit_router_out  [NUM_ROUTERS][3];

    logic   [FLIT_WIDTH - 1 : 0]       data_router_out  [NUM_ROUTERS][3];
    logic   [DEST_WIDTH - 1 : 0]       dest_router_out  [NUM_ROUTERS][3];
    logic                           is_tail_router_out  [NUM_ROUTERS][3];
    logic                              send_router_out  [NUM_ROUTERS][3];
    logic                            credit_router_in   [NUM_ROUTERS][3];

    // Assign router input and output ports
    always_comb begin
        for (int i = 0; i < NUM_ROUTERS; i++) begin
            // NoC IO Ports
               data_out [i] =    data_router_out [i][0];
               dest_out [i] =    dest_router_out [i][0];
            is_tail_out [i] = is_tail_router_out [i][0];
               send_out [i] =    send_router_out [i][0];
             credit_out [i] =  credit_router_out [i][0];

            // Clockwise Side Ports
               data_clock  [i] =    data_router_out [i][1];
               dest_clock  [i] =    dest_router_out [i][1];
            is_tail_clock  [i] = is_tail_router_out [i][1];
               send_clock  [i] =    send_router_out [i][1];
             credit_clock  [i] =  credit_router_out [i][1];

            // Anti-Clockwise Side Ports
            if (i != 0) begin
                   data_anticlock  [i - 1] =    data_router_out [i][2];
                   dest_anticlock  [i - 1] =    dest_router_out [i][2];
                is_tail_anticlock  [i - 1] = is_tail_router_out [i][2];
                   send_anticlock  [i - 1] =    send_router_out [i][2];
                 credit_anticlock  [i - 1] =  credit_router_out [i][2];
            end else begin  // loop around
                   data_anticlock  [NUM_ROUTERS - 1] =    data_router_out [i][2];
                   dest_anticlock  [NUM_ROUTERS - 1] =    dest_router_out [i][2];
                is_tail_anticlock  [NUM_ROUTERS - 1] = is_tail_router_out [i][2];
                   send_anticlock  [NUM_ROUTERS - 1] =    send_router_out [i][2];
                 credit_anticlock  [NUM_ROUTERS - 1] =  credit_router_out [i][2];
            end
        end
    end

    // This split in the alwasy block is necessary for Modelsim
    // to correctly assign the outputs without causing a delay
    // by triggering some signals only on the next clock edge
    always_comb begin
        for (int i = 0; i < NUM_ROUTERS; i++) begin
            // NoC IO Ports
               data_router_in [i][0] =    data_in  [i];
               dest_router_in [i][0] =    dest_in  [i];
            is_tail_router_in [i][0] = is_tail_in  [i];
               send_router_in [i][0] =    send_in  [i];
             credit_router_in [i][0] =  credit_in  [i];

            // Clockwise Side Ports
               data_router_in   [i][1] =    data_anticlock [i];
               dest_router_in   [i][1] =    dest_anticlock [i];
            is_tail_router_in   [i][1] = is_tail_anticlock [i];
               send_router_in   [i][1] =    send_anticlock [i];
             credit_router_in   [i][1] =  credit_anticlock [i];

            // Anti-Clockwise Side Ports
            if (i != 0) begin
                   data_router_in   [i][2] =    data_clock [i - 1];
                   dest_router_in   [i][2] =    dest_clock [i - 1];
                is_tail_router_in   [i][2] = is_tail_clock [i - 1];
                   send_router_in   [i][2] =    send_clock [i - 1];
                 credit_router_in   [i][2] =  credit_clock [i - 1];
            end else begin  // loop around
                   data_router_in   [i][2] =    data_clock [NUM_ROUTERS - 1];
                   dest_router_in   [i][2] =    dest_clock [NUM_ROUTERS - 1];
                is_tail_router_in   [i][2] = is_tail_clock [NUM_ROUTERS - 1];
                   send_router_in   [i][2] =    send_clock [NUM_ROUTERS - 1];
                 credit_router_in   [i][2] =  credit_clock [NUM_ROUTERS - 1];
            end
        end
    end

    // Generate routers
    generate begin: router_gen
        genvar i, j;
        for (i = 0; i < NUM_ROUTERS; i = i + 1) begin: for_routers
            // Generate routing table file name
            localparam string routing_table = $sformatf("%s%0d.hex", ROUTING_TABLE_PREFIX, i);

            // Instantiate router
            router #(
                .NOC_NUM_ENDPOINTS      (NUM_ROUTERS),
                .ROUTING_TABLE_HEX      (routing_table),
                .NUM_INPUTS             (3),
                .NUM_OUTPUTS            (3),
                .DEST_WIDTH             (DEST_WIDTH),
                .FLIT_WIDTH             (FLIT_WIDTH),
                .FLIT_BUFFER_DEPTH      (FLIT_BUFFER_DEPTH),
                .PIPELINE_ROUTE_COMPUTE (ROUTER_PIPELINE_ROUTE_COMPUTE),
                .PIPELINE_ARBITER       (ROUTER_PIPELINE_ARBITER),
                .PIPELINE_OUTPUT        (ROUTER_PIPELINE_OUTPUT),
                .DISABLE_SELFLOOP       (ROUTER_DISABLE_SELFLOOP),
                .FORCE_MLAB             (ROUTER_FORCE_MLAB)
            ) router_inst (
                .clk            (clk),
                .rst_n          (rst_n),

                .data_in        (   data_router_in [i]),
                .dest_in        (   dest_router_in [i]),
                .is_tail_in     (is_tail_router_in [i]),
                .send_in        (   send_router_in [i]),
                .credit_out     ( credit_router_out[i]),

                .data_out       (   data_router_out[i]),
                .dest_out       (   dest_router_out[i]),
                .is_tail_out    (is_tail_router_out[i]),
                .send_out       (   send_router_out[i]),
                .credit_in      ( credit_router_in [i])
            );
        end
    end
    endgenerate

endmodule: double_ring