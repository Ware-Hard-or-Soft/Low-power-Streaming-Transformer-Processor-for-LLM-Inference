// activation_unit.sv
// Supports ReLU and placeholder for GELU activation.

module activation_unit #(
    parameter N = 8,
    parameter DW = 16
)(
    input  logic clk,
    input  logic signed [DW-1:0] data_in [N],
    input  logic relu_mode,
    output logic signed [DW-1:0] data_out [N]
);
    always_ff @(posedge clk) begin
        for (int i = 0; i < N; i++) begin
            if (relu_mode)
                data_out[i] <= (data_in[i] > 0) ? data_in[i] : 0;
            else
                data_out[i] <= data_in[i]; // Replace with GELU approx if needed
        end
    end
endmodule
