/**
 * @file fifo_2vc.sv
 *
 * @brief Special FIFO for 2 virtual channels
 *
 * @author Shashank Obla
 * Contact: sobla@andrew.cmu.edu
 *
 */

// Can merge two FIFOs into one since only one VC is active at a time

module fifo_2vc #(
    parameter DEPTH = 4,
    parameter WIDTH = 512,
    parameter FORCE_MLAB = 0
) (
    input   wire                    clk,
    input   wire                    sclr,

    input   wire    [WIDTH - 1 : 0] data[2],
    input   wire                    wrreq[2],
    input   wire                    full[2],

    output  logic   [WIDTH - 1 : 0] q[2],
    output  logic                   empty[2],
    input   wire                    rdreq[2]
);

endmodule: fifo_2vc
