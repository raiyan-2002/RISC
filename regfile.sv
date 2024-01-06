// one hot codes for multiplexers 
`define OH0 8'b0000_0001
`define OH1 8'b0000_0010
`define OH2 8'b0000_0100
`define OH3 8'b0000_1000
`define OH4 8'b0001_0000
`define OH5 8'b0010_0000
`define OH6 8'b0100_0000
`define OH7 8'b1000_0000

module regfile(data_in, writenum, write, readnum, clk, data_out);
    input [15:0] data_in;
    input [2:0] writenum, readnum;
    input write, clk;
    output [15:0] data_out;
    
    wire [7:0] writenum_decoded;

    // instantiate 3 to 8 decoder for the writenum input
    dec38 write_dec(writenum, writenum_decoded);
    
    wire [7:0] write_bus, load_into_registers;

    //turns the write signal into a bus of 8 copies of the write signal
    assign write_bus = {8{write}}; 

    //put an AND gate between each of the write_bus and writenum_decoded bus
    assign load_into_registers = write_bus & writenum_decoded; 

    wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
    
    // instantiate 8, 16 bit load enabled registers, all loaded to same clock
    LE_reg #(16) l0(data_in, load_into_registers[0], clk, R0); 
    LE_reg #(16) l1(data_in, load_into_registers[1], clk, R1); 
    LE_reg #(16) l2(data_in, load_into_registers[2], clk, R2); 
    LE_reg #(16) l3(data_in, load_into_registers[3], clk, R3); 
    LE_reg #(16) l4(data_in, load_into_registers[4], clk, R4); 
    LE_reg #(16) l5(data_in, load_into_registers[5], clk, R5); 
    LE_reg #(16) l6(data_in, load_into_registers[6], clk, R6); 
    LE_reg #(16) l7(data_in, load_into_registers[7], clk, R7); 

    wire [7:0] readnum_decoded;

    // instantiate 3 to 8 decoder for the readnum input
    dec38 readnum_dec(readnum, readnum_decoded);
    
    // instantiate 16 bit multiplxer with 8 inputs 
    mux8 #(16) final_mux(R0, R1, R2, R3, R4, R5, R6, R7, readnum_decoded, data_out);

endmodule

// d flip flop module definition
module vDFF2(clk, D, Q);
    parameter n = 1;
    input [n - 1: 0] D;
    output reg [n - 1: 0] Q;
    input clk;

    //on rising edge of clk, copy D to Q, like a D flip flop  
    always_ff @(posedge clk) begin
        Q = D;
    end 

endmodule

// 3 to 8 decoder module definition 
module dec38(binary, onehot);
    input [2:0] binary;
    output reg [7:0] onehot;
    
    //decodes binary input to onehot output. 
    //For every decimal value between 0-7 of the binary input, a pre-defined one-hot code is outputted
    always_comb begin 
        case(binary)
            0: onehot = `OH0;
            1: onehot = `OH1;
            2: onehot = `OH2;
            3: onehot = `OH3;
            4: onehot = `OH4;
            5: onehot = `OH5;
            6: onehot = `OH6;
            7: onehot = `OH7;
            default: onehot = 8'bxxxx_xxxx;
        endcase
    end

endmodule

// load enable module definition
module LE_reg(in, load, clk, out);
    parameter n = 1;
    input [n-1:0] in;
    input load;
    input clk;
    output [n-1:0] out;

    wire [n-1:0] muxToDFF;

    // instantiate flip flop
    vDFF2 #(n) flipFlop(clk, muxToDFF, out);
    // instantiate n bit multiplexer 
    mux2 #(n) mux_load(out, in, load, muxToDFF);

endmodule

// parametrized 2 input multiplexer definition
module mux2(in0, in1, s, out);
    parameter n = 1;
    input [n-1: 0] in0;
    input [n-1: 0] in1;
    input s;
    output reg [n-1: 0] out;

    //if select is 0, then out should be in0 (the input marked to be outputted when select is set to 0), 
    //otherwise select should be 1 and output is in1 (the input marked to be outputted when select is set to 1)
    always_comb begin
        if (s == 0) begin
            out = in0;
        end else begin
            out = in1;
        end
    end
endmodule

// parametrized 8 input multiplexer definition
module mux8(in0, in1, in2, in3, in4, in5, in6, in7, s, out);
    parameter n = 1;
    input [n-1: 0] in0;
    input [n-1: 0] in1;
    input [n-1: 0] in2;
    input [n-1: 0] in3;
    input [n-1: 0] in4;
    input [n-1: 0] in5;
    input [n-1: 0] in6;
    input [n-1: 0] in7;

    input [7:0] s;
    output reg [n-1: 0] out;

    //multiplexer with 8 different input busses. depending on which one-hot select corresponds to, outputs the corresponding input
    always_comb begin
        case(s)
            `OH0: out = in0;
            `OH1: out = in1;
            `OH2: out = in2;
            `OH3: out = in3;
            `OH4: out = in4;
            `OH5: out = in5;
            `OH6: out = in6;
            `OH7: out = in7;
            default: out = {n{1'bx}};
        endcase
    end
endmodule
