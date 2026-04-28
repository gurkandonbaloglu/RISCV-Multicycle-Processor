module riscv (
    input  logic        clk, reset,
    input  logic [31:0] ReadData,
    output logic [31:0] Adr, WriteData,
    output logic        MemWrite
);


    logic        PCWrite, AdrSrc, IRWrite, RegWrite;
    logic        Zero;
    logic [1:0]  ResultSrc, ALUSrcA, ALUSrcB, ImmSrc;
    logic [2:0]  ALUControl;
    logic [31:0] Instr;

   
    controller c (
        .clk(clk),
        .reset(reset),
        .op(Instr[6:0]),
        .funct3(Instr[14:12]),
        .funct7b5(Instr[30]),
        .Zero(Zero),
        .ImmSrc(ImmSrc),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .AdrSrc(AdrSrc),
        .IRWrite(IRWrite),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl)
    );

   
    datapath dp (
        .clk(clk),
        .reset(reset),
        .Adr(Adr),
        .WriteData(WriteData),
        .ReadData(ReadData),
        .Instr(Instr),
        .ALUControl(ALUControl),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc),
        .ImmSrc(ImmSrc),
        .IRWrite(IRWrite),
        .PCWrite(PCWrite),
        .RegWrite(RegWrite),
        .AdrSrc(AdrSrc),
        .Zero(Zero)
    );

endmodule