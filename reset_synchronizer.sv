module reset_synchronizer #(
    parameter NUM_EXTEND_CYCLES = 4,
    parameter NUM_OUTPUT_REGISTERS = 1
) (
    input wire reset_async,
    input wire sync_clk,
    output logic reset_sync
);

    logic reset_async_reg, reset_async_reg2, reset_sync_int;

    always_ff @(posedge sync_clk) begin
        reset_async_reg <= reset_async;
        reset_async_reg2 <= reset_async_reg;
    end

    generate begin
        if (NUM_EXTEND_CYCLES > 0) begin
            genvar i;
            logic [NUM_EXTEND_CYCLES - 1 : 0] reset_extend;

            always_ff @(posedge sync_clk) begin
                if (NUM_EXTEND_CYCLES > 1)
                    reset_extend[NUM_EXTEND_CYCLES - 1 : 1] <= reset_extend[NUM_EXTEND_CYCLES - 2 : 0];
                reset_extend[0] <= reset_async_reg2;
            end

            always_comb begin
                reset_sync_int = reset_async_reg2;
                for (int i = 0; i < NUM_EXTEND_CYCLES; i++) begin
                    reset_sync_int = reset_sync_int | reset_extend[i];
                end
            end
        end else begin
            assign reset_sync_int = reset_async_reg2;
        end
    end
    endgenerate

    generate begin: output_registers_gen
        if (NUM_OUTPUT_REGISTERS > 0) begin
            logic reset_sync_reg[NUM_OUTPUT_REGISTERS];

            always_ff @(posedge sync_clk) begin
                reset_sync_reg[0] <= reset_sync_int;
                for (int i = 1; i < NUM_OUTPUT_REGISTERS; i++) begin
                    reset_sync_reg[i] <= reset_sync_reg[i - 1];
                end
            end

            assign reset_sync = reset_sync_reg[NUM_OUTPUT_REGISTERS - 1];
        end
    end
    endgenerate

endmodule: reset_synchronizer
