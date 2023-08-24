module axis_serializer_shim_in #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 4,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter EXTRA_SYNC_STAGES = 0
) (
    input   wire    clk_usr,
    input   wire    clk_noc,

    input   wire    rst_n_usr_sync,
    input   wire    rst_n_noc_sync,

    input   wire                                                    axis_tvalid,
    output  logic                                                   axis_tready,
    input   wire    [TDATA_WIDTH - 1 : 0]                           axis_tdata,
    input   wire                                                    axis_tlast,
    input   wire    [TDEST_WIDTH - 1 : 0]                           axis_tdest,

    output  logic   [TDATA_WIDTH / SERIALIZATION_FACTOR - 1 : 0]    data_out,
    output  logic   [TDEST_WIDTH - 1 : 0]                           dest_out,
    output  logic                                                   is_tail_out,
    output  logic                                                   send_out,
    input   wire                                                    credit_in
);

    localparam FLIT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR;

    // Declarations
    logic [TDEST_WIDTH + 1 - 1 : 0] dest_buffer_out;
    logic data_buffer_wrfull, data_buffer_rdempty, data_buffer_rdreq;
    logic [$clog2(FLIT_BUFFER_DEPTH) : 0] credit_count;
    logic [$clog2(SERIALIZATION_FACTOR) - 1 : 0] ser_count;

    // axis_tready is high when the buffers are not full
    assign axis_tready = ~data_buffer_wrfull;

    // Generate rdreq based on credit count if the data buffer is not empty
    assign data_buffer_rdreq = (credit_count > 0) & ~data_buffer_rdempty;

    // Send is one cycle delayed version of rdreq
    always @(posedge clk_noc) begin
        send_out <= data_buffer_rdreq;
    end

    // Credit counter
    always @(posedge clk_noc) begin
        if (rst_n_noc_sync == 1'b0) begin
            credit_count <= FLIT_BUFFER_DEPTH;
        end else begin
            credit_count <= credit_count + credit_in - data_buffer_rdreq;
        end
    end

    // Serialization counter counts down to end of input word
    always @(posedge clk_noc) begin
        if (rst_n_noc_sync == 1'b0) begin
            ser_count <= SERIALIZATION_FACTOR - 1;
        end else begin
            ser_count <= ser_count - data_buffer_rdreq;
            if ((ser_count == '0) && data_buffer_rdreq) begin
                ser_count <= SERIALIZATION_FACTOR - 1;
            end
        end
    end

    // Read dest buffer when it's the first flit in an input word
    assign dest_buffer_rdreq = (ser_count == (SERIALIZATION_FACTOR - 1)) & data_buffer_rdreq;

    // Unpack destination buffer output data into destination
    assign dest_out = dest_buffer_out[TDEST_WIDTH : 1];

    // Flit is tail flit when it's the last subword of the tail input word
    assign is_tail_out = dest_buffer_out[0] & (ser_count == (SERIALIZATION_FACTOR - 1));

    // Instantiations
    // Destination + Tail buffer
    dcfifo_mixed_width_agilex7 #(
        .WIDTH_IN           (TDEST_WIDTH + 1),
        .WIDTH_OUT          (TDEST_WIDTH + 1),
        .DEPTH              (BUFFER_DEPTH),
        .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
        .SHOWAHEAD          ("OFF")
    ) dest_buffer (
        .aclr   (~rst_n_noc_sync | ~rst_n_usr_sync),
        .data   ({axis_tdest, axis_tlast}),
        .rdclk  (clk_noc),
        .rdreq  (dest_buffer_rdreq),
        .wrclk  (clk_usr),
        .wrreq  (axis_tvalid & axis_tready),
        .q      (dest_buffer_out),
        .rdempty(dest_buffer_rdempty),
        .wrfull ()
    );

    // Data buffer
    dcfifo_mixed_width_agilex7 #(
        .WIDTH_IN           (TDATA_WIDTH),
        .WIDTH_OUT          (FLIT_WIDTH),
        .DEPTH              (BUFFER_DEPTH),
        .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
        .SHOWAHEAD          ("OFF")
    ) data_buffer (
        .aclr   (~rst_n_noc_sync | ~rst_n_usr_sync),
        .data   (axis_tdata),
        .rdclk  (clk_noc),
        .rdreq  (data_buffer_rdreq),
        .wrclk  (clk_usr),
        .wrreq  (axis_tvalid & axis_tready),
        .q      (data_out),
        .rdempty(data_buffer_rdempty),
        .wrfull (data_buffer_wrfull)
    );

endmodule: axis_serializer_shim_in

module axis_deserializer_shim_out #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 4,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter EXTRA_SYNC_STAGES = 0
) (
    input   wire    clk_usr,
    input   wire    clk_noc,

    input   wire    rst_n_usr_sync,
    input   wire    rst_n_noc_sync,

    output  logic                                                   axis_tvalid,
    input   wire                                                    axis_tready,
    output  logic   [TDATA_WIDTH - 1 : 0]                           axis_tdata,
    output  logic                                                   axis_tlast,
    output  logic   [TDEST_WIDTH - 1 : 0]                           axis_tdest,

    input   wire    [TDATA_WIDTH / SERIALIZATION_FACTOR - 1 : 0]    data_in,
    input   wire    [TDEST_WIDTH - 1 : 0]                           dest_in,
    input   wire                                                    is_tail_in,
    input   wire                                                    send_in,
    output  logic                                                   credit_out
);
    localparam FLIT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR;

    // Declarations
    logic [TDEST_WIDTH + 1 - 1 : 0] dest_buffer_out;
    logic dest_buffer_rdempty, dest_buffer_wrreq, data_buffer_rdempty;
    logic [$clog2(BUFFER_DEPTH * SERIALIZATION_FACTOR) + 1 - 1 : 0] data_buffer_wrusedw;
    logic [$clog2(FLIT_BUFFER_DEPTH) : 0] credit_count, credit_count_reg;
    logic [$clog2(SERIALIZATION_FACTOR) - 1 : 0] ser_count;

    // Credit counter
    always @(posedge clk_noc) begin
        if (rst_n_noc_sync == 1'b0) begin
            credit_count <= FLIT_BUFFER_DEPTH;
        end else begin
            credit_count <= credit_count + credit_out - send_in;
        end
    end

    // Delay used credits since wrused has a two cycle latency
    always @(posedge clk_noc) begin
        credit_count_reg <= credit_count;
    end

    // Credits are sent when there is space in the data buffer to hold more
    // This allows the buffer to larger than the number of credits
    // But wastes one entry in the FIFO
    assign credit_out = ((credit_count < FLIT_BUFFER_DEPTH) || send_in) &&
        ((BUFFER_DEPTH * SERIALIZATION_FACTOR) - 1 > data_buffer_wrusedw) &&
        (credit_count_reg < ((BUFFER_DEPTH * SERIALIZATION_FACTOR) - data_buffer_wrusedw - 1'b1));

    // Serialization counter
    always @(posedge clk_noc) begin
        if (rst_n_noc_sync == 1'b0) begin
            ser_count <= SERIALIZATION_FACTOR - 1;
        end else begin
            ser_count <= ser_count - send_in;
            if ((ser_count == '0) && send_in) begin
                ser_count <= SERIALIZATION_FACTOR - 1;
            end
        end
    end

    // Destination buffer is written to at the end of an output word
    assign dest_buffer_wrreq = (ser_count == '0) & send_in;

    // Data is valid when the buffer is not empty
    assign axis_tvalid = ~data_buffer_rdempty;

    // Unpack destination buffer output data into destination
    assign {axis_tdest, axis_tlast} = dest_buffer_out;

    // Instantiations
    // Destination + Tail buffer
    dcfifo_mixed_width_agilex7 #(
        .WIDTH_IN           (TDEST_WIDTH + 1),
        .WIDTH_OUT          (TDEST_WIDTH + 1),
        .DEPTH              (BUFFER_DEPTH),
        .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
        .SHOWAHEAD          ("ON")
    ) dest_buffer (
        .aclr   (~rst_n_usr_sync | ~rst_n_noc_sync),
        .data   ({dest_in, is_tail_in}),
        .rdclk  (clk_usr),
        .rdreq  (axis_tvalid & axis_tready),
        .wrclk  (clk_noc),
        .wrreq  (dest_buffer_wrreq),
        .q      (dest_buffer_out),
        .rdempty(dest_buffer_rdempty),
        .wrfull ()
    );

    // Data buffer
    dcfifo_mixed_width_agilex7 #(
        .WIDTH_IN           (FLIT_WIDTH),
        .WIDTH_OUT          (TDATA_WIDTH),
        .DEPTH              (BUFFER_DEPTH * SERIALIZATION_FACTOR),
        .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
        .SHOWAHEAD          ("ON")
    ) data_buffer (
        .aclr   (~rst_n_usr_sync | ~rst_n_noc_sync),
        .data   (data_in),
        .rdclk  (clk_usr),
        .rdreq  (axis_tvalid & axis_tready),
        .wrclk  (clk_noc),
        .wrreq  (send_in),
        .q      (axis_tdata),
        .rdempty(data_buffer_rdempty),
        .wrfull (),
        .wrusedw(data_buffer_wrusedw)
    );

endmodule: axis_deserializer_shim_out