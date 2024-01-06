module datapath(clk,   
                readnum,
                vsel,

                loada,
                loadb,
                shift,
                asel,
                bsel,

                ALUop,
                loadc,
                loads,
                writenum,
                write,

                mdata,
                sximm8,
                sximm5,
                PC,

                C,
                status_out
                );

    input [3:0] vsel;
    input write, clk, loada, loadb, asel, bsel, loads, loadc;
    input [1:0] shift, ALUop;
    input [2:0] writenum, readnum;

    input [15:0] mdata;
    input [15:0] sximm8;
    input [15:0] sximm5;
    input [7:0] PC;
    
    output [15:0] C;
    output [2:0] status_out;
    
    wire [15:0] data_in, data_out, in, sout, RA, Bin, Ain, out;
    wire [2:0] status;

    // instantiate 16 bit writeback multiplexer, corresponds to component 9 on diagram
    mux4 #(16) writeback_mux(mdata, sximm8, {8'b0000_0000, PC}, C, vsel, data_in);
    
    // instantiate 16 bit source operand multiplexer, corresponds to component 6 on diagram
    mux2 #(16) mux_A(RA, 16'b0, asel, Ain);    

    // instantiate 16 bit source operand multiplexer, corresponds to component 7 on diagram
    mux2 #(16) mux_B(sout, sximm5, bsel, Bin);

    // instantiate shifter unit, corresponds to component 8 on diagram
    shifter U1(in, shift, sout);
    
    // instantiate ALU unit, corresponds to component 2 on diagram
    ALU U2(Ain, Bin, ALUop, out, status);

    // instantiate regfile, corresponds to component 1 on diagram
    regfile REGFILE(data_in, writenum, write, readnum, clk, data_out);

    // instantaiate load enabled register A, corresponds to component 3 on diagram
    LE_reg #(16) registerA(data_out, loada, clk, RA);

    // instantiate load enabled register B, corresponds to component 4 on diagram
    LE_reg #(16) registerB(data_out, loadb, clk, in);

    //instantaite load enabled register C, corresponds to component 5 on diagram
    LE_reg #(16) registerC(out, loadc, clk, C);

    // instantiates status register, corresponds to component 10 on diagram
    LE_reg #(3) register_status(status, loads, clk, status_out);

endmodule

// parametrized 4 input multiplexer definition
module mux4(in0, in1, in2, in3, s, out);
    parameter n = 1;
    input [n-1: 0] in0;
    input [n-1: 0] in1;
    input [n-1: 0] in2;
    input [n-1: 0] in3;
    input [3:0] s;
    output reg [n-1: 0] out;

    //if select is 0, then out should be in0 (the input marked to be outputted when select is set to 0), 
    //otherwise select should be 1 and output is in1 (the input marked to be outputted when select is set to 1)
    always_comb begin
        case(s) 
            4'b0001: out = in0;
            4'b0010: out = in1;
            4'b0100: out = in2;
            4'b1000: out = in3;
            default: out = {n{1'bx}};
        endcase
    end
endmodule
