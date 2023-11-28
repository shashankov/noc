/**
 * @file axis_serdes_shim.sv
 *
 * @brief AXI-Stream and serdes shims for the NoC
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

module axis_serializer_shim_in #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 1,
    parameter CLKCROSS_FACTOR = 1,
    parameter SINGLE_CLOCK = 0,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter EXTRA_SYNC_STAGES = 0,
    parameter FORCE_MLAB = 0
) (
    input   wire    clk_usr,
    input   wire    clk_noc,

    input   wire    rst_n_usr_sync,
    input   wire    rst_n_noc_sync,

    input   wire                                            axis_tvalid,
    output  logic                                           axis_tready,
    input   wire    [TDATA_WIDTH - 1 : 0]                   axis_tdata,
    input   wire                                            axis_tlast,
    input   wire    [TDEST_WIDTH - 1 : 0]                   axis_tdest,

    output  logic   [TDATA_WIDTH / SERIALIZATION_FACTOR
                                 / CLKCROSS_FACTOR - 1 : 0] data_out,
    output  logic   [TDEST_WIDTH - 1 : 0]                   dest_out,
    output  logic                                           is_tail_out,
    output  logic                                           send_out,
    input   wire                                            credit_in
);
    localparam TDATA_INT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR;

    logic                           axis_int_tvalid;
    logic                           axis_int_tready;
    logic [TDATA_INT_WIDTH - 1 : 0] axis_int_tdata;
    logic                           axis_int_tlast;
    logic [TDEST_WIDTH - 1 : 0]     axis_int_tdest;

    generate begin: serializer_gen
        if (SERIALIZATION_FACTOR == 1) begin
            assign axis_int_tvalid = axis_tvalid;
            assign axis_tready = axis_int_tready;
            assign axis_int_tdata = axis_tdata;
            assign axis_int_tlast = axis_tlast;
            assign axis_int_tdest = axis_tdest;
        end else begin
            axis_serializer #(
                .TDEST_WIDTH            (TDEST_WIDTH),
                .TDATA_WIDTH            (TDATA_WIDTH),
                .SERIALIZATION_FACTOR   (SERIALIZATION_FACTOR))
            serializer_inst (
                .clk                (clk_usr),
                .rst_n              (rst_n_usr_sync),

                .axis_in_tvalid     (axis_tvalid),
                .axis_in_tready     (axis_tready),
                .axis_in_tdata      (axis_tdata),
                .axis_in_tlast      (axis_tlast),
                .axis_in_tdest      (axis_tdest),

                .axis_out_tvalid    (axis_int_tvalid),
                .axis_out_tready    (axis_int_tready),
                .axis_out_tdata     (axis_int_tdata),
                .axis_out_tlast     (axis_int_tlast),
                .axis_out_tdest     (axis_int_tdest)
            );
        end
    end
    endgenerate

    generate begin: clkcross_gen
        if (SINGLE_CLOCK == 1) begin
            axis_shim_in #(
                .TDEST_WIDTH        (TDEST_WIDTH),
                .TDATA_WIDTH        (TDATA_INT_WIDTH),
                .BUFFER_DEPTH       (BUFFER_DEPTH * SERIALIZATION_FACTOR),
                .FLIT_BUFFER_DEPTH  (FLIT_BUFFER_DEPTH),
                .FORCE_MLAB         (FORCE_MLAB))
            shim_inst (
                .clk            (clk_usr),
                .rst_n          (rst_n_usr_sync),

                .axis_tvalid    (axis_int_tvalid),
                .axis_tready    (axis_int_tready),
                .axis_tdata     (axis_int_tdata),
                .axis_tlast     (axis_int_tlast),
                .axis_tdest     (axis_int_tdest),

                .data_out       (data_out),
                .dest_out       (dest_out),
                .is_tail_out    (is_tail_out),
                .send_out       (send_out),
                .credit_in      (credit_in)
            );
        end else begin
            axis_clkcross_shim_in #(
                .TDEST_WIDTH            (TDEST_WIDTH),
                .TDATA_WIDTH            (TDATA_INT_WIDTH),
                .SERIALIZATION_FACTOR   (CLKCROSS_FACTOR),
                .BUFFER_DEPTH           (BUFFER_DEPTH * SERIALIZATION_FACTOR),
                .FLIT_BUFFER_DEPTH      (FLIT_BUFFER_DEPTH),
                .EXTRA_SYNC_STAGES      (EXTRA_SYNC_STAGES),
                .FORCE_MLAB             (FORCE_MLAB))
            shim_inst (
                .clk_usr        (clk_usr),
                .clk_noc        (clk_noc),

                .rst_n_usr_sync (rst_n_usr_sync),
                .rst_n_noc_sync (rst_n_noc_sync),

                .axis_tvalid    (axis_int_tvalid),
                .axis_tready    (axis_int_tready),
                .axis_tdata     (axis_int_tdata),
                .axis_tlast     (axis_int_tlast),
                .axis_tdest     (axis_int_tdest),

                .data_out       (data_out),
                .dest_out       (dest_out),
                .is_tail_out    (is_tail_out),
                .send_out       (send_out),
                .credit_in      (credit_in)
            );
        end
    end
    endgenerate

endmodule: axis_serializer_shim_in

module axis_deserializer_shim_out #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 1,
    parameter CLKCROSS_FACTOR = 1,
    parameter SINGLE_CLOCK = 0,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter EXTRA_SYNC_STAGES = 0,
    parameter FORCE_MLAB = 0
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

    input   wire    [TDATA_WIDTH / SERIALIZATION_FACTOR
                                 / CLKCROSS_FACTOR - 1 : 0]         data_in,
    input   wire    [TDEST_WIDTH - 1 : 0]                           dest_in,
    input   wire                                                    is_tail_in,
    input   wire                                                    send_in,
    output  logic                                                   credit_out
);
    localparam TDATA_INT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR;

    logic                           axis_int_tvalid;
    logic                           axis_int_tready;
    logic [TDATA_INT_WIDTH - 1 : 0] axis_int_tdata;
    logic                           axis_int_tlast;
    logic [TDEST_WIDTH - 1 : 0]     axis_int_tdest;

    generate begin: deserializer_gen
        if (SERIALIZATION_FACTOR == 1) begin
            assign axis_tvalid = axis_int_tvalid;
            assign axis_int_tready = axis_tready;
            assign axis_tdata = axis_int_tdata;
            assign axis_tlast = axis_int_tlast;
            assign axis_tdest = axis_int_tdest;
        end else begin
            axis_deserializer #(
                .TDEST_WIDTH            (TDEST_WIDTH),
                .TDATA_WIDTH            (TDATA_WIDTH),
                .SERIALIZATION_FACTOR   (SERIALIZATION_FACTOR))
            deserializer_inst (
                .clk                (clk_usr),
                .rst_n              (rst_n_usr_sync),

                .axis_in_tvalid     (axis_int_tvalid),
                .axis_in_tready     (axis_int_tready),
                .axis_in_tdata      (axis_int_tdata),
                .axis_in_tlast      (axis_int_tlast),
                .axis_in_tdest      (axis_int_tdest),

                .axis_out_tvalid    (axis_tvalid),
                .axis_out_tready    (axis_tready),
                .axis_out_tdata     (axis_tdata),
                .axis_out_tlast     (axis_tlast),
                .axis_out_tdest     (axis_tdest)
            );
        end
    end
    endgenerate

    generate begin: clkcross_gen
        if (SINGLE_CLOCK == 1) begin
            axis_shim_out #(
                .TDEST_WIDTH        (TDEST_WIDTH),
                .TDATA_WIDTH        (TDATA_INT_WIDTH),
                .BUFFER_DEPTH       (BUFFER_DEPTH * SERIALIZATION_FACTOR),
                .FLIT_BUFFER_DEPTH  (FLIT_BUFFER_DEPTH),
                .FORCE_MLAB         (FORCE_MLAB))
            shim_inst (
                .clk            (clk_usr),
                .rst_n          (rst_n_usr_sync),

                .axis_tvalid    (axis_int_tvalid),
                .axis_tready    (axis_int_tready),
                .axis_tdata     (axis_int_tdata),
                .axis_tlast     (axis_int_tlast),
                .axis_tdest     (axis_int_tdest),

                .data_in        (data_in),
                .dest_in        (dest_in),
                .is_tail_in     (is_tail_in),
                .send_in        (send_in),
                .credit_out     (credit_out)
            );
        end else begin
            axis_clkcross_shim_out #(
                .TDEST_WIDTH            (TDEST_WIDTH),
                .TDATA_WIDTH            (TDATA_INT_WIDTH),
                .SERIALIZATION_FACTOR   (CLKCROSS_FACTOR),
                .BUFFER_DEPTH           (BUFFER_DEPTH * SERIALIZATION_FACTOR),
                .FLIT_BUFFER_DEPTH      (FLIT_BUFFER_DEPTH),
                .EXTRA_SYNC_STAGES      (EXTRA_SYNC_STAGES),
                .FORCE_MLAB             (FORCE_MLAB))
            shim_inst (
                .clk_usr        (clk_usr),
                .clk_noc        (clk_noc),

                .rst_n_usr_sync (rst_n_usr_sync),
                .rst_n_noc_sync (rst_n_noc_sync),

                .axis_tvalid    (axis_int_tvalid),
                .axis_tready    (axis_int_tready),
                .axis_tdata     (axis_int_tdata),
                .axis_tlast     (axis_int_tlast),
                .axis_tdest     (axis_int_tdest),

                .data_in        (data_in),
                .dest_in        (dest_in),
                .is_tail_in     (is_tail_in),
                .send_in        (send_in),
                .credit_out     (credit_out)
            );
        end
    end
    endgenerate
endmodule: axis_deserializer_shim_out

module axis_clkcross_shim_in #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 4,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter EXTRA_SYNC_STAGES = 0,
    parameter FORCE_MLAB = 0
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
    always_ff @(posedge clk_noc) begin
        send_out <= data_buffer_rdreq;
    end

    // Credit counter
    always_ff @(posedge clk_noc) begin
        if (rst_n_noc_sync == 1'b0) begin
            credit_count <= FLIT_BUFFER_DEPTH;
        end else begin
            credit_count <= credit_count + credit_in - data_buffer_rdreq;
        end
    end

    // Serialization counter counts down to end of input word
    always_ff @(posedge clk_noc) begin
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
    dcfifo_agilex7 #(
        .WIDTH              (TDEST_WIDTH + 1),
        .DEPTH              (BUFFER_DEPTH),
        .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
        .SHOWAHEAD          ("OFF"),
        .FORCE_MLAB         (FORCE_MLAB)
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
    generate begin: data_fifo_gen
        if (SERIALIZATION_FACTOR == 1) begin
            dcfifo_agilex7 #(
                .WIDTH              (TDATA_WIDTH),
                .DEPTH              (BUFFER_DEPTH),
                .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
                .SHOWAHEAD          ("OFF"),
                .FORCE_MLAB         (FORCE_MLAB)
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
        end else begin
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
        end
    end
    endgenerate

endmodule: axis_clkcross_shim_in

module axis_clkcross_shim_out #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 4,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter EXTRA_SYNC_STAGES = 0,
    parameter FORCE_MLAB = 0
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
    always_ff @(posedge clk_noc) begin
        if (rst_n_noc_sync == 1'b0) begin
            credit_count <= FLIT_BUFFER_DEPTH;
        end else begin
            credit_count <= credit_count + credit_out - send_in;
        end
    end

    // Delay used credits since wrused has a two cycle latency
    always_ff @(posedge clk_noc) begin
        credit_count_reg <= credit_count;
    end

    // Credits are sent when there is space in the data buffer to hold more
    // This allows the buffer to larger than the number of credits
    // But wastes one entry in the FIFO
    assign credit_out = ((credit_count < FLIT_BUFFER_DEPTH) || send_in) &&
        ((BUFFER_DEPTH * SERIALIZATION_FACTOR) - 1 > data_buffer_wrusedw) &&
        (credit_count_reg < ((BUFFER_DEPTH * SERIALIZATION_FACTOR) - data_buffer_wrusedw - 1'b1));

    // Serialization counter
    always_ff @(posedge clk_noc) begin
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
    dcfifo_agilex7 #(
        .WIDTH              (TDEST_WIDTH + 1),
        .DEPTH              (BUFFER_DEPTH),
        .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
        .SHOWAHEAD          ("ON"),
        .FORCE_MLAB         (FORCE_MLAB)
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
    generate begin: data_buffer_gen
        if (SERIALIZATION_FACTOR == 1) begin
            dcfifo_agilex7 #(
                .WIDTH              (FLIT_WIDTH),
                .DEPTH              (BUFFER_DEPTH * SERIALIZATION_FACTOR),
                .EXTRA_SYNC_STAGES  (EXTRA_SYNC_STAGES),
                .SHOWAHEAD          ("ON"),
                .FORCE_MLAB         (FORCE_MLAB)
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
        end else begin
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
        end
    end
    endgenerate

endmodule: axis_clkcross_shim_out

module axis_shim_in #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter FORCE_MLAB = 0
) (
    input   wire    clk,
    input   wire    rst_n,

    input   wire                            axis_tvalid,
    output  logic                           axis_tready,
    input   wire    [TDATA_WIDTH - 1 : 0]   axis_tdata,
    input   wire                            axis_tlast,
    input   wire    [TDEST_WIDTH - 1 : 0]   axis_tdest,

    output  logic   [TDATA_WIDTH - 1 : 0]   data_out,
    output  logic   [TDEST_WIDTH - 1 : 0]   dest_out,
    output  logic                           is_tail_out,
    output  logic                           send_out,
    input   wire                            credit_in
);
    logic [$clog2(FLIT_BUFFER_DEPTH) : 0] credit_count;
    logic credit_used;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            credit_count <= FLIT_BUFFER_DEPTH;
        end else begin
            credit_count <= credit_count + credit_in - credit_used;
        end
    end

    generate begin: buffer_gen
        if (BUFFER_DEPTH == 0) begin
            assign data_out = axis_tdata;
            assign dest_out = axis_tdest;
            assign is_tail_out = axis_tlast;
            assign send_out = axis_tvalid & axis_tready;
            assign axis_tready = (credit_count != '0);
            assign credit_used = send_out;
        end else begin
            logic buffer_empty, buffer_full, buffer_rdreq;

            assign axis_tready = !buffer_full;
            assign credit_used = buffer_rdreq;
            assign buffer_rdreq = (credit_count > 0) & !buffer_empty;

            always_ff @(posedge clk) begin
                send_out <= buffer_rdreq;
            end

            fifo_agilex7 #(
                .WIDTH      (TDATA_WIDTH + TDEST_WIDTH + 1),
                .DEPTH      (BUFFER_DEPTH),
                .FORCE_MLAB (FORCE_MLAB))
            buffer (
                .clock  (clk),
                .data   ({axis_tdata, axis_tdest, axis_tlast}),
                .rdreq  (buffer_rdreq),
                .sclr   (~rst_n),
                .wrreq  (axis_tvalid & axis_tready),
                .empty  (buffer_empty),
                .full   (buffer_full),
                .q      ({data_out, dest_out, is_tail_out})
            );
        end
    end
    endgenerate

endmodule: axis_shim_in

module axis_shim_out #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter BUFFER_DEPTH = 4,
    parameter FLIT_BUFFER_DEPTH = 4,
    parameter FORCE_MLAB = 0
) (
    input   wire    clk,
    input   wire    rst_n,

    output  logic                           axis_tvalid,
    input   wire                            axis_tready,
    output  logic   [TDATA_WIDTH - 1 : 0]   axis_tdata,
    output  logic                           axis_tlast,
    output  logic   [TDEST_WIDTH - 1 : 0]   axis_tdest,

    input   wire    [TDATA_WIDTH - 1 : 0]   data_in,
    input   wire    [TDEST_WIDTH - 1 : 0]   dest_in,
    input   wire                            is_tail_in,
    input   wire                            send_in,
    output  logic                           credit_out
);

    logic buffer_empty, buffer_full;
    logic [$clog2(BUFFER_DEPTH) : 0] credit_count;
    logic [$clog2(BUFFER_DEPTH) : 0] buffer_usedw;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            credit_count <= FLIT_BUFFER_DEPTH;
            buffer_usedw <= '0;
        end else begin
            credit_count <= credit_count - send_in + credit_out;
            buffer_usedw <= buffer_usedw + send_in - (axis_tready & axis_tvalid);
        end
    end

    assign axis_tvalid = ~buffer_empty;

    assign credit_out = ((credit_count < FLIT_BUFFER_DEPTH) || send_in) &
                        ((credit_count < (BUFFER_DEPTH - buffer_usedw)) || (axis_tready & axis_tvalid));

    fifo_agilex7 #(
        .WIDTH      (TDATA_WIDTH + TDEST_WIDTH + 1),
        .DEPTH      (BUFFER_DEPTH),
        .SHOWAHEAD  ("ON"),
        .FORCE_MLAB (FORCE_MLAB))
    buffer (
        .clock  (clk),
        .data   ({data_in, dest_in, is_tail_in}),
        .rdreq  (axis_tvalid & axis_tready),
        .sclr   (~rst_n),
        .wrreq  (send_in),
        .empty  (buffer_empty),
        .full   (buffer_full),
        .q      ({axis_tdata, axis_tdest, axis_tlast})
    );

endmodule: axis_shim_out

module axis_serializer #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 2
) (
    input   wire    clk,
    input   wire    rst_n,

    input   wire                                                    axis_in_tvalid,
    output  logic                                                   axis_in_tready,
    input   wire    [TDATA_WIDTH - 1 : 0]                           axis_in_tdata,
    input   wire                                                    axis_in_tlast,
    input   wire    [TDEST_WIDTH - 1 : 0]                           axis_in_tdest,

    output  logic                                                   axis_out_tvalid,
    input   wire                                                    axis_out_tready,
    output  logic   [TDATA_WIDTH / SERIALIZATION_FACTOR - 1 : 0]    axis_out_tdata,
    output  logic                                                   axis_out_tlast,
    output  logic   [TDEST_WIDTH - 1 : 0]                           axis_out_tdest
);
    localparam TDATA_OUT_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR;

    logic [TDATA_WIDTH - 1 : 0] tdata_buffer;
    logic [TDEST_WIDTH - 1 : 0] tdest_buffer;
    logic                       tlast_buffer;

    logic [$clog2(SERIALIZATION_FACTOR) - 1 : 0] ser_count;

    assign axis_out_tdest = tdest_buffer;
    assign axis_out_tlast = tlast_buffer & (ser_count == (SERIALIZATION_FACTOR - 1));
    assign axis_in_tready = !axis_out_tvalid || ((axis_out_tready && axis_out_tvalid) && (ser_count == (SERIALIZATION_FACTOR - 1)));

    always_comb begin
        axis_out_tdata = tdata_buffer[TDATA_OUT_WIDTH * (ser_count + 1'b1) - 1 -: TDATA_OUT_WIDTH];
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ser_count <= '0;
        end else begin
            ser_count <= ser_count + (axis_out_tvalid & axis_out_tready);
            if (ser_count == (SERIALIZATION_FACTOR - 1) && (axis_out_tvalid & axis_out_tready)) begin
                ser_count <= '0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (axis_in_tready & axis_in_tvalid) begin
            tdata_buffer <= axis_in_tdata;
            tdest_buffer <= axis_in_tdest;
            tlast_buffer <= axis_in_tlast;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axis_out_tvalid <= 1'b0;
        end else begin
            if ((ser_count == SERIALIZATION_FACTOR - 1) && (axis_out_tvalid && axis_out_tready))
                axis_out_tvalid <= 1'b0;
            if (axis_in_tvalid && axis_in_tready)
                axis_out_tvalid <= 1'b1;
        end
    end

endmodule: axis_serializer

module axis_deserializer #(
    parameter TDEST_WIDTH = 3,
    parameter TDATA_WIDTH = 512,
    parameter SERIALIZATION_FACTOR = 2
) (
    input   wire    clk,
    input   wire    rst_n,

    input   wire                                                    axis_in_tvalid,
    output  logic                                                   axis_in_tready,
    input   wire    [TDATA_WIDTH / SERIALIZATION_FACTOR - 1 : 0]    axis_in_tdata,
    input   wire                                                    axis_in_tlast,
    input   wire    [TDEST_WIDTH - 1 : 0]                           axis_in_tdest,

    output  logic                                                   axis_out_tvalid,
    input   wire                                                    axis_out_tready,
    output  logic   [TDATA_WIDTH - 1 : 0]                           axis_out_tdata,
    output  logic                                                   axis_out_tlast,
    output  logic   [TDEST_WIDTH - 1 : 0]                           axis_out_tdest
);
    localparam TDATA_IN_WIDTH = TDATA_WIDTH / SERIALIZATION_FACTOR;

    logic [TDATA_WIDTH - 1 : 0] tdata_buffer;
    logic [TDEST_WIDTH - 1 : 0] tdest_buffer;
    logic                       tlast_buffer;

    logic [$clog2(SERIALIZATION_FACTOR) - 1 : 0] ser_count;

    assign axis_out_tdata = tdata_buffer;
    assign axis_out_tdest = tdest_buffer;
    assign axis_out_tlast = tlast_buffer;

    assign axis_in_tready = !axis_out_tvalid || ((axis_out_tready && axis_out_tvalid) && (ser_count == (SERIALIZATION_FACTOR - 1)));

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ser_count <= '0;
        end else begin
            ser_count <= ser_count + (axis_in_tvalid & axis_in_tready);
            if (ser_count == (SERIALIZATION_FACTOR - 1) && (axis_in_tvalid & axis_in_tready)) begin
                ser_count <= '0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            axis_out_tvalid <= 1'b0;
        end else begin
            if (axis_out_tvalid && axis_out_tready)
                axis_out_tvalid <= 1'b0;
            if ((ser_count == SERIALIZATION_FACTOR - 1) && (axis_in_tvalid && axis_in_tready))
                axis_out_tvalid <= 1'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (axis_in_tready & axis_in_tvalid) begin
            tdata_buffer[TDATA_IN_WIDTH * (ser_count + 1'b1) - 1 -: TDATA_IN_WIDTH] <= axis_in_tdata;
            if (ser_count == (SERIALIZATION_FACTOR - 1)) begin
                tdest_buffer <= axis_in_tdest;
                tlast_buffer <= axis_in_tlast;
            end
        end
    end

endmodule: axis_deserializer