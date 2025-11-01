/**
 * @file butterfly.sv
 *
 * @brief k-ary n-fly Butterfly NoC with native interface
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

module butterfly #(
    parameter K = 2,
    parameter N = 2,
    parameter DEST_WIDTH = 4,
    parameter FLIT_WIDTH = 256,
    parameter FLIT_BUFFER_DEPTH = 2,
    parameter ROUTING_TABLE_PREFIX = "routing_tables/butterfly_2_2/",
    parameter bit ROUTER_PIPELINE_ROUTE_COMPUTE = 1,
    parameter bit ROUTER_PIPELINE_ARBITER = 0,
    parameter bit ROUTER_PIPELINE_OUTPUT = 0,
    parameter bit ROUTER_FORCE_MLAB = 0
) (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [FLIT_WIDTH - 1 : 0]    data_in     [K ** N],
    input   wire    [DEST_WIDTH - 1 : 0]    dest_in     [K ** N],
    input   wire                            is_tail_in  [K ** N],
    input   wire                            send_in     [K ** N],
    output  logic                           credit_out  [K ** N],

    output  logic   [FLIT_WIDTH - 1 : 0]    data_out    [K ** N],
    output  logic   [DEST_WIDTH - 1 : 0]    dest_out    [K ** N],
    output  logic                           is_tail_out [K ** N],
    output  logic                           send_out    [K ** N],
    input   wire                            credit_in   [K ** N]
);

    // Declare all intermediate signals of routers
    logic  [FLIT_WIDTH - 1 : 0]       data_int[K ** N][N + 1];
    logic  [DEST_WIDTH - 1 : 0]       dest_int[K ** N][N + 1];
    logic                          is_tail_int[K ** N][N + 1];
    logic                             send_int[K ** N][N + 1];
    logic                           credit_int[K ** N][N + 1];

    bit DISABLE_TURNS[K][K];
    always_comb begin
        for (int i = 0; i < K; i = i + 1) begin
            for (int j = 0; j < K; j = j + 1) begin
                DISABLE_TURNS[i][j] = 0;
            end
        end
    end

    // Temporary signals to connect to router instance
    logic  [FLIT_WIDTH - 1 : 0]       data_router_in[N][K ** (N - 1)][K];
    logic  [DEST_WIDTH - 1 : 0]       dest_router_in[N][K ** (N - 1)][K];
    logic                          is_tail_router_in[N][K ** (N - 1)][K];
    logic                             send_router_in[N][K ** (N - 1)][K];
    logic                           credit_router_in[N][K ** (N - 1)][K];

    logic  [FLIT_WIDTH - 1 : 0]       data_router_out[N][K ** (N - 1)][K];
    logic  [DEST_WIDTH - 1 : 0]       dest_router_out[N][K ** (N - 1)][K];
    logic                          is_tail_router_out[N][K ** (N - 1)][K];
    logic                             send_router_out[N][K ** (N - 1)][K];
    logic                           credit_router_out[N][K ** (N - 1)][K];

    always_comb begin
        for (int stage = 0; stage < N; stage = stage + 1) begin
            for (int sub_stage = 0; sub_stage < K ** (N - 1 - stage); sub_stage = sub_stage + 1) begin
                for (int i = 0; i < K ** (stage); i = i + 1) begin
                    for (int p = 0; p < K; p = p + 1) begin
                        // Connect router inputs
                        if (stage == 0) begin
                            data_router_in[stage][sub_stage * (K ** stage) + i][p]    = data_in[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)];
                            dest_router_in[stage][sub_stage * (K ** stage) + i][p]    = dest_in[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)];
                            is_tail_router_in[stage][sub_stage * (K ** stage) + i][p] = is_tail_in[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)];
                            send_router_in[stage][sub_stage * (K ** stage) + i][p]    = send_in[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)];
                            credit_out[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)] = credit_router_in[stage][sub_stage * (K ** stage) + i][p];
                        end else begin
                            data_router_in[stage][sub_stage * (K ** stage) + i][p]    = data_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage];
                            dest_router_in[stage][sub_stage * (K ** stage) + i][p]    = dest_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage];
                            is_tail_router_in[stage][sub_stage * (K ** stage) + i][p] = is_tail_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage];
                            send_router_in[stage][sub_stage * (K ** stage) + i][p]    = send_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage];
                            credit_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage] = credit_router_in[stage][sub_stage * (K ** stage) + i][p];
                        end
                    end
                end
            end
        end
    end

    always_comb begin
        for (int stage = 0; stage < N; stage = stage + 1) begin
            for (int sub_stage = 0; sub_stage < K ** (N - 1 - stage); sub_stage = sub_stage + 1) begin
                for (int i = 0; i < K ** (stage); i = i + 1) begin
                    for (int p = 0; p < K; p = p + 1) begin
                        // Connect router outputs
                        if (stage == N - 1) begin
                            data_out[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)]    = data_router_out[stage][sub_stage * (K ** stage) + i][p];
                            dest_out[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)]    = dest_router_out[stage][sub_stage * (K ** stage) + i][p];
                            is_tail_out[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)] = is_tail_router_out[stage][sub_stage * (K ** stage) + i][p];
                            send_out[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)]    = send_router_out[stage][sub_stage * (K ** stage) + i][p];
                            credit_router_out[stage][sub_stage * (K ** stage) + i][p] = credit_in[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)];
                        end else begin
                            data_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage + 1]    = data_router_out[stage][sub_stage * (K ** stage) + i][p];
                            dest_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage + 1]    = dest_router_out[stage][sub_stage * (K ** stage) + i][p];
                            is_tail_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage + 1] = is_tail_router_out[stage][sub_stage * (K ** stage) + i][p];
                            send_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage + 1]    = send_router_out[stage][sub_stage * (K ** stage) + i][p];
                            credit_router_out[stage][sub_stage * (K ** stage) + i][p] = credit_int[i + sub_stage * (K ** (stage + 1)) + p * (K ** stage)][stage + 1];
                        end
                    end
                end
            end
        end
    end

    generate begin: gen_butterfly_routers
        genvar stage, i;
        for (stage = 0; stage < N; stage = stage + 1) begin: for_stages
            for (i = 0; i < K ** (N - 1); i = i + 1) begin: for_routers
                localparam string routing_table = $sformatf("%s/%0d_%0d.hex", ROUTING_TABLE_PREFIX, stage, i);
                // Instantiate router
                router #(
                    .NOC_NUM_ENDPOINTS      (K ** N),
                    .ROUTING_TABLE_HEX      (routing_table),
                    .NUM_INPUTS             (K),
                    .NUM_OUTPUTS            (K),
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

                    .data_in        (   data_router_in[stage][i]),
                    .dest_in        (   dest_router_in[stage][i]),
                    .is_tail_in     (is_tail_router_in[stage][i]),
                    .send_in        (   send_router_in[stage][i]),
                    .credit_out     ( credit_router_in[stage][i]),

                    .data_out       (   data_router_out[stage][i]),
                    .dest_out       (   dest_router_out[stage][i]),
                    .is_tail_out    (is_tail_router_out[stage][i]),
                    .send_out       (   send_router_out[stage][i]),
                    .credit_in      ( credit_router_out[stage][i]),

                    .DISABLE_TURNS  (DISABLE_TURNS)
                );
            end

        end
    end
    endgenerate

endmodule: butterfly
