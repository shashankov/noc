/**
 * @file torus.sv
 *
 * @brief Torus NoC with native interface
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

 module torus #(
    parameter NUM_ROWS = 4,
    parameter NUM_COLS = 4,
    parameter DEST_WIDTH = 4,           // clog2(NUM_ROWS * NUM_COLS)
    parameter FLIT_WIDTH = 128,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter PIPELINE_LINKS = 0,
    parameter EXTRA_PIPELINE_LONG_LINKS = 0,
    parameter ROUTING_TABLE_PREFIX = "routing_tables/torus_4x4/",
    parameter OPTIMIZE_FOR_ROUTING = "XY",
    parameter bit DISABLE_SELFLOOP = 0,
    parameter bit ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter bit ROUTER_PIPELINE_ARBITER = 0,
    parameter bit ROUTER_PIPELINE_OUTPUT = 1,
    parameter bit ROUTER_FORCE_MLAB = 0
) (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [FLIT_WIDTH - 1 : 0]    data_in     [NUM_ROWS][NUM_COLS],
    input   wire    [DEST_WIDTH - 1 : 0]    dest_in     [NUM_ROWS][NUM_COLS],
    input   wire                            is_tail_in  [NUM_ROWS][NUM_COLS],
    input   wire                            send_in     [NUM_ROWS][NUM_COLS],
    output  logic                           credit_out  [NUM_ROWS][NUM_COLS],

    output  logic   [FLIT_WIDTH - 1 : 0]    data_out    [NUM_ROWS][NUM_COLS],
    output  logic   [DEST_WIDTH - 1 : 0]    dest_out    [NUM_ROWS][NUM_COLS],
    output  logic                           is_tail_out [NUM_ROWS][NUM_COLS],
    output  logic                           send_out    [NUM_ROWS][NUM_COLS],
    input   wire                            credit_in   [NUM_ROWS][NUM_COLS]
);

    // Declare all intermediate signals of routers
    logic   [FLIT_WIDTH - 1 : 0]       data_south_in    [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_south_in    [NUM_ROWS][NUM_COLS];
    logic                           is_tail_south_in    [NUM_ROWS][NUM_COLS];
    logic                              send_south_in    [NUM_ROWS][NUM_COLS];
    logic                            credit_south_in    [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_south_out   [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_south_out   [NUM_ROWS][NUM_COLS];
    logic                           is_tail_south_out   [NUM_ROWS][NUM_COLS];
    logic                              send_south_out   [NUM_ROWS][NUM_COLS];
    logic                            credit_south_out   [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_north_in    [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_north_in    [NUM_ROWS][NUM_COLS];
    logic                           is_tail_north_in    [NUM_ROWS][NUM_COLS];
    logic                              send_north_in    [NUM_ROWS][NUM_COLS];
    logic                            credit_north_in    [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_north_out   [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_north_out   [NUM_ROWS][NUM_COLS];
    logic                           is_tail_north_out   [NUM_ROWS][NUM_COLS];
    logic                              send_north_out   [NUM_ROWS][NUM_COLS];
    logic                            credit_north_out   [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_east_in     [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_east_in     [NUM_ROWS][NUM_COLS];
    logic                           is_tail_east_in     [NUM_ROWS][NUM_COLS];
    logic                              send_east_in     [NUM_ROWS][NUM_COLS];
    logic                            credit_east_in     [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_east_out    [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_east_out    [NUM_ROWS][NUM_COLS];
    logic                           is_tail_east_out    [NUM_ROWS][NUM_COLS];
    logic                              send_east_out    [NUM_ROWS][NUM_COLS];
    logic                            credit_east_out    [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_west_in     [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_west_in     [NUM_ROWS][NUM_COLS];
    logic                           is_tail_west_in     [NUM_ROWS][NUM_COLS];
    logic                              send_west_in     [NUM_ROWS][NUM_COLS];
    logic                            credit_west_in     [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_west_out    [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_west_out    [NUM_ROWS][NUM_COLS];
    logic                           is_tail_west_out    [NUM_ROWS][NUM_COLS];
    logic                              send_west_out    [NUM_ROWS][NUM_COLS];
    logic                            credit_west_out    [NUM_ROWS][NUM_COLS];

    // Declare packed router input and output ports
    logic   [FLIT_WIDTH - 1 : 0]       data_router_in   [NUM_ROWS * NUM_COLS][5];
    logic   [DEST_WIDTH - 1 : 0]       dest_router_in   [NUM_ROWS * NUM_COLS][5];
    logic                           is_tail_router_in   [NUM_ROWS * NUM_COLS][5];
    logic                              send_router_in   [NUM_ROWS * NUM_COLS][5];
    logic                            credit_router_out  [NUM_ROWS * NUM_COLS][5];

    logic   [FLIT_WIDTH - 1 : 0]       data_router_out  [NUM_ROWS * NUM_COLS][5];
    logic   [DEST_WIDTH - 1 : 0]       dest_router_out  [NUM_ROWS * NUM_COLS][5];
    logic                           is_tail_router_out  [NUM_ROWS * NUM_COLS][5];
    logic                              send_router_out  [NUM_ROWS * NUM_COLS][5];
    logic                            credit_router_in   [NUM_ROWS * NUM_COLS][5];

    // Assign router input and output ports
    always_comb begin
        for (int i = 0; i < NUM_ROWS; i++) begin
            for (int j = 0; j < NUM_COLS; j++) begin
                int ridx, idx;
                ridx = i * NUM_COLS + j;

                // NoC IO Ports
                   data_router_in[ridx][0] =    data_in[i][j];
                   dest_router_in[ridx][0] =    dest_in[i][j];
                is_tail_router_in[ridx][0] = is_tail_in[i][j];
                   send_router_in[ridx][0] =    send_in[i][j];
                          credit_out[i][j] = credit_router_out[ridx][0];

                // Read from the directional ports
                // North Side Ports
                   data_router_in[ridx][1] =    data_south_out[i][j];
                   dest_router_in[ridx][1] =    dest_south_out[i][j];
                is_tail_router_in[ridx][1] = is_tail_south_out[i][j];
                   send_router_in[ridx][1] =    send_south_out[i][j];
                     credit_south_in[i][j] = credit_router_out[ridx][1];

                // West Side Ports
                   data_router_in[ridx][2] =    data_east_out[i][j];
                   dest_router_in[ridx][2] =    dest_east_out[i][j];
                is_tail_router_in[ridx][2] = is_tail_east_out[i][j];
                   send_router_in[ridx][2] =    send_east_out[i][j];
                      credit_east_in[i][j] = credit_router_out[ridx][2];

                // South Side Ports
                   data_router_in[ridx][3] =    data_north_out[i][j];
                   dest_router_in[ridx][3] =    dest_north_out[i][j];
                is_tail_router_in[ridx][3] = is_tail_north_out[i][j];
                   send_router_in[ridx][3] =    send_north_out[i][j];
                     credit_north_in[i][j] = credit_router_out[ridx][3];

                // West Side Ports
                   data_router_in[ridx][4] =    data_west_out[i][j];
                   dest_router_in[ridx][4] =    dest_west_out[i][j];
                is_tail_router_in[ridx][4] = is_tail_west_out[i][j];
                   send_router_in[ridx][4] =    send_west_out[i][j];
                      credit_west_in[i][j] = credit_router_out[ridx][4];
            end
        end
    end

    // This split in the always block is necessary for Modelsim
    // to correctly assign the outputs without causing a delay
    // by triggering some signals only on the next clock edge
    always_comb begin
        for (int i = 0; i < NUM_ROWS; i++) begin
            for (int j = 0; j < NUM_COLS; j++) begin
                int ridx, idx;
                ridx = i * NUM_COLS + j;

                // NoC IO Ports
                   data_out [i][j] =    data_router_out[ridx][0];
                   dest_out [i][j] =    dest_router_out[ridx][0];
                is_tail_out [i][j] = is_tail_router_out[ridx][0];
                   send_out [i][j] =    send_router_out[ridx][0];
                credit_router_in[ridx][0] =    credit_in[i][j];

                // Write to the directional ports
                // North Side Ports
                      data_north_in[i][j] =    data_router_out[ridx][1];
                      dest_north_in[i][j] =    dest_router_out[ridx][1];
                   is_tail_north_in[i][j] = is_tail_router_out[ridx][1];
                      send_north_in[i][j] =    send_router_out[ridx][1];
                credit_router_in[ridx][1] =   credit_north_out[i][j];

                // West Side Ports
                       data_west_in[i][j] =    data_router_out[ridx][2];
                       dest_west_in[i][j] =    dest_router_out[ridx][2];
                    is_tail_west_in[i][j] = is_tail_router_out[ridx][2];
                       send_west_in[i][j] =    send_router_out[ridx][2];
                credit_router_in[ridx][2] =    credit_west_out[i][j];

                // South Side Ports
                      data_south_in[i][j] =    data_router_out[ridx][3];
                      dest_south_in[i][j] =    dest_router_out[ridx][3];
                   is_tail_south_in[i][j] = is_tail_router_out[ridx][3];
                      send_south_in[i][j] =    send_router_out[ridx][3];
                credit_router_in[ridx][3] =  credit_south_out[i][j];

                // East Side Ports
                       data_east_in[i][j] =    data_router_out[ridx][4];
                       dest_east_in[i][j] =    dest_router_out[ridx][4];
                    is_tail_east_in[i][j] = is_tail_router_out[ridx][4];
                       send_east_in[i][j] =    send_router_out[ridx][4];
                credit_router_in[ridx][4] =    credit_east_out[i][j];
            end
        end
    end

    // Generate routers
    generate begin: router_gen
        genvar i, j, k, l;
        for (i = 0; i < NUM_ROWS; i = i + 1) begin: for_rows
            for (j = 0; j < NUM_COLS; j = j + 1) begin: for_cols
                localparam ridx = i * NUM_COLS + j;

                // Generate routing table file name
                localparam string routing_table = $sformatf("%s%0d_%0d.hex", ROUTING_TABLE_PREFIX, i, j);

                bit DISABLE_TURNS[5][5];
                for (k = 0; k < 5; k = k + 1) begin
                    for (l = 0; l < 5; l = l + 1) begin
                        if ((DISABLE_SELFLOOP == 1) && (k == 0) && (l == 0)) begin
                            assign DISABLE_TURNS[0][0] = 1;
                        end else if ((k == l) && (k != 0) && (OPTIMIZE_FOR_ROUTING == "XY")) begin
                            assign DISABLE_TURNS[k][k] = 1;
                        end else if ((OPTIMIZE_FOR_ROUTING == "XY") && (k == 1 || k == 3) && (l == 2 || l == 4)) begin
                            assign DISABLE_TURNS[k][l] = 1;
                        end else begin
                            assign DISABLE_TURNS[k][l] = 0;
                        end
                    end
                end

                // Instantiate router
                router #(
                    .NOC_NUM_ENDPOINTS      (NUM_COLS * NUM_ROWS),
                    .ROUTING_TABLE_HEX      (routing_table),
                    .NUM_INPUTS             (5),
                    .NUM_OUTPUTS            (5),
                    .DEST_WIDTH             (DEST_WIDTH),
                    .FLIT_WIDTH             (FLIT_WIDTH),
                    .FLIT_BUFFER_DEPTH      (FLIT_BUFFER_DEPTH),
                    .PIPELINE_ROUTE_COMPUTE (ROUTER_PIPELINE_ROUTE_COMPUTE),
                    .PIPELINE_ARBITER       (ROUTER_PIPELINE_ARBITER),
                    .PIPELINE_OUTPUT        (ROUTER_PIPELINE_OUTPUT),
                    .FORCE_MLAB             (ROUTER_FORCE_MLAB)
                ) router_inst (
                    .clk            (clk),
                    .rst_n          (rst_n),

                    .data_in        (   data_router_in [ridx]),
                    .dest_in        (   dest_router_in [ridx]),
                    .is_tail_in     (is_tail_router_in [ridx]),
                    .send_in        (   send_router_in [ridx]),
                    .credit_out     ( credit_router_out[ridx]),

                    .data_out       (   data_router_out[ridx]),
                    .dest_out       (   dest_router_out[ridx]),
                    .is_tail_out    (is_tail_router_out[ridx]),
                    .send_out       (   send_router_out[ridx]),
                    .credit_in      ( credit_router_in [ridx]),

                    .DISABLE_TURNS  (DISABLE_TURNS)
                );
            end
        end
    end
    endgenerate

    generate begin: links_gen
        genvar i, j;
        for (i = 0; i < NUM_ROWS; i = i + 1) begin: for_rows
            for (j = 0; j < NUM_COLS; j = j + 1) begin: for_cols

                noc_pipeline_link #(
                    .NUM_PIPELINE(PIPELINE_LINKS + ((i == NUM_ROWS - 1) ? EXTRA_PIPELINE_LONG_LINKS : 0)),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                south_link_inst (
                    .clk         (clk),

                    .data_in     (data_south_in    [i][j]),
                    .dest_in     (dest_south_in    [i][j]),
                    .is_tail_in  (is_tail_south_in [i][j]),
                    .send_in     (send_south_in    [i][j]),
                    .credit_out  (credit_south_out [i][j]),

                    .data_out    (data_south_out   [(i + 1) % NUM_ROWS][j]),
                    .dest_out    (dest_south_out   [(i + 1) % NUM_ROWS][j]),
                    .is_tail_out (is_tail_south_out[(i + 1) % NUM_ROWS][j]),
                    .send_out    (send_south_out   [(i + 1) % NUM_ROWS][j]),
                    .credit_in   (credit_south_in  [(i + 1) % NUM_ROWS][j])
                );

                noc_pipeline_link #(
                    .NUM_PIPELINE(PIPELINE_LINKS + ((j == NUM_COLS - 1) ? EXTRA_PIPELINE_LONG_LINKS : 0)),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                east_link_inst (
                    .clk         (clk),

                    .data_in     (data_east_in    [i][j]),
                    .dest_in     (dest_east_in    [i][j]),
                    .is_tail_in  (is_tail_east_in [i][j]),
                    .send_in     (send_east_in    [i][j]),
                    .credit_out  (credit_east_out [i][j]),

                    .data_out    (data_east_out   [i][(j + 1) % NUM_COLS]),
                    .dest_out    (dest_east_out   [i][(j + 1) % NUM_COLS]),
                    .is_tail_out (is_tail_east_out[i][(j + 1) % NUM_COLS]),
                    .send_out    (send_east_out   [i][(j + 1) % NUM_COLS]),
                    .credit_in   (credit_east_in  [i][(j + 1) % NUM_COLS])
                );

                noc_pipeline_link #(
                    .NUM_PIPELINE(PIPELINE_LINKS + ((i == 0) ? EXTRA_PIPELINE_LONG_LINKS : 0)),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                north_link_inst (
                    .clk         (clk),

                    .data_in     (data_north_in    [i][j]),
                    .dest_in     (dest_north_in    [i][j]),
                    .is_tail_in  (is_tail_north_in [i][j]),
                    .send_in     (send_north_in    [i][j]),
                    .credit_out  (credit_north_out [i][j]),

                    .data_out    (data_north_out   [(i + NUM_ROWS - 1) % NUM_ROWS][j]),
                    .dest_out    (dest_north_out   [(i + NUM_ROWS - 1) % NUM_ROWS][j]),
                    .is_tail_out (is_tail_north_out[(i + NUM_ROWS - 1) % NUM_ROWS][j]),
                    .send_out    (send_north_out   [(i + NUM_ROWS - 1) % NUM_ROWS][j]),
                    .credit_in   (credit_north_in  [(i + NUM_ROWS - 1) % NUM_ROWS][j])
                );

                noc_pipeline_link #(
                    .NUM_PIPELINE(PIPELINE_LINKS + ((j == 0) ? EXTRA_PIPELINE_LONG_LINKS : 0)),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                west_link_inst (
                    .clk         (clk),

                    .data_in     (data_west_in    [i][j]),
                    .dest_in     (dest_west_in    [i][j]),
                    .is_tail_in  (is_tail_west_in [i][j]),
                    .send_in     (send_west_in    [i][j]),
                    .credit_out  (credit_west_out [i][j]),

                    .data_out    (data_west_out   [i][(j + NUM_COLS - 1) % NUM_COLS]),
                    .dest_out    (dest_west_out   [i][(j + NUM_COLS - 1) % NUM_COLS]),
                    .is_tail_out (is_tail_west_out[i][(j + NUM_COLS - 1) % NUM_COLS]),
                    .send_out    (send_west_out   [i][(j + NUM_COLS - 1) % NUM_COLS]),
                    .credit_in   (credit_west_in  [i][(j + NUM_COLS - 1) % NUM_COLS])
                );
            end
        end
    end
    endgenerate

 endmodule: torus
