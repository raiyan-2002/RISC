module ALU(Ain,Bin,ALUop,out,status);
    input [15:0] Ain, Bin;
    input [1:0] ALUop;
    output reg [15:0] out;
    reg Z; //is it zero?
    reg V; //overflow?
    reg N; //negative?
    output [2:0] status;
    assign status = {Z, V, N};

    // combination logic block to change outputs out and Z when any input signals change
    always_comb begin
        
        // change out based on current value of ALUop
        case(ALUop) 
            2'b00: out = Ain + Bin;
            2'b01: out = Ain - Bin;
            2'b10: out = Ain & Bin;
            2'b11: out = ~Bin;
            default: out = 16'bxxxx_xxxx_xxxx_xxxx;
        endcase

        // change Z based on value of out
        if (out == 0) begin 
            Z = 1'b1;
        end else begin
            Z = 1'b0;
        end

        //change V based on overflow
        //ALUop == 2'b01 means it's in subtraction move
        if (ALUop == 2'b01) begin
            //if Ain is positive, Bin is negative, and Ain-Bin is somehow negative, then we have overflow
            if (Ain[15] == 0 & Bin[15] == 1 & out[15] == 1) begin
                V = 1'b1;
            //if Ain is negative, Bin is positive, and Ain-Bin is somehow positive, then we have overflow
            end else if (Ain[15] == 1 & Bin[15] == 0 & out[15] == 0) begin
                V = 1'b1;
            end else begin
                V = 1'b0;
            end
        end else begin
            V = 1'b0;
        end

        //change N based on negative
        N = out[15];

    end

endmodule