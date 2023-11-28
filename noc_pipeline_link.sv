/**
 * @file noc_pipeline_link.sv
 *
 * @brief Pipeline registers for links
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

// Pipeline links module which does not use reset signal
// to allow them to be mapped to the hyper registers

module noc_pipeline_link #(
    parameter NUM_PIPELINE = 0,

    parameter FLIT_WIDTH = 128,
    parameter DEST_WIDTH = 8
) (
    input   wire                            clk         ,

    input   wire    [FLIT_WIDTH - 1 : 0]    data_in     ,
    input   wire    [DEST_WIDTH - 1 : 0]    dest_in     ,
    input   wire                            is_tail_in  ,
    input   wire                            send_in     ,
    output  logic                           credit_out  ,

    output  logic   [FLIT_WIDTH - 1 : 0]    data_out    ,
    output  logic   [DEST_WIDTH - 1 : 0]    dest_out    ,
    output  logic                           is_tail_out ,
    output  logic                           send_out    ,
    input   wire                            credit_in
);

    generate begin: pipeline_gen
        if (NUM_PIPELINE == 0) begin
            assign data_out    = data_in;
            assign dest_out    = dest_in;
            assign is_tail_out = is_tail_in;
            assign send_out    = send_in;
            assign credit_out  = credit_in;
        end else begin
            logic   [FLIT_WIDTH - 1 : 0]    data    [NUM_PIPELINE];
            logic   [DEST_WIDTH - 1 : 0]    dest    [NUM_PIPELINE];
            logic                           is_tail [NUM_PIPELINE];
            logic                           send    [NUM_PIPELINE];
            logic                           credit  [NUM_PIPELINE];

            always_ff @(posedge clk) begin
                data[0]     <= data_in;
                dest[0]     <= dest_in;
                is_tail[0]  <= is_tail_in;
                send[0]     <= send_in;
                credit[0]   <= credit_in;

                for (int i = 1; i < NUM_PIPELINE; i = i + 1) begin
                    data[i]    <= data[i - 1];
                    dest[i]    <= dest[i - 1];
                    is_tail[i] <= is_tail[i - 1];
                    send[i]    <= send[i - 1];
                    credit[i]  <= credit[i - 1];
                end
            end

            always_comb begin
                data_out    = data[NUM_PIPELINE - 1];
                dest_out    = dest[NUM_PIPELINE - 1];
                is_tail_out = is_tail[NUM_PIPELINE - 1];
                send_out    = send[NUM_PIPELINE - 1];
                credit_out  = credit[NUM_PIPELINE - 1];
            end
        end
    end
    endgenerate

endmodule: noc_pipeline_link