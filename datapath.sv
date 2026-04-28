module datapath (
    input  logic        clk, reset,
    output logic [31:0] Adr, WriteData,
    input  logic [31:0] ReadData,
    output logic [31:0] Instr,
    input  logic [2:0]  ALUControl,
    input  logic [1:0]  ALUSrcA, ALUSrcB, ResultSrc, ImmSrc,
    input  logic        IRWrite, PCWrite, RegWrite, AdrSrc,
    output logic        Zero
);

    // İç Kablolar (Sinyaller)
    logic [31:0] PC, PCNext, OldPC;
    logic [31:0] Data, RD1, RD2, A, B;
    logic [31:0] SrcA, SrcB;
    logic [31:0] ALUResult, ALUOut;
    logic [31:0] Result, ImmExt;

    // --- 1. PROGRAM SAYACI (PC) VE ADRES MANTIĞI ---
    // PC Kaydedicisi (Sadece PCWrite 1 olduğunda güncellenir)
    flopenr #(32) pcreg (clk, reset, PCWrite, Result, PC);

    // Adres Çoklayıcısı (0 ise PC, 1 ise ALUOut)
    mux2 #(32) adrmux (PC, ALUOut, AdrSrc, Adr);

    // --- 2. ARA KAYDEDİCİLER (BELLEKTEN GELENLER) ---
    // Komut Kaydedicisi (IR - Sadece IRWrite 1 olduğunda güncellenir)
    flopenr #(32) ireg (clk, reset, IRWrite, ReadData, Instr);
    
    // Eski PC Kaydedicisi (IRWrite ile aynı anda güncellenir)
    flopenr #(32) oldpcreg (clk, reset, IRWrite, PC, OldPC);
    
    // Veri Kaydedicisi (Her çevrimde güncellenir)
    flopr #(32) datareg (clk, reset, ReadData, Data);

    // --- 3. REGISTER FILE VE EXTEND BİRİMİ ---
    regfile rf (
        .clk(clk), 
        .we3(RegWrite), 
        .a1(Instr[19:15]), 
        .a2(Instr[24:20]), 
        .a3(Instr[11:7]), 
        .wd3(Result), 
        .rd1(RD1), 
        .rd2(RD2)
    );

    extend ext (
        .instr(Instr[31:7]), 
        .immsrc(ImmSrc), 
        .immext(ImmExt)
    );

    // Register File çıkışlarındaki ara kaydediciler (A ve B)
    flopr #(32) areg (clk, reset, RD1, A);
    flopr #(32) breg (clk, reset, RD2, B);
    
    // B kaydedicisinden çıkan değer aynı zamanda belleğe gidecek veridir (WriteData)
    assign WriteData = B;

    // --- 4. ALU VE GİRİŞ ÇOKLAYICILARI ---
    // ALU SrcA Çoklayıcısı (3 girişli)
    mux3 #(32) srcamux (
        .d0(PC), 
        .d1(OldPC), 
        .d2(A), 
        .s(ALUSrcA), 
        .y(SrcA)
    );

    // ALU SrcB Çoklayıcısı (3 girişli)
	mux3 #(32) srcbmux (
        .d0(B), 
        .d1(ImmExt),   // <-- 01 seçildiğinde ImmExt gelsin
        .d2(32'd4),    // <-- 10 seçildiğinde 4 gelsin
        .s(ALUSrcB), 
        .y(SrcB)
    );

    alu alunit (
        .a(SrcA), 
        .b(SrcB), 
        .alucontrol(ALUControl), 
        .result(ALUResult), 
        .zero(Zero)
    );

    // ALU çıkışındaki ara kaydedici
    flopr #(32) aluoutreg (clk, reset, ALUResult, ALUOut);

    // --- 5. SONUÇ ÇOKLAYICISI (ResultSrc) ---
    // Sona giden 3 girişli çoklayıcı (00: ALUOut, 01: Data, 10: ALUResult)
    mux3 #(32) resmux (
        .d0(ALUOut), 
        .d1(Data), 
        .d2(ALUResult), 
        .s(ResultSrc), 
        .y(Result)
    );

endmodule