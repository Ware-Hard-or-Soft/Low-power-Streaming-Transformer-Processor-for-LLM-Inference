// tile_loader.sv
// Streams input data into a 2D tile buffer for use by the MMA engine.
// Emits `tile_valid` when the tile is fully loaded

module tile_loader #(
    parameter TILE_SIZE = 8,
    parameter DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic reset,
    input  logic valid_in,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic ready_in,
    output logic tile_valid,
    output logic [DATA_WIDTH-1:0] tile [TILE_SIZE][TILE_SIZE],
    input  logic tile_read_en
);
    logic [$clog2(TILE_SIZE+1)-1:0] row_cnt, col_cnt;
    logic full;
    logic [DATA_WIDTH-1:0] tile_buf [TILE_SIZE][TILE_SIZE];

    assign ready_in = !full;
    assign tile_valid = full;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            row_cnt <= 0;
            col_cnt <= 0;
            full <= 0;
        end else if (valid_in && !full) begin
            tile_buf[row_cnt][col_cnt] <= data_in;
            if (col_cnt == TILE_SIZE - 1) begin
                col_cnt <= 0;
                if (row_cnt == TILE_SIZE - 1) begin
                    row_cnt <= 0;
                    full <= 1;
                end else begin
                    row_cnt <= row_cnt + 1;
                end
            end else begin
                col_cnt <= col_cnt + 1;
            end
        end else if (tile_read_en) begin
            full <= 0;
        end
    end

    always_comb begin
        for (int i = 0; i < TILE_SIZE; i++) begin
            for (int j = 0; j < TILE_SIZE; j++) begin
                tile[i][j] = tile_buf[i][j];
            end
        end
    end
endmodule
