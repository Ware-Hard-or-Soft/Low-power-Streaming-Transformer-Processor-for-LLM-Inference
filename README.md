# Low-power-Streaming-Transformer-Processor-for-LLM-Inference
# Streaming Transformer Processor (FPGA)

Modular SystemVerilog implementation of a low-power, streaming matrix processor for LLM inference.

# 🔧 Features
- Tiled INT8 GEMM engine
- Softmax, GELU/ReLU, LayerNorm units
- Double-buffered streaming tile loaders
- FSM controller for Q/K/V + FFN scheduling
- Verified in Vivado with SystemVerilog testbench

# 🔋 Low Power Design Notes
- Clock gating for all compute blocks
- Quantized INT8 data path
- Tile-level data reuse and reduced DRAM bandwidth
- Double-buffering for compute/load overlap

# 📂 Directory Structure
- `rtl/` - all SystemVerilog RTL modules
- `tb/`  - simulation testbench
- `docs/` - architecture diagrams and notes

# 🧪 Simulation
Open Vivado, add all RTL/testbench files, and set `transformer_tb` as top module.
