`timescale 1ns/1ps

module router #(
    parameter NOC_NUM_ENDPOINTS = 5,
    parameter ROUTING_TABLE_HEX = "routing_tables/router_tb_5x5.hex",
    parameter NUM_INPUTS = 5,
    parameter NUM_OUTPUTS = 5,
    parameter DEST_WIDTH = 3,
    parameter FLIT_WIDTH = 256,
    parameter FLIT_BUFFER_DEPTH = 2,
    parameter PIPELINE_OUTPUT = 0,
    parameter DISABLE_SELFLOOP = 0,     // Useful for IO pairs were data will not go back to the same router
    parameter FORCE_MLAB = 1
) (
    input   wire    clk,
    input   wire    rst_n,

    input   wire    [FLIT_WIDTH - 1 : 0]    data_in     [NUM_INPUTS],
    input   wire    [DEST_WIDTH - 1 : 0]    dest_in     [NUM_INPUTS],
    input   wire                            is_tail_in  [NUM_INPUTS],
    input   wire                            send_in     [NUM_INPUTS],
    output  logic                           credit_out  [NUM_INPUTS],

    output  logic   [FLIT_WIDTH - 1 : 0]    data_out    [NUM_OUTPUTS],
    output  logic   [DEST_WIDTH - 1 : 0]    dest_out    [NUM_OUTPUTS],
    output  logic                           is_tail_out [NUM_OUTPUTS],
    output  logic                           send_out    [NUM_INPUTS],
    input   wire                            credit_in   [NUM_OUTPUTS]
);
    /**************************************************************************/
    /****************************** Declarations ******************************/
    /**************************************************************************/

    // Routing Tables
    logic [$clog2(NUM_OUTPUTS) - 1 : 0]         route_table         [NOC_NUM_ENDPOINTS];  // Replicated for each input
    logic [$clog2(NUM_OUTPUTS) - 1 : 0]         route_table_out     [NUM_INPUTS];
    logic [$clog2(NOC_NUM_ENDPOINTS) - 1 : 0]   route_table_select  [NUM_INPUTS];

    // Router state
    logic receiving_packet[NUM_INPUTS], transiting_packet[NUM_INPUTS];

    // Dest buffer FIFO signals
    logic [DEST_WIDTH - 1 : 0]  dest_buffer_out     [NUM_INPUTS];
    logic                       dest_buffer_empty   [NUM_INPUTS];
    logic                       dest_buffer_rdreq   [NUM_INPUTS];

    // Flit buffer FIFO signals
    logic [FLIT_WIDTH - 1 : 0]  flit_buffer_out             [NUM_INPUTS];
    logic                       flit_buffer_is_tail_out     [NUM_INPUTS];
    logic                       flit_buffer_empty           [NUM_INPUTS];
    logic                       flit_buffer_rdreq           [NUM_INPUTS];
    logic                       flit_buffer_valid           [NUM_INPUTS];

    // Arbiter signals
    logic [NUM_INPUTS - 1 : 0] request     [NUM_OUTPUTS];
    logic [NUM_INPUTS - 1 : 0] hold        [NUM_OUTPUTS];
    logic [NUM_INPUTS - 1 : 0] grant       [NUM_OUTPUTS];
    logic [NUM_INPUTS - 1 : 0] grant_mask  [NUM_OUTPUTS];

    // Input pipeline signals
    logic [FLIT_WIDTH + DEST_WIDTH + 1 - 1: 0]  flit_reg0[NUM_INPUTS];
    logic                                       flit_reg0_valid[NUM_INPUTS];
    logic                                       pipeline_enable[NUM_INPUTS];

    // Crossbar signals
    logic [FLIT_WIDTH + DEST_WIDTH + 1 - 1: 0]  data_out_packed[NUM_OUTPUTS];
    logic                                       flit_out_valid[NUM_OUTPUTS];

    // Output pipeline signals
    logic [FLIT_WIDTH + DEST_WIDTH + 1 - 1: 0]  data_out_reg[NUM_OUTPUTS];
    logic                                       data_out_reg_valid[NUM_OUTPUTS];

    // Output credit counter
    logic [$clog2(FLIT_BUFFER_DEPTH) : 0]       credit_counter  [NUM_OUTPUTS];

    /**************************************************************************/
    /********************************** Intial ********************************/
    /**************************************************************************/

    // Read the routing table into the ROM
    initial begin
        // Make explicit one routing table for all inputs
        // Use generate statements to create multiple inital blocks/
        // for Quartus to do the right thing (otherwise it only runs the
        // first iteration of the for loop inside the initial statement
        // and all other routing tables are empty...)
        $readmemh(ROUTING_TABLE_HEX, route_table);
    end

    /**************************************************************************/
    /********************************** Logic *********************************/
    /**************************************************************************/

    // Input generate
    generate begin: input_assign_gen
        genvar i;
        for (i = 0; i < NUM_INPUTS; i++) begin: for_inputs
            // Pipeline enable
            assign pipeline_enable[i] = grant[route_table_out[i]][i] & (send_out[route_table_out[i]] | (~data_out_reg_valid[route_table_out[i]] & (PIPELINE_OUTPUT == 1)));

            // Read flit buffer when the pipeline is free
            assign flit_buffer_rdreq[i] = ~flit_buffer_empty[i] & (~flit_reg0_valid[i] | pipeline_enable[i]);

            // Generate credits based on flit buffer reads
            assign credit_out[i] = flit_buffer_rdreq[i];

            // Read dest buffer when a new packet begins
            assign dest_buffer_rdreq[i] = flit_buffer_rdreq[i] & ~(transiting_packet[i] & ~flit_buffer_is_tail_out[i]);

            // Index into the routing table using the destination
            assign route_table_select[i] = dest_buffer_out[i][$clog2(NOC_NUM_ENDPOINTS) - 1 : 0];

            // Unpack the crossbar output
            assign {data_out[i], dest_out[i], is_tail_out[i]} = (PIPELINE_OUTPUT == 0) ? data_out_packed[i] : data_out_reg[i];
        end
    end
    endgenerate

    // Credit counter
    always @(posedge clk) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            if (rst_n == 1'b0) begin
                credit_counter[i] <= FLIT_BUFFER_DEPTH;
            end else begin
                credit_counter[i] <= credit_counter[i] + credit_in[i] - send_out[i];
            end
        end
    end

    // Registered logic to read from the routing table
    always @(posedge clk) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            route_table_out[i] <= route_table[route_table_select[i]];
        end
    end

    // First stage flit pipeline (parallel to routing table lookup)
    always @(posedge clk) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (~flit_reg0_valid[i] | pipeline_enable[i])
                flit_reg0[i] <= {flit_buffer_out[i], dest_buffer_out[i], flit_buffer_is_tail_out[i]};
        end
    end

    // Covert routing table output to one-hot
    always @(*) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            request[i] = '0;
        end
        for (int i = 0; i < NUM_INPUTS; i++) begin
            request[route_table_out[i]][i] = flit_reg0_valid[i];
            if (DISABLE_SELFLOOP == 1) begin
                request[i][i] = 1'b0;
            end
        end
    end

    /* Note: This also doesn't change the resource utilization
     * which probably means the logic optimization is being
     * propogated correctly but having an uninteded effect.
     * It's retained for redundancy purposes
     */
    // Grant mask is used to disable selfloop at a second point
    // Just masking the request increased resource utilization
    always @(*) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            grant_mask[i] = grant[i];
        end
        if (DISABLE_SELFLOOP == 1) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                grant_mask[i][i] = 1'b0;
            end
        end
    end

    // Update state of packet receive and transit
    always @(posedge clk) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (rst_n == 1'b0) begin
                receiving_packet[i] <= 1'b0;
                transiting_packet[i] <= 1'b0;
            end else begin
                receiving_packet[i] <= send_in[i] ? ~is_tail_in[i] : receiving_packet[i];
                if (flit_buffer_valid[i])
                    transiting_packet[i] <= ~flit_buffer_is_tail_out[i];
                if (flit_buffer_rdreq[i])
                    transiting_packet[i] <= 1'b1;
            end
        end
    end

    // Hold is active when the data is valid until the tail flit
    always @(*) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            hold[i] = '0;
            for (int j = 0; j < NUM_INPUTS; j++) begin
                hold[i][j] = ~(flit_reg0[j][0] & send_out[i]);
            end
        end
    end

    // Flit buffer data and pipeline data valid signal
    always @(posedge clk) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (rst_n == 1'b0) begin
                flit_buffer_valid[i] <= '0;
                flit_reg0_valid[i] <= '0;
            end else begin
                if (pipeline_enable[i])
                    flit_reg0_valid[i] <= 1'b0;

                if (pipeline_enable[i] | ~flit_reg0_valid[i])
                    flit_buffer_valid[i] <= 1'b0;

                if (flit_buffer_rdreq[i])
                    flit_buffer_valid[i] <= 1'b1;

                if (flit_buffer_valid[i])
                    flit_reg0_valid[i] <= 1'b1;
            end
        end
    end

    // Output data pipeline
    always @(posedge clk) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            if (~data_out_reg_valid[i] | send_out[i])
                data_out_reg[i] <= data_out_packed[i];
        end
    end

    // Data out pipeline valid signal
    always @(posedge clk) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            if (rst_n == 1'b0) begin
                data_out_reg_valid[i] <= '0;
            end else begin
                if (send_out[i])
                    data_out_reg_valid[i] <= 1'b0;

                if (flit_out_valid[i])
                    data_out_reg_valid[i] <= 1'b1;
            end
        end
    end

    // send_out signal
    always @(*) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            if (PIPELINE_OUTPUT == 1)
                send_out[i] = data_out_reg_valid[i] & (credit_counter[i] > 1'b0);
            else
                send_out[i] = flit_out_valid[i] & (credit_counter[i] > 1'b0);
        end
    end

    /**************************************************************************/
    /***************************** Instantiations *****************************/
    /**************************************************************************/

    // Flit buffer FIFOs
    generate begin: flit_buffer_gen
        genvar i;
        for (i = 0; i < NUM_INPUTS; i++) begin: for_inputs
            fifo_agilex7 #(
                .WIDTH      (FLIT_WIDTH + 1),
                .DEPTH      (FLIT_BUFFER_DEPTH),
                .FORCE_MLAB (FORCE_MLAB))
            flit_buffer (
                .clock  (clk),
                .data   ({data_in[i], is_tail_in[i]}),
                .rdreq  (flit_buffer_rdreq[i]),
                .sclr   (~rst_n),
                .wrreq  (send_in[i]),
                .empty  (flit_buffer_empty[i]),
                .full   (),                             // Handled with credits
                .q      ({flit_buffer_out[i], flit_buffer_is_tail_out[i]})
            );
        end
    end
    endgenerate

    // Destination FIFO
    generate begin: dest_buffer_gen
        genvar i;
        for (i = 0; i < NUM_INPUTS; i++) begin: for_inputs
            fifo_agilex7 #(
                .WIDTH      (DEST_WIDTH),
                .DEPTH      (FLIT_BUFFER_DEPTH),
                .FORCE_MLAB (FORCE_MLAB))
            dest_buffer (
                .clock  (clk),
                .data   (dest_in[i]),
                .rdreq  (dest_buffer_rdreq[i]),
                .sclr   (~rst_n),
                .wrreq  (send_in[i] & ~receiving_packet[i]),
                .empty  (dest_buffer_empty[i]),
                .full   (),                             // Handled with credits
                .q      (dest_buffer_out[i])
            );
        end
    end
    endgenerate

    // Output Arbiters
    generate begin: arbiter_gen
        genvar i;
        for (i = 0; i < NUM_OUTPUTS; i++) begin: for_outputs
            arbiter_matrix #(
                .NUM_INPUTS(NUM_INPUTS)
            ) arbiter_inst (
                .clk        (clk),
                .rst_n      (rst_n),

                .request    (request[i]),
                .hold       (hold[i]),
                .grant      (grant[i])
            );
        end
    end
    endgenerate

    // Crossbar
    crossbar_onehot #(
        .DATA_WIDTH         (FLIT_WIDTH + DEST_WIDTH + 1),
        .NUM_INPUTS         (NUM_INPUTS),
        .NUM_OUTPUTS        (NUM_OUTPUTS),
        .DISABLE_SELFLOOP   (DISABLE_SELFLOOP))
    crossbar_inst (
        .data_in     (flit_reg0),
        .valid_in    (flit_reg0_valid),

        .data_out    (data_out_packed),
        .valid_out   (flit_out_valid),

        .select      (grant_mask)
    );

endmodule: router

module arbiter_matrix #(
    parameter NUM_INPUTS = 4
) (
    input   wire                            clk,
    input   wire                            rst_n,

    input   wire    [NUM_INPUTS - 1 : 0]    request,
    input   wire    [NUM_INPUTS - 1 : 0]    hold,
    output  logic   [NUM_INPUTS - 1 : 0]    grant
);
    logic matrix [NUM_INPUTS][NUM_INPUTS];

    logic enable;
    logic deactivate [NUM_INPUTS];

    // Generate grant logic combinationally
    always @(*) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            grant[i] = request[i] & ~deactivate[i];
        end
    end

    // Update grant logic when hold for the granted signal is low
    always @(*) begin
        enable = 1'b1;
        for (int i = 0; i < NUM_INPUTS; i++) begin
            enable = enable & ~(grant[i] & hold[i]);
        end
    end

    // Generate deactivate signals
    always @(*) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            deactivate[i] = 1'b0;
            for (int j = 0; j < NUM_INPUTS; j++) begin
                deactivate[i] = deactivate[i] | (matrix[j][i] & request[j]);
            end
        end
    end

    // Matrix update logic
    always @(posedge clk) begin
        if (rst_n == 1'b0) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                for (int j = i + 1; j < NUM_INPUTS; j++) begin
                    matrix[i][j] <= 1'b1;
                    matrix[j][i] <= 1'b0;
                end
            end
            for (int i = 0; i < NUM_INPUTS; i++) begin
                matrix[i][i] <= 1'b0;
            end
        end else begin
            if (enable) begin
                for (int i = 1; i < NUM_INPUTS; i++) begin
                    for (int j = 0; j < i; j++) begin
                        matrix[i][j] <= (matrix[i][j] & ~grant[i]) | grant[j];
                        matrix[j][i] <= (matrix[j][i] & ~grant[j]) | grant[i];
                    end
                end
            end
        end
    end

endmodule: arbiter_matrix

module crossbar_onehot #(
    parameter DATA_WIDTH = 32,
    parameter NUM_INPUTS = 2,
    parameter NUM_OUTPUTS = 2,
    parameter DISABLE_SELFLOOP = 0
) (
    input   wire    [DATA_WIDTH - 1 : 0]    data_in     [NUM_INPUTS],
    input   wire                            valid_in    [NUM_INPUTS],

    output  logic   [DATA_WIDTH - 1 : 0]    data_out    [NUM_OUTPUTS],
    output  logic                           valid_out   [NUM_OUTPUTS],

    input   wire    [NUM_INPUTS - 1 : 0]    select      [NUM_OUTPUTS]
);

    always @(*) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            data_out[i] = '0;
            valid_out[i] = '0;
            for (int j = 0; j < NUM_INPUTS; j++) begin
                if (((DISABLE_SELFLOOP == 0) || (i != j)) && select[i][j]) begin
                    data_out[i] |= data_in[j];
                    valid_out[i] |= valid_in[j];
                end
            end
        end
    end

endmodule: crossbar_onehot