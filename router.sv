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
    logic [NUM_INPUTS - 1 : 0] grant_input;

    // Input pipeline signals (Unpacked for easier debugging)
    logic [FLIT_WIDTH + DEST_WIDTH + 1 - 1: 0]  flit_reg0[NUM_INPUTS];
    logic [FLIT_WIDTH - 1: 0]                   flit_reg0_flit[NUM_INPUTS];
    logic [DEST_WIDTH - 1: 0]                   flit_reg0_dest[NUM_INPUTS];
    logic                                       flit_reg0_is_tail[NUM_INPUTS];
    logic                                       flit_reg0_valid[NUM_INPUTS];
    logic                                       pipeline_enable[NUM_INPUTS];

    // Crossbar signals (Unpacked for easier debugging)
    logic [FLIT_WIDTH + DEST_WIDTH + 1 - 1: 0]  data_out_packed[NUM_OUTPUTS];
    logic [FLIT_WIDTH - 1: 0]                   data_out_flit[NUM_OUTPUTS];
    logic [DEST_WIDTH - 1: 0]                   data_out_dest[NUM_OUTPUTS];
    logic                                       data_out_is_tail[NUM_OUTPUTS];
    logic                                       flit_out_valid[NUM_OUTPUTS];

    // Output pipeline signals (Unpacked for easier debugging)
    logic [FLIT_WIDTH + DEST_WIDTH + 1 - 1: 0]  data_out_reg[NUM_OUTPUTS];
    logic [FLIT_WIDTH - 1: 0]                   data_out_reg_flit[NUM_OUTPUTS];
    logic [DEST_WIDTH - 1: 0]                   data_out_reg_dest[NUM_OUTPUTS];
    logic                                       data_out_reg_is_tail[NUM_OUTPUTS];
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
            assign pipeline_enable[i] = grant_input[i] & (send_out[route_table_out[i]] | (~data_out_reg_valid[route_table_out[i]] & (PIPELINE_OUTPUT == 1)));

            // Read flit buffer when the pipeline is free
            assign flit_buffer_rdreq[i] = ~flit_buffer_empty[i] & (~flit_reg0_valid[i] | pipeline_enable[i]);

            // Generate credits based on flit buffer reads
            assign credit_out[i] = flit_buffer_rdreq[i];

            // Read dest buffer when a new packet begins
            assign dest_buffer_rdreq[i] = flit_buffer_rdreq[i] & ~(transiting_packet[i] & ~flit_buffer_is_tail_out[i]);

            // Index into the routing table using the destination
            assign route_table_select[i] = dest_buffer_out[i][$clog2(NOC_NUM_ENDPOINTS) - 1 : 0];

            // Unpack the crossbar output
            assign {data_out[i], dest_out[i], is_tail_out[i]} = (PIPELINE_OUTPUT == 0) ?
                {data_out_flit[i], data_out_dest[i], data_out_is_tail[i]} :
                {data_out_reg_flit[i], data_out_reg_dest[i], data_out_reg_is_tail[i]};
        end
    end
    endgenerate

    // grant_input is a combined signal which indicates whether the input
    // has been granted any request. Since an input only requests one output
    // at any cycle, this signal can used to generate the pipeline enable
    always_comb begin
        grant_input = '0;
        for (int i = 0; i < NUM_INPUTS; i++) begin
            for (int j = 0; j < NUM_OUTPUTS; j++) begin
                grant_input[i] = grant_input[i] | grant[j][i];
            end
        end
    end

    // Credit counter
    always_ff @(posedge clk) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            if (rst_n == 1'b0) begin
                credit_counter[i] <= FLIT_BUFFER_DEPTH;
            end else begin
                credit_counter[i] <= credit_counter[i] + credit_in[i] - send_out[i];
            end
        end
    end

    // Registered logic to read from the routing table
    always_ff @(posedge clk) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (~flit_reg0_valid[i] | pipeline_enable[i])
                route_table_out[i] <= route_table[route_table_select[i]];
        end
    end

    // First stage flit pipeline (parallel to routing table lookup)
    always_ff @(posedge clk) begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (~flit_reg0_valid[i] | pipeline_enable[i]) begin
                flit_reg0_flit[i] <= flit_buffer_out[i];
                flit_reg0_dest[i] <= dest_buffer_out[i];
                flit_reg0_is_tail[i] <= flit_buffer_is_tail_out[i];
            end
        end
    end

    // Covert routing table output to one-hot
    always_comb begin
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
    always_comb begin
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
    always_ff @(posedge clk) begin
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
    always_comb begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            hold[i] = '0;
            for (int j = 0; j < NUM_INPUTS; j++) begin
                // If pipeline output is enabled then the data moves forward if
                // the piepline moves forward, which happens when the output
                // is active or the output pipeline register is empty
                hold[i][j] = ~(flit_reg0_is_tail[j] && (send_out[i]
                    || (~data_out_reg_valid[i] && (PIPELINE_OUTPUT == 1))));
            end
        end
    end

    // Flit buffer data and pipeline data valid signal
    always_ff @(posedge clk) begin
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
    always_ff @(posedge clk) begin
        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            if (~data_out_reg_valid[i] | send_out[i]) begin
                data_out_reg_flit[i] <= data_out_flit[i];
                data_out_reg_dest[i] <= data_out_dest[i];
                data_out_reg_is_tail[i] <= data_out_is_tail[i];
            end
        end
    end

    // Data out pipeline valid signal
    always_ff @(posedge clk) begin
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
    always_comb begin
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
    always_comb begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            flit_reg0[i] = {flit_reg0_flit[i], flit_reg0_dest[i], flit_reg0_is_tail[i]};
        end

        for (int i = 0; i < NUM_OUTPUTS; i++) begin
            {data_out_flit[i], data_out_dest[i], data_out_is_tail[i]} = data_out_packed[i];
        end
    end

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

    // Hold input is expected to high from when the request is made
    // till before the last cycle of the required grant but to keep
    // the grants stable during a hold, we need to latch the grants
    // after the first cycle of the hold and keep them stable till
    // after the last cycle of the hold while the new grant is generated
    // This is done by using a delay on the hold signal which is used to
    // combinationally affect the grant and hold circuit
    logic [NUM_INPUTS - 1 : 0] hold_delay;
    logic anyhold;
    logic [NUM_INPUTS - 1 : 0] grant_int, grant_prev;

    logic deactivate [NUM_INPUTS];

    // Generate instantaneous grant logic combinationally
    always_comb begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            grant_int[i] = request[i] & ~deactivate[i];
        end
    end

    // Latch grant and hold logic
    always_ff @(posedge clk) begin
        // This should not depend on request since request is only dependent on
        // data being valid but hold must act to hold the request for when it is
        // low. Hold is later gated by whether grant is high or not which
        // accounts for the case when the request is low to start and the
        // request has not been granted yet so as to not hold a no-grant
        hold_delay <= hold;
        if (rst_n == 1'b0) begin
            grant_prev <= '0;
        end else begin
            grant_prev <= grant;
        end
    end

    // Generate anyhold signal
    always_comb begin
        anyhold = 1'b0;
        for (int i = 0; i < NUM_INPUTS; i++) begin
            anyhold = anyhold | (hold_delay[i] & grant_prev[i]);
        end
    end

    // Generate grant logic
    always_comb begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            grant[i] = (hold_delay[i] & grant_prev[i]) ? grant_prev[i] : (grant_int[i] & ~anyhold);
        end
    end

    // Generate deactivate signals
    always_comb begin
        for (int i = 0; i < NUM_INPUTS; i++) begin
            deactivate[i] = 1'b0;
            for (int j = 0; j < NUM_INPUTS; j++) begin
                deactivate[i] = deactivate[i] | (matrix[j][i] & request[j]);
            end
        end
    end

    // Matrix update logic
    always_ff @(posedge clk) begin
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
            // Matrix can always be updated because grants are held with holds
            for (int i = 1; i < NUM_INPUTS; i++) begin
                for (int j = 0; j < i; j++) begin
                    matrix[i][j] <= (matrix[i][j] & ~grant[i]) | grant[j];
                    matrix[j][i] <= (matrix[j][i] & ~grant[j]) | grant[i];
                end
            end
        end
    end

endmodule: arbiter_matrix

module onehot_to_binary #(
    parameter WIDTH = 4
) (
    input   wire    [WIDTH - 1 : 0]         onehot,
    output  logic   [$clog2(WIDTH) - 1 : 0] binary
);
    always_comb begin
        binary = '0;
        for (int i = 0; i < WIDTH; i++) begin
            binary |= onehot[i] ? i : '0;
        end
    end
endmodule: onehot_to_binary

module crossbar_onehot #(
    parameter DATA_WIDTH = 32,
    parameter NUM_INPUTS = 2,
    parameter NUM_OUTPUTS = 2,
    parameter DISABLE_SELFLOOP = 0,
    parameter MODE = "ONEHOT"       // BINARY, ONEHOT, EXPLICIT (supports upto 5x5)
) (
    input   wire    [DATA_WIDTH - 1 : 0]    data_in     [NUM_INPUTS],
    input   wire                            valid_in    [NUM_INPUTS],

    output  logic   [DATA_WIDTH - 1 : 0]    data_out    [NUM_OUTPUTS],
    output  logic                           valid_out   [NUM_OUTPUTS],

    input   wire    [NUM_INPUTS - 1 : 0]    select      [NUM_OUTPUTS]
);

    generate begin: crossbar
        if (MODE == "BINARY") begin
            logic [$clog2(NUM_INPUTS) - 1 : 0] select_binary [NUM_OUTPUTS];
            genvar i;
            for (i = 0; i < NUM_OUTPUTS; i++) begin: for_outputs
                onehot_to_binary #(
                    .WIDTH (NUM_INPUTS)
                ) onehot_to_binary_inst (
                    .onehot (select[i]),
                    .binary (select_binary[i])
                );

                assign data_out[i] = ((select[i] == '0) || ((DISABLE_SELFLOOP == 1) && (select_binary[i] == i))) ? 'x : data_in[select_binary[i]];
                assign valid_out[i] = (select[i] == '0) ? 1'b0 : valid_in[select_binary[i]];
            end
        end else if (MODE == "ONEHOT") begin
            always_comb begin
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
        end else if (MODE == "EXPLICIT") begin
            logic [4 : 0] select_expanded [NUM_OUTPUTS];

            logic [DATA_WIDTH - 1 : 0] data_in_expanded[5];
            logic valid_in_expanded[5];

            genvar i;
            for (i = 0; i < NUM_INPUTS; i++) begin: for_inputs
                assign data_in_expanded[i] = data_in[i];
                assign valid_in_expanded[i] = valid_in[i];
            end

            for (i = 0; i < NUM_OUTPUTS; i++) begin: for_outputs
                assign select_expanded[i] = {'0, select[i]};

                always_comb begin
                    data_out[i] = 'x;
                    valid_out[i] = 'x;
                    case (select_expanded[i])
                        5'b00000: begin
                            data_out[i] = 'x;
                            valid_out[i] = '0;
                        end
                        5'b00001: begin
                            if ((i != 0) || (DISABLE_SELFLOOP == 0)) begin
                                data_out[i] = data_in_expanded[0];
                                valid_out[i] = valid_in_expanded[0];
                            end
                        end
                        5'b00010: begin
                            if ((i != 1) || (DISABLE_SELFLOOP == 0)) begin
                                data_out[i] = data_in_expanded[1];
                                valid_out[i] = valid_in_expanded[1];
                            end
                        end
                        5'b00100: begin
                            if ((i != 2) || (DISABLE_SELFLOOP == 0)) begin
                                data_out[i] = data_in_expanded[2];
                                valid_out[i] = valid_in_expanded[2];
                            end
                        end
                        5'b01000: begin
                            if ((i != 3) || (DISABLE_SELFLOOP == 0)) begin
                                data_out[i] = data_in_expanded[3];
                                valid_out[i] = valid_in_expanded[3];
                            end
                        end
                        5'b10000: begin
                            if ((i != 4) || (DISABLE_SELFLOOP == 0)) begin
                                data_out[i] = data_in_expanded[4];
                                valid_out[i] = valid_in_expanded[4];
                            end
                        end
                        default: begin
                            data_out[i] = 'x;
                            valid_out[i] = 1'bx;
                        end
                    endcase
                end
            end
        end
    end
    endgenerate

endmodule: crossbar_onehot