// norm_add_unit.sv
// Performs layer normalization and adds residual connection.

module norm_add_unit #(
    parameter N = 8,
    parameter DW = 16
)(
    input  logic signed [DW-1:0] x [N],
    input  logic signed [DW-1:0] residual [N],
    output logic signed [DW-1:0] y [N]
);
    logic signed [DW-1:0] sum;
    logic signed [DW-1:0] mean;

    always_comb begin
        sum = 0;
        for (int i = 0; i < N; i++)
            sum += x[i];
        mean = sum / N;

        for (int i = 0; i < N; i++)
            y[i] = (x[i] - mean) + residual[i];
    end
endmodule
