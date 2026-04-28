// --- 1. KAYDEDİCİ DOSYASI (Register File) ---
// İşlemcinin içindeki x0-x31 arası 32-bitlik kayıt alanları
module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  a1, a2, a3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf [31:0];

    // Yazma işlemi (Senkron)
    always_ff @(posedge clk) begin
        if (we3) rf[a3] <= wd3;
    end

    // Okuma işlemi (Kombinasyonel - x0 her zaman 0'dır)
    assign rd1 = (a1 != 0) ? rf[a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf[a2] : 32'b0;
endmodule


// --- 2. ALU (Aritmetik Mantık Birimi) ---
// Toplama, çıkarma, ve, veya gibi işlemleri yapan ana matematik motoru
module alu (
    input  logic [31:0] a, b,
    input  logic [2:0]  alucontrol,
    output logic [31:0] result,
    output logic        zero
);
    always_comb begin
        case (alucontrol)
            3'b000: result = a + b;         // add (Toplama)
            3'b001: result = a - b;         // sub (Çıkarma)
            3'b010: result = a & b;         // and (VE)
            3'b011: result = a | b;         // or (VEYA)
            3'b101: result = (a < b) ? 32'd1 : 32'd0; // slt (Küçüktür)
            default: result = 32'bx;
        endcase
    end

    // Sonuç 0 ise Zero bayrağını 1 yap (Dallanmalar için kritik)
    assign zero = (result == 32'b0);
endmodule


// --- 3. EXTEND (İşaret Uzatıcı Birim) ---
// Komutun içindeki offset (mesafe) değerlerini 32-bite çevirir
module extend (
    input  logic [31:7] instr,
    input  logic [1:0]  immsrc,
    output logic [31:0] immext
);
    always_comb begin
        case(immsrc)
            2'b00: immext = {{20{instr[31]}}, instr[31:20]}; // I-type (lw, addi vb.)
            2'b01: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S-type (sw)
            2'b10: immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type (beq)
            2'b11: immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type (jal)
            default: immext = 32'bx;
        endcase
    end
endmodule


// --- 4. FLOPR (Resetli Normal Kaydedici / D-Flip Flop) ---
// Data, A, B, ALUOut gibi her çevrimde güncellenen ara kutular
module flopr #(parameter WIDTH = 8) (
    input  logic             clk, reset,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) q <= 0;
        else       q <= d;
    end
endmodule


// --- 5. FLOPENR (Enable'lı ve Resetli Kaydedici) ---
// PC, IR, OldPC gibi sadece izin verildiğinde (Enable=1) güncellenen kutular
module flopenr #(parameter WIDTH = 8) (
    input  logic             clk, reset, en,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset)   q <= 0;
        else if (en) q <= d;
    end
endmodule


module mux2 #(parameter WIDTH = 8) (
    input  logic [WIDTH-1:0] d0, d1,
    input  logic             s,
    output logic [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule



module mux3 #(parameter WIDTH = 8) (
    input  logic [WIDTH-1:0] d0, d1, d2,
    input  logic [1:0]       s,
    output logic [WIDTH-1:0] y
);
    always_comb begin
        case(s)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            default: y = d0;
        endcase
    end
endmodule