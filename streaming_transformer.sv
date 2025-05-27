// streaming_transformer.sv
// Top-level processor integrating tile_loader, MMA, softmax, activation, norm_add, and FSM

module streaming_transformer #(
    parameter TILE_SIZE = 8,
    parameter DATA_WIDTH = 8
)(
    input logic clk,
    input logic reset,
    input logic valid_q,
    input logic valid_k,
    input logic valid_v,
    input logic [DATA_WIDTH-1:0] data_q,
    input logic [DATA_WIDTH-1:0] data_k,
    input logic [DATA_WIDTH-1:0] data_v,
    output logic done
);

    // Tile buffers
    logic [DATA_WIDTH-1:0] Q_tile [TILE_SIZE][TILE_SIZE];
    logic [DATA_WIDTH-1:0] K_tile [TILE_SIZE][TILE_SIZE];
    logic [DATA_WIDTH-1:0] V_tile [TILE_SIZE][TILE_SIZE];
    logic tile_q_valid, tile_k_valid, tile_v_valid;
    logic tile_read_q, tile_read_k, tile_read_v;

    // Load Q, K, V tiles using tile_loader modules
    tile_loader #(.TILE_SIZE(TILE_SIZE), .DATA_WIDTH(DATA_WIDTH)) q_loader (
        .clk(clk), .reset(reset),
        .valid_in(valid_q), .data_in(data_q), .ready_in(),
        .tile_valid(tile_q_valid), .tile(Q_tile), .tile_read_en(tile_read_q)
    );

    tile_loader #(.TILE_SIZE(TILE_SIZE), .DATA_WIDTH(DATA_WIDTH)) k_loader (
        .clk(clk), .reset(reset),
        .valid_in(valid_k), .data_in(data_k), .ready_in(),
        .tile_valid(tile_k_valid), .tile(K_tile), .tile_read_en(tile_read_k)
    );

    tile_loader #(.TILE_SIZE(TILE_SIZE), .DATA_WIDTH(DATA_WIDTH)) v_loader (
        .clk(clk), .reset(reset),
        .valid_in(valid_v), .data_in(data_v), .ready_in(),
        .tile_valid(tile_v_valid), .tile(V_tile), .tile_read_en(tile_read_v)
    );

    // Attention score computation (Q · K^T)
    logic signed [2*DATA_WIDTH:0] attn_logits [TILE_SIZE][TILE_SIZE];
    logic attn_done, attn_start;

    mma_tile_engine #(.TILE_SIZE(TILE_SIZE), .DATA_WIDTH(DATA_WIDTH)) dot_product (
        .clk(clk), .reset(reset), .start(attn_start),
        .A(Q_tile), .B(K_tile), .C(attn_logits), .done(attn_done)
    );

    // Softmax
    logic [DATA_WIDTH-1:0] softmax_out [TILE_SIZE];
    logic softmax_valid;

    softmax_unit #(.N(TILE_SIZE), .DW(16)) softmax (
        .clk(clk), .reset(reset),
        .valid_in(attn_done),
        .vec_in(attn_logits[0]),  // Apply softmax row-wise on 1 row as simplification
        .valid_out(softmax_valid),
        .softmax_out(softmax_out)
    );

    // Weighted attention (softmax · V)
    logic signed [2*DATA_WIDTH:0] attn_out [TILE_SIZE][TILE_SIZE];
    logic attn_out_done, attn_out_start;

    // For simplicity: replicate softmax_out across rows for A matrix
    logic signed [DATA_WIDTH-1:0] softmax_tile [TILE_SIZE][TILE_SIZE];
    always_comb begin
        for (int i = 0; i < TILE_SIZE; i++)
            for (int j = 0; j < TILE_SIZE; j++)
                softmax_tile[i][j] = softmax_out[j];
    end

    mma_tile_engine #(.TILE_SIZE(TILE_SIZE), .DATA_WIDTH(DATA_WIDTH)) attn_weighting (
        .clk(clk), .reset(reset), .start(attn_out_start),
        .A(softmax_tile), .B(V_tile), .C(attn_out), .done(attn_out_done)
    );

    // Feed-forward activation
    logic [DATA_WIDTH-1:0] act_out [TILE_SIZE];
    activation_unit #(.N(TILE_SIZE), .DW(DATA_WIDTH)) act_unit (
        .clk(clk),
        .data_in(attn_out[0]),  // process first row
        .relu_mode(1'b1),
        .data_out(act_out)
    );

    // Residual + LayerNorm
    logic [DATA_WIDTH-1:0] norm_out [TILE_SIZE];
    norm_add_unit #(.N(TILE_SIZE), .DW(DATA_WIDTH)) norm_add (
        .x(act_out), .residual(Q_tile[0]), .y(norm_out)
    );

    // Controller FSM
    logic start_mma, start_softmax, start_ffn;
    logic done_ffn = 1;  // Immediate for now

    controller_fsm ctrl (
        .clk(clk), .reset(reset),
        .start_mma(attn_start),
        .start_softmax(attn_out_start),
        .start_ffn(),  // not used
        .done_mma(attn_done),
        .done_softmax(softmax_valid),
        .done_ffn(done_ffn)
    );

    assign done = attn_out_done;

endmodule
