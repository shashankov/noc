module shift_reg #(
    parameter DELAY = 1,
    parameter WIDTH = 1) (

    input wire clk,
    input wire rst_n,

    input wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] q
);

logic [WIDTH - 1 : 0] q_int[0 : DELAY - 1];

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < DELAY; i++) begin
            q_int[i] <= '0;
        end
    end else begin
        q_int[0] <= d;
        for (int i = 1; i < DELAY; i++) begin
            q_int[i] <= q_int[i-1];
        end
    end
end

assign q = q_int[DELAY - 1];

endmodule: shift_reg