module controller (
    input  logic       clk,
    input  logic       reset,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       Zero,
    output logic [1:0] ImmSrc,
    output logic [1:0] ALUSrcA, ALUSrcB,
    output logic [1:0] ResultSrc,
    output logic       AdrSrc,
    output logic       IRWrite,
    output logic       PCWrite,
    output logic       RegWrite,
    output logic       MemWrite,
    output logic [2:0] ALUControl
);

    // FSM Durumları (States) için Enum Tanımlaması
    typedef enum logic [3:0] {
        FETCH    = 4'd0,
        DECODE   = 4'd1,
        MEMADR   = 4'd2,
        MEMREAD  = 4'd3,
        MEMWB    = 4'd4,
        MEMWRITE = 4'd5,
        EXECUTER = 4'd6,
        ALUWB    = 4'd7,
        EXECUTEI = 4'd8,
        JAL      = 4'd9,
        BEQ      = 4'd10
    } statetype;

    statetype state, next_state;

    // FSM İç Sinyalleri
    logic [1:0] ALUOp;
    logic       Branch, PCUpdate;

    // --- 1. STATE REGISTER (Senkron - Saat sinyali ile değişir) ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= FETCH;
        else       state <= next_state;
    end

    // --- 2. NEXT STATE LOGIC (Kombinasyonel - Oklara göre geçişler) ---
    always_comb begin
        case (state)
            FETCH:    next_state = DECODE;
            DECODE: begin
                case (op)
                    7'b0000011: next_state = MEMADR;   // lw
                    7'b0100011: next_state = MEMADR;   // sw
                    7'b0110011: next_state = EXECUTER; // R-type
                    7'b0010011: next_state = EXECUTEI; // I-type ALU
                    7'b1101111: next_state = JAL;      // jal
                    7'b1100011: next_state = BEQ;      // beq
                    default:    next_state = FETCH;    // Hata durumu
                endcase
            end
            MEMADR: begin
                if (op == 7'b0000011) next_state = MEMREAD;  // lw
                else                  next_state = MEMWRITE; // sw
            end
            MEMREAD:  next_state = MEMWB;
            MEMWB:    next_state = FETCH;
            MEMWRITE: next_state = FETCH;
            EXECUTER: next_state = ALUWB;
            EXECUTEI: next_state = ALUWB;
            ALUWB:    next_state = FETCH;
            JAL:      next_state = ALUWB;
            BEQ:      next_state = FETCH;
            default:  next_state = FETCH;
        endcase
    end

    // --- 3. OUTPUT LOGIC (Kombinasyonel - Baloncukların içi) ---
    // Her adımda "latch" (istenmeyen hafıza) oluşmaması için önce her şeyi 0'lıyoruz
    always_comb begin
        AdrSrc    = 1'b0;
        IRWrite   = 1'b0;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 2'b00;
        ALUOp     = 2'b00;
        ResultSrc = 2'b00;
        PCUpdate  = 1'b0;
        Branch    = 1'b0;
        RegWrite  = 1'b0;
        MemWrite  = 1'b0;

        case (state)
            FETCH: begin
                AdrSrc    = 1'b0;
                IRWrite   = 1'b1;
                ALUSrcA   = 2'b00;
                ALUSrcB   = 2'b10;
                ALUOp     = 2'b00;
                ResultSrc = 2'b10;
                PCUpdate  = 1'b1;
            end
            DECODE: begin
                ALUSrcA   = 2'b01;
                ALUSrcB   = 2'b01;
                ALUOp     = 2'b00;
            end
            MEMADR: begin
                ALUSrcA   = 2'b10;
                ALUSrcB   = 2'b01;
                ALUOp     = 2'b00;
            end
            MEMREAD: begin
                ResultSrc = 2'b00;
                AdrSrc    = 1'b1;
            end
            MEMWB: begin
                ResultSrc = 2'b01;
                RegWrite  = 1'b1;
            end
            MEMWRITE: begin
                ResultSrc = 2'b00;
                AdrSrc    = 1'b1;
                MemWrite  = 1'b1;
            end
            EXECUTER: begin
                ALUSrcA   = 2'b10;
                ALUSrcB   = 2'b00;
                ALUOp     = 2'b10;
            end
            EXECUTEI: begin
                ALUSrcA   = 2'b10;
                ALUSrcB   = 2'b01;
                ALUOp     = 2'b10;
            end
            ALUWB: begin
                ResultSrc = 2'b00;
                RegWrite  = 1'b1;
            end
            BEQ: begin
                ALUSrcA   = 2'b10;
                ALUSrcB   = 2'b00;
                ALUOp     = 2'b01;
                ResultSrc = 2'b00;
                Branch    = 1'b1;
            end
            JAL: begin
                ALUSrcA   = 2'b01;
                ALUSrcB   = 2'b10;
                ALUOp     = 2'b00;
                ResultSrc = 2'b00;
                PCUpdate  = 1'b1;
            end
        endcase
    end

    // --- PC YAZMA VE BRANCH MANTIĞI ---
    // FSM'den gelen Branch ve ALU'dan gelen Zero'ya göre PC'yi güncelleme
    assign PCWrite = PCUpdate | (Branch & Zero);

    // --- IMMSRC DECODER (Komuta Göre Immediate Uzatıcı Seçimi) ---
    always_comb begin
        case (op)
            7'b0100011: ImmSrc = 2'b01; // sw (S-type)
            7'b1100011: ImmSrc = 2'b10; // beq (B-type)
            7'b1101111: ImmSrc = 2'b11; // jal (J-type)
            default:    ImmSrc = 2'b00; // lw, I-type ALU (I-type)
        endcase
    end

    // --- ALU DECODER (ALU'nun yapacağı matematiksel işlemi seçer) ---
    logic RtypeSub;
    assign RtypeSub = funct7b5 & op[5]; // op[5]=1 ise R-type, 0 ise I-type

    always_comb begin
        case (ALUOp)
            2'b00: ALUControl = 3'b000; // Toplama (Fetch, Decode, MemAdr, JAL)
            2'b01: ALUControl = 3'b001; // Çıkarma (BEQ)
            2'b10: begin // R-type veya I-type ALU işlemleri
                case (funct3)
                    3'b000: begin
                        if (RtypeSub) ALUControl = 3'b001; // sub
                        else          ALUControl = 3'b000; // add, addi
                    end
                    3'b010: ALUControl = 3'b101; // slt, slti
                    3'b110: ALUControl = 3'b011; // or, ori
                    3'b111: ALUControl = 3'b010; // and, andi
                    default: ALUControl = 3'b000;
                endcase
            end
            default: ALUControl = 3'b000;
        endcase
    end

endmodule