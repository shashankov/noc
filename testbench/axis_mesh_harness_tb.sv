`timescale 1ns / 1ps

module axis_mesh_harness_tb();
    localparam NUM_ROWS = 2;
    localparam NUM_COLS = 2;
    localparam DATA_WIDTH = 32;
    localparam TDEST_WIDTH = 2;
    localparam TID_WIDTH = 2;
    localparam SERIALIZATION_FACTOR = 2;
    localparam COUNT_WIDTH = 16;

    localparam logic [63 : 0] DEST_SEED[NUM_ROWS * NUM_COLS] = {
        64'b0101111011110001111000100100010000011011000001011000000011000110,
        64'b0011101110100111000111010110111111011111011010010011001010111111,
        64'b0011001000110001111011111000011001110111011111100101011101001010,
        64'b1001010010001101010011110101111110100111100101100111101111001100};

    localparam logic [15 : 0] LOAD_SEED[NUM_ROWS * NUM_COLS] = {
        16'b1111011100111000,
        16'b0011101010011110,
        16'b0011100010101111,
        16'b0111100111001100};

    logic clk, clk_noc, rst_n;
    logic [DATA_WIDTH / 2 - 1 : 0] ticks;

    logic                       axis_in_tvalid  [NUM_ROWS][NUM_COLS];
    logic                       axis_in_tready  [NUM_ROWS][NUM_COLS];
    logic [DATA_WIDTH - 1 : 0]  axis_in_tdata   [NUM_ROWS][NUM_COLS];
    logic                       axis_in_tlast   [NUM_ROWS][NUM_COLS];
    logic [TDEST_WIDTH - 1 : 0] axis_in_tdest   [NUM_ROWS][NUM_COLS];
    logic [TID_WIDTH - 1 : 0]   axis_in_tid     [NUM_ROWS][NUM_COLS];

    logic                       axis_out_tvalid [NUM_ROWS][NUM_COLS];
    logic                       axis_out_tready [NUM_ROWS][NUM_COLS];
    logic [DATA_WIDTH - 1 : 0]  axis_out_tdata  [NUM_ROWS][NUM_COLS];
    logic                       axis_out_tlast  [NUM_ROWS][NUM_COLS];
    logic [TDEST_WIDTH - 1 : 0] axis_out_tdest  [NUM_ROWS][NUM_COLS];
    logic [TID_WIDTH - 1 : 0]   axis_out_tid    [NUM_ROWS][NUM_COLS];

    logic                       done            [NUM_ROWS][NUM_COLS];
    logic                       start           [NUM_ROWS][NUM_COLS];
    logic [COUNT_WIDTH - 1 : 0] sent_packets    [NUM_ROWS][NUM_COLS][2**TDEST_WIDTH];
    logic [COUNT_WIDTH - 1 : 0] recv_packets    [NUM_ROWS][NUM_COLS][2**TID_WIDTH];
    logic                       error           [NUM_ROWS][NUM_COLS];

    always_ff @(posedge clk) begin
        if (rst_n == 0) begin
            ticks <= 0;
        end else begin
            ticks <= ticks + 1'b1;
        end
    end

    initial begin
        clk = 0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        clk_noc = 0;
        forever begin
            #5 clk_noc = ~clk_noc;
        end
    end

    logic all_done;
    initial begin
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        for (int i = 0; i < NUM_ROWS; i = i + 1) begin
            for (int j = 0; j < NUM_COLS; j = j + 1) begin
                start[i][j] = 1'b1;
            end
        end
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);

        forever begin
            @(negedge clk);
            all_done = 1'b1;
            for (int i = 0; i < NUM_ROWS; i = i + 1) begin
                for (int j = 0; j < NUM_COLS; j = j + 1) begin
                    if (done[i][j] == 0) begin
                        all_done = 1'b0;
                    end else begin
                        start[i][j] = 1'b0;
                    end
                end
            end
            if (all_done) begin
                $display("All done!");
                $finish;
            end else if (ticks >= (1 << 15)) begin
                $display("Timeout!");
                $finish;
            end
        end
    end

    generate begin: harness_gen
        genvar i, j;
        for (i = 0; i < NUM_ROWS; i = i + 1) begin: for_rows
            for (j = 0; j < NUM_COLS; j = j + 1) begin: for_cols
            axis_tg #(
                .DEST_SEED      (DEST_SEED[i * NUM_COLS + j]),
                .LOAD_SEED      (LOAD_SEED[i * NUM_COLS + j]),

                .COUNT_WIDTH    (COUNT_WIDTH),
                .TID            (i * NUM_COLS + j),

                .TDATA_WIDTH    (DATA_WIDTH),
                .TDEST_WIDTH    (TDEST_WIDTH),
                .TID_WIDTH      (TID_WIDTH))
            tg_inst (
                .clk,
                .rst_n,

                .load           (16'b1 << 14),
                .num_packets    (16'b1 << 10),

                .start          (start[i][j]),
                .ticks,
                .done           (done[i][j]),
                .sent_packets   (sent_packets[i][j]),

                .axis_out_tvalid    (axis_in_tvalid[i][j]),
                .axis_out_tready    (axis_in_tready[i][j]),
                .axis_out_tdata     (axis_in_tdata[i][j]),
                .axis_out_tlast     (axis_in_tlast[i][j]),
                .axis_out_tid       (axis_in_tid[i][j]),
                .axis_out_tdest     (axis_in_tdest[i][j])
            );

            axis_checker #(
                .COUNT_WIDTH    (COUNT_WIDTH),
                .TDEST          (i * NUM_COLS + j),

                .TDATA_WIDTH    (DATA_WIDTH),
                .TDEST_WIDTH    (TDEST_WIDTH),
                .TID_WIDTH      (TID_WIDTH))
            checker_inst (
                .clk,
                .rst_n,

                .ticks,
                .recv_packets   (recv_packets[i][j]),
                .error          (error[i][j]),

                .axis_in_tvalid (axis_out_tvalid[i][j]),
                .axis_in_tready (axis_out_tready[i][j]),
                .axis_in_tdata  (axis_out_tdata[i][j]),
                .axis_in_tlast  (axis_out_tlast[i][j]),
                .axis_in_tid    (axis_out_tid[i][j]),
                .axis_in_tdest  (axis_out_tdest[i][j])
            );
            end
        end
    end
    endgenerate

    axis_mesh #(
        .NUM_ROWS                   (NUM_ROWS),
        .NUM_COLS                   (NUM_COLS),
        .PIPELINE_LINKS             (1),

        .TDEST_WIDTH                (TDEST_WIDTH),
        .TDATA_WIDTH                (DATA_WIDTH),
        .SERIALIZATION_FACTOR       (SERIALIZATION_FACTOR),
        .CLKCROSS_FACTOR            (1),
        .SINGLE_CLOCK               (1),
        .SERDES_IN_BUFFER_DEPTH     (4),
        .SERDES_OUT_BUFFER_DEPTH    (4),
        .SERDES_EXTRA_SYNC_STAGES   (0),

        .FLIT_BUFFER_DEPTH          (4),
        .ROUTING_TABLE_PREFIX       ("routing_tables/mesh_2x2/"),
        .ROUTER_PIPELINE_OUTPUT     (1),
        .ROUTER_DISABLE_SELFLOOP    (0),
        .ROUTER_FORCE_MLAB          (0)
    ) dut (
        .clk_noc(clk_noc),
        .clk_usr(clk),
        .rst_n,

        .axis_in_tvalid ,
        .axis_in_tready ,
        .axis_in_tdata  ,
        .axis_in_tlast  ,
        .axis_in_tid    ,
        .axis_in_tdest  ,

        .axis_out_tvalid,
        .axis_out_tready,
        .axis_out_tdata ,
        .axis_out_tlast ,
        .axis_out_tid   ,
        .axis_out_tdest
    );

endmodule: axis_mesh_harness_tb