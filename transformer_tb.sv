// transformer_tb.sv
// Testbench for the streaming_transformer module

module transformer_tb;

    parameter TILE_SIZE = 8;
    parameter DATA_WIDTH = 8;

    logic clk, reset;
    logic valid_q, valid_k, valid_v;
    logic [DATA_WIDTH-1:0] data_q, data_k, data_v;
    logic done;

    // DUT instantiation
    streaming_transformer #(
        .TILE_SIZE(TILE_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk), .reset(reset),
        .valid_q(valid_q), .valid_k(valid_k), .valid_v(valid_v),
        .data_q(data_q), .data_k(data_k), .data_v(data_v),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Flat tile data
    logic [DATA_WIDTH-1:0] q_tile_flat [TILE_SIZE*TILE_SIZE];
    logic [DATA_WIDTH-1:0] k_tile_flat [TILE_SIZE*TILE_SIZE];
    logic [DATA_WIDTH-1:0] v_tile_flat [TILE_SIZE*TILE_SIZE];

    initial begin
        // Initial state
        clk = 0;
        reset = 1;
        valid_q = 0;
        valid_k = 0;
        valid_v = 0;
        data_q = 0;
        data_k = 0;
        data_v = 0;

        // Release reset
        #20 reset = 0;

        // Generate mock Q/K/V input tiles
        for (int i = 0; i < TILE_SIZE*TILE_SIZE; i++) begin
            q_tile_flat[i] = i;
            k_tile_flat[i] = TILE_SIZE*TILE_SIZE - i;
            v_tile_flat[i] = (i % 2 == 0) ? 3 : 1;
        end

        // Stream Q tile
        for (int i = 0; i < TILE_SIZE*TILE_SIZE; i++) begin
            @(posedge clk);
            valid_q <= 1;
            data_q <= q_tile_flat[i];
        end
        @(posedge clk);
        valid_q <= 0;

        // Stream K tile
        for (int i = 0; i < TILE_SIZE*TILE_SIZE; i++) begin
            @(posedge clk);
            valid_k <= 1;
            data_k <= k_tile_flat[i];
        end
        @(posedge clk);
        valid_k <= 0;

        // Stream V tile
        for (int i = 0; i < TILE_SIZE*TILE_SIZE; i++) begin
            @(posedge clk);
            valid_v <= 1;
            data_v <= v_tile_flat[i];
        end
        @(posedge clk);
        valid_v <= 0;

        // Wait for completion
        wait(done);
        $display("✅ Transformer pipeline completed simulation!");
        $finish;
    end

endmodule
