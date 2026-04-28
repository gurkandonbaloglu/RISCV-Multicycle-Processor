module mem (
    input  logic        clk, we,
    input  logic [31:0] a, wd,
    output logic [31:0] rd
);

    
    logic [31:0] RAM[63:0]; 

    
    initial begin
        $readmemh("C:/projects/Lab3_Multicycle/memfile.txt", RAM);
    end

    
    assign rd = RAM[a[31:2]]; 

    
    always_ff @(posedge clk) begin
        if (we) begin
            RAM[a[31:2]] <= wd;
        end
    end

endmodule