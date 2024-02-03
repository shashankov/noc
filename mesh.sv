/**
 * @file mesh.sv
 *
 * @brief Mesh NoC with native interface
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

 module mesh #(
    parameter NUM_ROWS = 4,
    parameter NUM_COLS = 4,
    parameter DEST_WIDTH = 4,           // clog2(NUM_ROWS * NUM_COLS)
    parameter FLIT_WIDTH = 128,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter PIPELINE_LINKS = 0,
    parameter ROUTING_TABLE_PREFIX = "routing_tables/mesh_4x4/",
    parameter bit ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter bit ROUTER_PIPELINE_ARBITER = 0,
    parameter bit ROUTER_PIPELINE_OUTPUT = 1,
    parameter bit DISABLE_SELFLOOP = 1,
    parameter OPTIMIZE_FOR_ROUTING = "XY",
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
                idx = 0;

                // NoC IO Ports
                   data_router_in [ridx][idx] =    data_in  [i][j];
                   dest_router_in [ridx][idx] =    dest_in  [i][j];
                is_tail_router_in [ridx][idx] = is_tail_in  [i][j];
                   send_router_in [ridx][idx] =    send_in  [i][j];
                 credit_router_in [ridx][idx] =  credit_in  [i][j];

                // Read from the directional ports
                // North Side Ports
                if (i != 0) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_south_out [i - 1][j];
                       dest_router_in   [ridx][idx] =    dest_south_out [i - 1][j];
                    is_tail_router_in   [ridx][idx] = is_tail_south_out [i - 1][j];
                       send_router_in   [ridx][idx] =    send_south_out [i - 1][j];
                     credit_router_in   [ridx][idx] =  credit_north_out [i][j];
                end

                // South Side Ports
                if (i != (NUM_ROWS - 1)) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_north_out [i + 1][j];
                       dest_router_in   [ridx][idx] =    dest_north_out [i + 1][j];
                    is_tail_router_in   [ridx][idx] = is_tail_north_out [i + 1][j];
                       send_router_in   [ridx][idx] =    send_north_out [i + 1][j];
                     credit_router_in   [ridx][idx] =  credit_south_out [i][j];
                end

                // East Side Ports
                if (j != (NUM_COLS - 1)) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_west_out  [i][j + 1];
                       dest_router_in   [ridx][idx] =    dest_west_out  [i][j + 1];
                    is_tail_router_in   [ridx][idx] = is_tail_west_out  [i][j + 1];
                       send_router_in   [ridx][idx] =    send_west_out  [i][j + 1];
                     credit_router_in   [ridx][idx] =  credit_east_out  [i][j];
                end

                // West Side Ports
                if (j != 0) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_east_out  [i][j - 1];
                       dest_router_in   [ridx][idx] =    dest_east_out  [i][j - 1];
                    is_tail_router_in   [ridx][idx] = is_tail_east_out  [i][j - 1];
                       send_router_in   [ridx][idx] =    send_east_out  [i][j - 1];
                     credit_router_in   [ridx][idx] =  credit_west_out  [i][j];
                end
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
                idx = 0;

                // NoC IO Ports
                   data_out [i][j] =    data_router_out [ridx][idx];
                   dest_out [i][j] =    dest_router_out [ridx][idx];
                is_tail_out [i][j] = is_tail_router_out [ridx][idx];
                   send_out [i][j] =    send_router_out [ridx][idx];
                 credit_out [i][j] =  credit_router_out [ridx][idx];

                // Write to the directional ports
                // North Side Ports
                if (i != 0) begin
                    idx = idx + 1;
                       data_north_in       [i][j] =    data_router_out [ridx][idx];
                       dest_north_in       [i][j] =    dest_router_out [ridx][idx];
                    is_tail_north_in       [i][j] = is_tail_router_out [ridx][idx];
                       send_north_in       [i][j] =    send_router_out [ridx][idx];
                     credit_south_in   [i - 1][j] =  credit_router_out [ridx][idx];
                end

                // South Side Ports
                if (i != (NUM_ROWS - 1)) begin
                    idx = idx + 1;
                       data_south_in       [i][j] =    data_router_out [ridx][idx];
                       dest_south_in       [i][j] =    dest_router_out [ridx][idx];
                    is_tail_south_in       [i][j] = is_tail_router_out [ridx][idx];
                       send_south_in       [i][j] =    send_router_out [ridx][idx];
                     credit_north_in   [i + 1][j] =  credit_router_out [ridx][idx];
                end

                // East Side Ports
                if (j != (NUM_COLS - 1)) begin
                    idx = idx + 1;
                       data_east_in        [i][j] =    data_router_out [ridx][idx];
                       dest_east_in        [i][j] =    dest_router_out [ridx][idx];
                    is_tail_east_in        [i][j] = is_tail_router_out [ridx][idx];
                       send_east_in        [i][j] =    send_router_out [ridx][idx];
                     credit_west_in    [i][j + 1] =  credit_router_out [ridx][idx];
                end

                // West Side Ports
                if (j != 0) begin
                    idx = idx + 1;
                       data_west_in        [i][j] =    data_router_out [ridx][idx];
                       dest_west_in        [i][j] =    dest_router_out [ridx][idx];
                    is_tail_west_in        [i][j] = is_tail_router_out [ridx][idx];
                       send_west_in        [i][j] =    send_router_out [ridx][idx];
                     credit_east_in    [i][j - 1] =  credit_router_out [ridx][idx];
                end
            end
        end
    end

    // Generate routers
    generate begin: router_gen
        genvar i, j, k, l;
        for (i = 0; i < NUM_ROWS; i = i + 1) begin: for_rows
            for (j = 0; j < NUM_COLS; j = j + 1) begin: for_cols

                // Calculate number of IO ports
                localparam num_io = 5 - ((i == 0) || i == (NUM_ROWS - 1))
                                      - ((j == 0) || j == (NUM_COLS - 1));
                localparam ridx = i * NUM_COLS + j;

                // Generate routing table file name
                localparam string routing_table = $sformatf("%s%0d_%0d.hex", ROUTING_TABLE_PREFIX, i, j);

                bit DISABLE_TURNS[num_io][num_io];
                for (k = 0; k < num_io; k = k + 1) begin
                    for (l = 0; l < num_io; l = l + 1) begin
                        if ((DISABLE_SELFLOOP == 1) && (k == l) && (k == 0)) begin
                            assign DISABLE_TURNS[k][l] = 1;
                        end else if ((k == l) && (k != 0) && (OPTIMIZE_FOR_ROUTING == "XY")) begin
                            assign DISABLE_TURNS[k][l] = 1;
                        end else if ((k != l) && (l != 0) && (OPTIMIZE_FOR_ROUTING == "XY")) begin
                            // First and last row disable north to any east and west port
                            if (((i == 0) || (i == NUM_ROWS - 1)) && (k == 1)) assign DISABLE_TURNS[k][l] = 1;
                            // All other rows disable north and south to any east and west port
                            else if (!((i == 0) || (i == NUM_ROWS - 1)) && ((k == 1) || (k == 2)) && (l > 2)) assign DISABLE_TURNS[k][l] = 1;
                            else assign DISABLE_TURNS[k][l] = 0;
                        end else begin
                            assign DISABLE_TURNS[k][l] = 0;
                        end
                    end
                end

                // Instantiate router
                router #(
                    .NOC_NUM_ENDPOINTS      (NUM_COLS * NUM_ROWS),
                    .ROUTING_TABLE_HEX      (routing_table),
                    .NUM_INPUTS             (num_io),
                    .NUM_OUTPUTS            (num_io),
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

                    .data_in        (   data_router_in [ridx][0 : num_io - 1]),
                    .dest_in        (   dest_router_in [ridx][0 : num_io - 1]),
                    .is_tail_in     (is_tail_router_in [ridx][0 : num_io - 1]),
                    .send_in        (   send_router_in [ridx][0 : num_io - 1]),
                    .credit_out     ( credit_router_out[ridx][0 : num_io - 1]),

                    .data_out       (   data_router_out[ridx][0 : num_io - 1]),
                    .dest_out       (   dest_router_out[ridx][0 : num_io - 1]),
                    .is_tail_out    (is_tail_router_out[ridx][0 : num_io - 1]),
                    .send_out       (   send_router_out[ridx][0 : num_io - 1]),
                    .credit_in      ( credit_router_in [ridx][0 : num_io - 1]),

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
                    .NUM_PIPELINE(PIPELINE_LINKS),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                north_link_inst (
                    .clk         (clk),

                    .data_in     (data_north_in[i][j]),
                    .dest_in     (dest_north_in[i][j]),
                    .is_tail_in  (is_tail_north_in[i][j]),
                    .send_in     (send_north_in[i][j]),
                    .credit_out  (credit_north_out[i][j]),

                    .data_out    (data_north_out[i][j]),
                    .dest_out    (dest_north_out[i][j]),
                    .is_tail_out (is_tail_north_out[i][j]),
                    .send_out    (send_north_out[i][j]),
                    .credit_in   (credit_north_in[i][j])
                );

                noc_pipeline_link #(
                    .NUM_PIPELINE(PIPELINE_LINKS),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                south_link_inst (
                    .clk         (clk),

                    .data_in     (data_south_in[i][j]),
                    .dest_in     (dest_south_in[i][j]),
                    .is_tail_in  (is_tail_south_in[i][j]),
                    .send_in     (send_south_in[i][j]),
                    .credit_out  (credit_south_out[i][j]),

                    .data_out    (data_south_out[i][j]),
                    .dest_out    (dest_south_out[i][j]),
                    .is_tail_out (is_tail_south_out[i][j]),
                    .send_out    (send_south_out[i][j]),
                    .credit_in   (credit_south_in[i][j])
                );

                noc_pipeline_link #(
                    .NUM_PIPELINE(PIPELINE_LINKS),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                east_link_inst (
                    .clk         (clk),

                    .data_in     (data_east_in[i][j]),
                    .dest_in     (dest_east_in[i][j]),
                    .is_tail_in  (is_tail_east_in[i][j]),
                    .send_in     (send_east_in[i][j]),
                    .credit_out  (credit_east_out[i][j]),

                    .data_out    (data_east_out[i][j]),
                    .dest_out    (dest_east_out[i][j]),
                    .is_tail_out (is_tail_east_out[i][j]),
                    .send_out    (send_east_out[i][j]),
                    .credit_in   (credit_east_in[i][j])
                );

                noc_pipeline_link #(
                    .NUM_PIPELINE(PIPELINE_LINKS),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .DEST_WIDTH(DEST_WIDTH))
                west_link_inst (
                    .clk         (clk),

                    .data_in     (data_west_in[i][j]),
                    .dest_in     (dest_west_in[i][j]),
                    .is_tail_in  (is_tail_west_in[i][j]),
                    .send_in     (send_west_in[i][j]),
                    .credit_out  (credit_west_out[i][j]),

                    .data_out    (data_west_out[i][j]),
                    .dest_out    (dest_west_out[i][j]),
                    .is_tail_out (is_tail_west_out[i][j]),
                    .send_out    (send_west_out[i][j]),
                    .credit_in   (credit_west_in[i][j])
                );
            end
        end
    end
    endgenerate

endmodule: mesh