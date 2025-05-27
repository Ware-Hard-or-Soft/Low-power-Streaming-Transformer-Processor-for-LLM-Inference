// controller_fsm.sv
// Simple FSM to coordinate processing stages

module controller_fsm (
    input  logic clk,
    input  logic reset,
    output logic start_mma,
    output logic start_softmax,
    output logic start_ffn,
    input  logic done_mma,
    input  logic done_softmax,
    input  logic done_ffn
);
    typedef enum logic [2:0] {
        IDLE, LOAD, DOT, ATTN, FFN, DONE
    } state_t;

    state_t state;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else case (state)
            IDLE: state <= LOAD;
            LOAD: state <= DOT;
            DOT:  if (done_mma) state <= ATTN;
            ATTN: if (done_softmax) state <= FFN;
            FFN:  if (done_ffn) state <= DONE;
            DONE: state <= IDLE;
        endcase
    end

    assign start_mma = (state == DOT);
    assign start_softmax = (state == ATTN);
    assign start_ffn = (state == FFN);
endmodule
