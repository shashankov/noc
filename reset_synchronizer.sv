module reset_synchronizer #(
    parameter NUM_EXTEND_CYCLES = 4
) (
    input wire reset_async,
    input wire sync_clk,
    output logic reset_sync
);

    logic reset_async_reg, reset_async_reg2;

    always @(posedge sync_clk) begin
        reset_async_reg <= reset_async;
        reset_async_reg2 <= reset_async_reg;
    end

    generate begin
        if (NUM_EXTEND_CYCLES > 0) begin
            genvar i;
            logic [NUM_EXTEND_CYCLES - 1 : 0] reset_extend;

            always @(posedge sync_clk) begin
                if (NUM_EXTEND_CYCLES > 1)
                    reset_extend[NUM_EXTEND_CYCLES - 1 : 1] <= reset_extend[NUM_EXTEND_CYCLES - 2 : 0];
                reset_extend[0] <= reset_async_reg2;
            end

            always @(*) begin
                reset_sync = reset_async_reg2;
                for (int i = 0; i < NUM_EXTEND_CYCLES; i++) begin
                    reset_sync = reset_sync | reset_extend[i];
                end
            end
        end else begin
            assign reset_sync = reset_async_reg2;
        end
    end
    endgenerate

endmodule: reset_synchronizer
