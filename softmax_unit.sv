// softmax_unit.sv
// Simplified softmax using fixed-point arithmetic.

module softmax_unit #(
    parameter N = 8,
    parameter DW = 16
)(
    input  logic clk,
    input  logic reset,
    input  logic valid_in,
    input  logic signed [DW-1:0] vec_in [N],
    output logic valid_out,
    output logic [DW-1:0] softmax_out [N]
);
    logic [DW-1:0] exp_val [N];
    logic [31:0] sum;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_out <= 0;
        end else if (valid_in) begin
            sum = 0;
            for (int i = 0; i < N; i++) begin
                exp_val[i] = vec_in[i]; // Placeholder: insert exp() approximation
                sum += exp_val[i];
            end
            for (int i = 0; i < N; i++) begin
                softmax_out[i] <= exp_val[i] * 256 / sum;
            end
            valid_out <= 1;
        end
    end
endmodule
