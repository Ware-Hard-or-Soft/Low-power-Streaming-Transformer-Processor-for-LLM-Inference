// mma_tile_engine.sv
// Performs tiled matrix multiplication C = A × B using rank-by-rank accumulation.

module mma_tile_engine #(
    parameter TILE_SIZE = 8,
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic reset,
    input  logic start,
    input  logic signed [DATA_WIDTH-1:0] A [TILE_SIZE][TILE_SIZE],
    input  logic signed [DATA_WIDTH-1:0] B [TILE_SIZE][TILE_SIZE],
    output logic signed [2*DATA_WIDTH:0] C [TILE_SIZE][TILE_SIZE],
    output logic done
);
    logic [$clog2(TILE_SIZE):0] step;
    logic processing;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            step <= 0;
            done <= 0;
            processing <= 0;
        end else if (start) begin
            step <= 0;
            done <= 0;
            processing <= 1;
        end else if (processing) begin
            for (int i = 0; i < TILE_SIZE; i++) begin
                for (int j = 0; j < TILE_SIZE; j++) begin
                    if (step == 0)
                        C[i][j] <= A[i][step] * B[step][j];
                    else
                        C[i][j] <= C[i][j] + A[i][step] * B[step][j];
                end
            end
            step <= step + 1;
            if (step == TILE_SIZE - 1) begin
                done <= 1;
                processing <= 0;
            end
        end
    end
endmodule
