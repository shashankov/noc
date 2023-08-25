module mesh #(
    parameter NUM_ROWS = 2,
    parameter NUM_COLS = 2,
    parameter DEST_WIDTH = 4,           // clog2(NUM_ROWS * NUM_COLS)
    parameter FLIT_WIDTH = 256,
    parameter FLIT_BUFFER_DEPTH = 2,
    parameter ROUTING_TABLE_PREFIX = "routing_tables/mesh_2x2/",
    parameter ROUTER_PIPELINE_OUTPUT = 0,
    parameter ROUTER_DISABLE_SELFLOOP = 0,
    parameter ROUTER_FORCE_MLAB = 0
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
    logic   [FLIT_WIDTH - 1 : 0]       data_north   [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_north   [NUM_ROWS][NUM_COLS];
    logic                           is_tail_north   [NUM_ROWS][NUM_COLS];
    logic                              send_north   [NUM_ROWS][NUM_COLS];
    logic                            credit_north   [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_south   [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_south   [NUM_ROWS][NUM_COLS];
    logic                           is_tail_south   [NUM_ROWS][NUM_COLS];
    logic                              send_south   [NUM_ROWS][NUM_COLS];
    logic                            credit_south   [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_east    [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_east    [NUM_ROWS][NUM_COLS];
    logic                           is_tail_east    [NUM_ROWS][NUM_COLS];
    logic                              send_east    [NUM_ROWS][NUM_COLS];
    logic                            credit_east    [NUM_ROWS][NUM_COLS];

    logic   [FLIT_WIDTH - 1 : 0]       data_west    [NUM_ROWS][NUM_COLS];
    logic   [DEST_WIDTH - 1 : 0]       dest_west    [NUM_ROWS][NUM_COLS];
    logic                           is_tail_west    [NUM_ROWS][NUM_COLS];
    logic                              send_west    [NUM_ROWS][NUM_COLS];
    logic                            credit_west    [NUM_ROWS][NUM_COLS];

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
    always @(*) begin
        for (int i = 0; i < NUM_ROWS; i++) begin
            for (int j = 0; j < NUM_COLS; j++) begin
                int ridx, idx;
                ridx = i * NUM_COLS + j;
                idx = 0;
                // Read from the directional ports
                // North Side Ports
                if (i != 0) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_south [i - 1][j];
                       dest_router_in   [ridx][idx] =    dest_south [i - 1][j];
                    is_tail_router_in   [ridx][idx] = is_tail_south [i - 1][j];
                       send_router_in   [ridx][idx] =    send_south [i - 1][j];
                     credit_router_in   [ridx][idx] =  credit_north [i][j];
                end

                // South Side Ports
                if (i != (NUM_ROWS - 1)) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_north [i + 1][j];
                       dest_router_in   [ridx][idx] =    dest_north [i + 1][j];
                    is_tail_router_in   [ridx][idx] = is_tail_north [i + 1][j];
                       send_router_in   [ridx][idx] =    send_north [i + 1][j];
                     credit_router_in   [ridx][idx] =  credit_south [i][j];
                end

                // East Side Ports
                if (j != (NUM_COLS - 1)) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_west  [i][j + 1];
                       dest_router_in   [ridx][idx] =    dest_west  [i][j + 1];
                    is_tail_router_in   [ridx][idx] = is_tail_west  [i][j + 1];
                       send_router_in   [ridx][idx] =    send_west  [i][j + 1];
                     credit_router_in   [ridx][idx] =  credit_east  [i][j];
                end

                // West Side Ports
                if (j != 0) begin
                    idx = idx + 1;
                       data_router_in   [ridx][idx] =    data_east  [i][j - 1];
                       dest_router_in   [ridx][idx] =    dest_east  [i][j - 1];
                    is_tail_router_in   [ridx][idx] = is_tail_east  [i][j - 1];
                       send_router_in   [ridx][idx] =    send_east  [i][j - 1];
                     credit_router_in   [ridx][idx] =  credit_west  [i][j];
                end
            end
        end
    end

    // This split in the alwasy block is necessary for Modelsim
    // to correctly assign the outputs without causing a delay
    // by triggering some signals only on the next clock edge
    always @(*) begin
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

                   data_out [i][j] =    data_router_out [ridx][idx];
                   dest_out [i][j] =    dest_router_out [ridx][idx];
                is_tail_out [i][j] = is_tail_router_out [ridx][idx];
                   send_out [i][j] =    send_router_out [ridx][idx];
                 credit_out [i][j] =  credit_router_out [ridx][idx];

                // Write to the directional ports
                // North Side Ports
                if (i != 0) begin
                    idx = idx + 1;
                       data_north       [i][j] =    data_router_out [ridx][idx];
                       dest_north       [i][j] =    dest_router_out [ridx][idx];
                    is_tail_north       [i][j] = is_tail_router_out [ridx][idx];
                       send_north       [i][j] =    send_router_out [ridx][idx];
                     credit_south   [i - 1][j] =  credit_router_out [ridx][idx];
                end

                // South Side Ports
                if (i != (NUM_ROWS - 1)) begin
                    idx = idx + 1;
                       data_south       [i][j] =    data_router_out [ridx][idx];
                       dest_south       [i][j] =    dest_router_out [ridx][idx];
                    is_tail_south       [i][j] = is_tail_router_out [ridx][idx];
                       send_south       [i][j] =    send_router_out [ridx][idx];
                     credit_north   [i + 1][j] =  credit_router_out [ridx][idx];
                end

                // East Side Ports
                if (j != (NUM_COLS - 1)) begin
                    idx = idx + 1;
                       data_east        [i][j] =    data_router_out [ridx][idx];
                       dest_east        [i][j] =    dest_router_out [ridx][idx];
                    is_tail_east        [i][j] = is_tail_router_out [ridx][idx];
                       send_east        [i][j] =    send_router_out [ridx][idx];
                     credit_west    [i][j + 1] =  credit_router_out [ridx][idx];
                end

                // West Side Ports
                if (j != 0) begin
                    idx = idx + 1;
                       data_west        [i][j] =    data_router_out [ridx][idx];
                       dest_west        [i][j] =    dest_router_out [ridx][idx];
                    is_tail_west        [i][j] = is_tail_router_out [ridx][idx];
                       send_west        [i][j] =    send_router_out [ridx][idx];
                     credit_east    [i][j - 1] =  credit_router_out [ridx][idx];
                end
            end
        end
    end

    // Generate routers
    generate begin: router_gen
        genvar i, j;
        for (i = 0; i < NUM_ROWS; i = i + 1) begin: for_rows
            for (j = 0; j < NUM_COLS; j = j + 1) begin: for_cols

                // Calculate number of IO ports
                localparam num_io = 5 - ((i == 0) || i == (NUM_ROWS - 1))
                                      - ((j == 0) || j == (NUM_COLS - 1));
                localparam ridx = i * NUM_COLS + j;

                // Generate routing table file name
                localparam string routing_table = $sformatf("%s%0d_%0d.hex", ROUTING_TABLE_PREFIX, i, j);

                // Instantiate router
                router #(
                    .NOC_NUM_ENDPOINTS  (NUM_COLS * NUM_ROWS),
                    .ROUTING_TABLE_HEX  (routing_table),
                    .NUM_INPUTS         (num_io),
                    .NUM_OUTPUTS        (num_io),
                    .DEST_WIDTH         (DEST_WIDTH),
                    .FLIT_WIDTH         (FLIT_WIDTH),
                    .FLIT_BUFFER_DEPTH  (FLIT_BUFFER_DEPTH),
                    .PIPELINE_OUTPUT    (ROUTER_PIPELINE_OUTPUT),
                    .DISABLE_SELFLOOP   (ROUTER_DISABLE_SELFLOOP),
                    .FORCE_MLAB         (ROUTER_FORCE_MLAB)
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
                    .credit_in      ( credit_router_in [ridx][0 : num_io - 1])
                );
            end
        end
    end
    endgenerate

endmodule: mesh