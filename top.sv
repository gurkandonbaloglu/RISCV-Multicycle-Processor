module top (
    input  logic        clk, reset,
    output logic [31:0] WriteData, DataAdr, 
    output logic        MemWrite
);

    logic [31:0] ReadData; 

    riscv rvmulti (
        .clk(clk),
        .reset(reset),
        .ReadData(ReadData),     
        .Adr(DataAdr),           
        .WriteData(WriteData),   
        .MemWrite(MemWrite)      
    );

    mem memory (
        .clk(clk),
        .we(MemWrite),
        .a(DataAdr),
        .wd(WriteData),
        .rd(ReadData)
    );

endmodule