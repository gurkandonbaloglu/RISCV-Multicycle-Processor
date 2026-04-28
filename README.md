# Lab 3: Multicycle RISC-V Processor Design

This repository contains the SystemVerilog implementation of a 32-bit Multicycle RISC-V processor, designed as part of the Digital Design Laboratory course.

## Project Structure
- **top.sv**: The top-level module connecting the processor and memory.
- **riscv.sv**: Core processor module (instantiates controller and datapath).
- **controller.sv**: FSM-based control unit (11 states).
- **datapath.sv**: Data processing unit including ALU and register file.
- **mem.sv**: Unified memory module for both instructions and data.
- **building_blocks.sv**: Generic modules like muxes, registers, and the ALU.
- **testbench.sv**: Verification environment.

## Features
- Implements **RV32I** base instruction set (partial).
- Supports: `LW`, `SW`, `R-Type`, `ADDI`, `BEQ`, and `JAL`.
- Efficient resource usage by sharing a single ALU across multiple cycles.

## How to Run
1. Open the project in **Quartus Prime**.
2. Start the simulation via **ModelSim / Questa Intel FPGA**.
3. Run the simulation using the `run -all` command in the transcript window.
4. Verify the output: The simulation should terminate with the message `"Simulation succeeded"`.

## Results
The processor successfully executes the test program and writes the expected final value to memory at **725 ns**.
