//state encoding
`define S_RST 6'b000000

`define S_MOV_IMM 6'b000001

`define S_MOV_1 6'b000010
`define S_MOV_2 6'b000011
`define S_MOV_3 6'b000100

`define S_ADD_1 6'b000101
`define S_ADD_2 6'b000110
`define S_ADD_3 6'b000111
`define S_ADD_4 6'b001000

`define S_CMP_1 6'b001001
`define S_CMP_2 6'b001010
`define S_CMP_3 6'b001011

`define S_AND_1 6'b001100
`define S_AND_2 6'b001101
`define S_AND_3 6'b001110
`define S_AND_4 6'b001111

`define S_MVN_1 6'b010000
`define S_MVN_2 6'b010001
`define S_MVN_3 6'b010010

`define S_IF1 6'b010011
`define S_IF2 6'b010100
`define S_UPC 6'b010101

`define S_LDR1 6'b010110
`define S_LDR2 6'b010111
`define S_LDR3 6'b011000
`define S_LDR4 6'b011001
`define S_LDR5 6'b011010

`define S_STR1 6'b011011
`define S_STR2 6'b011100
`define S_STR3 6'b011101
`define S_STR4 6'b011110
`define S_STR5 6'b011111
`define S_STR6 6'b100000

`define S_HALT 6'b100001

//opcodes
`define OPCODE_MOV 3'b110
`define OPCODE_ALU 3'b101
`define OPCODE_LDR 3'b011
`define OPCODE_STR 3'b100
`define OPCODE_HALT 3'b111

//op for mov instructions
`define MOV_IMM 2'b10
`define MOV_REG 2'b00

//op for alu instructions
`define ALU_ADD 2'b00
`define ALU_CMP 2'b01
`define ALU_AND 2'b10
`define ALU_MVN 2'b11

//nsel onehot
`define NSEL_RN 3'b001
`define NSEL_RD 3'b010
`define NSEL_RM 3'b100

//vsel onehot
`define VSEL_MDATA 4'b0001
`define VSEL_IMM 4'b0010
`define VSEL_PC 4'b0100
`define VSEL_C 4'b1000

//steps
`define STEP0 3'b000
`define STEP1 3'b001
`define STEP2 3'b010
`define STEP3 3'b011

//mem_cmd
`define MNONE 2'b00
`define MREAD 2'b01
`define MWRITE 2'b10


module cpu(clk,reset,s,load,in,out,N,V,Z,w, mem_cmd, mem_addr, read_data, write_data, PC);
    input clk, reset, s, load;
    input [15:0] in;
    output [15:0] out;
    output N, V, Z, w;

    input [15:0] read_data;
    output [1:0] mem_cmd;
    output [8:0] mem_addr;
    output [15:0] write_data;
    
    wire [15:0] reg_to_dec;

    //fsm to dec wires
    wire [2:0] opcode;
    wire [1:0] op;
    wire [2:0] nsel;

    //dec to datapath wires
    wire [1:0] ALUop;
    wire [15:0] sximm5;
    wire [15:0] sximm8;
    wire [1:0] shift;
    wire [2:0] readnum;
    wire [2:0] writenum;
    wire [15:0] mdata;
    output [8:0] PC;
    wire [8:0] next_pc;
    wire load_ir;
    wire load_addr;
    wire [8:0] data_addr;

    assign mdata = {16{1'b0}};


    // fsm to PC wires, and other PC wires
    wire load_pc, reset_pc, addr_sel;
    wire [8:0] pcplus;

    // add 1 to PC
    assign pcplus = PC + 1;

    // load enabled register for program counter
    LE_reg #(9) PC_REG(next_pc, load_pc, clk, PC);
    
    // 2 - input binary select multiplexer for program counter
    mux2 #(9) PC_MUX(pcplus, {9{1'b0}}, reset_pc, next_pc);

    // 2 - input binary select address multiplexer
    mux2 #(9) ADDR_MUX(data_addr, PC, addr_sel, mem_addr);

    LE_reg #(9) DATA_ADDRESS(write_data[8:0],load_addr,clk,data_addr);


    //fsm to datapath wires
    wire [3:0] vsel;
    wire loada, loadb, loadc, loads, asel, bsel, write;

    // load enabled register for instruction register
    LE_reg #(16) INS_REG(read_data, load_ir, clk, reg_to_dec);

    // instantiate instruction decoder to decode instruction register output
    instruction_decoder INS_DEC(reg_to_dec, nsel, opcode, op, ALUop, sximm5, sximm8, shift, readnum, writenum);

    // instantiate state machine
    state_machine FSM(
        .s (s),
        .reset (reset),
        .clk (clk),
        .opcode (opcode),
        .op (op),
        .nsel (nsel),
        .vsel (vsel),
        .loada (loada),
        .loadb (loadb),
        .loadc (loadc),
        .loads (loads),
        .asel (asel),
        .bsel (bsel),
        .write (write),
        .w (w),
        .load_ir (load_ir),
        .mem_cmd (mem_cmd),
        .addr_sel (addr_sel),
        .load_pc (load_pc),
        .reset_pc (reset_pc),
        .load_addr (load_addr)
    );

    // instantiate datapath from lab 5
    datapath DP( .clk         (clk), // recall from Lab 4 that KEY0 is 1 when NOT pushed
    
                    //things, stuffs, and more
                    .mdata (read_data),
                    .sximm8 (sximm8),
                    .sximm5 (sximm5),
                    .PC (PC[7:0]),

                    // register operand fetch stage
                    .readnum     (readnum),
                    .vsel        (vsel),
                    .loada       (loada),
                    .loadb       (loadb),

                    // computation stage (sometimes called "execute")
                    .shift       (shift),
                    .asel        (asel),
                    .bsel        (bsel),
                    .ALUop       (ALUop),
                    .loadc       (loadc),
                    .loads       (loads),

                    // set when "writing back" to register file
                    .writenum    (writenum),
                    .write       (write),  

                    // outputs
                    .C (write_data),
                    .status_out ({Z, V, N})
                );

endmodule

module instruction_decoder(from_reg, nsel, opcode, op, ALUop, sximm5, sximm8, shift, readnum, writenum);
    input [15:0] from_reg;
    input [2:0] nsel;

    output [2:0] opcode;
    output [1:0] op;
    output [1:0] ALUop;
    output [15:0] sximm5;
    output [15:0] sximm8;
    output [1:0] shift;
    output [2:0] readnum;
    output [2:0] writenum;

    wire [4:0] imm5;
    wire [7:0] imm8;
    wire [2:0] Rn, Rd, Rm;

    // assign wires according to description in lab figure 8
    assign opcode = from_reg[15:13];
    assign op = from_reg[12:11];
    assign ALUop = from_reg[12:11];
    assign imm5 = from_reg[4:0];
    assign imm8 = from_reg[7:0];
    assign shift = opcode == 3'b100 ? 2'b00 : from_reg[4:3]; //if we are STRing, shift is 00
    assign writenum = readnum;
    assign {Rn, Rd, Rm} = {from_reg[10:8], from_reg[7:5], from_reg[2:0]};

    // sign extend imm5 and imm8 accordingly with sign_extension module
    sign_extend #(5,16) sign_extend_5to16(imm5, sximm5);
    sign_extend #(8, 16) sign_extend_8to16(imm8, sximm8);

    // mux to select which register to read from
    mux3 #(3) reg_mux(Rn, Rd, Rm, nsel, readnum);


endmodule

module state_machine(s, reset, //cpu input
clk,
 opcode, op, nsel, //to/from instructional decoder
 vsel, loada, loadb, loadc, loads, asel, bsel, write, //these go to datapath
 load_ir, mem_cmd, addr_sel, load_pc, reset_pc, load_addr,
    w //cpu output
);
    input clk;
    input s, reset;
    input [2:0] opcode;
    input [1:0] op;
    
    output reg load_ir, addr_sel, load_pc, reset_pc, load_addr;
    output reg [1:0] mem_cmd;

    output reg [2:0] nsel;
    output reg w;

    output reg [3:0] vsel;
    output reg loada, loadb, loadc, loads, asel, bsel, write;

    reg [5:0] state;
    reg [13:0] next; // {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
    reg [6:0] next2; // {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}

    // assign outputs based on the output of state machine 
    assign {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write} = next;
    assign {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr} = next2;

    //state transitions
    always_ff @(posedge clk) begin
        if (reset)
            state = `S_RST;
        else begin
            case (state)
                `S_RST: state = `S_IF1;

                `S_IF1: state = `S_IF2;

                `S_IF2: state = `S_UPC;

                `S_UPC : begin
                    // move from WAIT only if s 
                    //if (s) begin
                        case (opcode)

                            //if opcode goes towards mov instructions:
                            `OPCODE_MOV: begin
                                case(op)
                                    `MOV_IMM: state = `S_MOV_IMM;
                                    `MOV_REG: state = `S_MOV_1;
                                    default: state = 6'bxxxxxx;
                                endcase
                            end

                            //if opcode goes towards alu instructions:
                            `OPCODE_ALU: begin
                                case(op)
                                    `ALU_ADD: state = `S_ADD_1;
                                    `ALU_CMP: state = `S_CMP_1;
                                    `ALU_AND: state = `S_AND_1;
                                    `ALU_MVN: state = `S_MVN_1;
                                    default: state = 6'bxxxxxx;
                                endcase
                            end

                            `OPCODE_LDR: state = op == 2'b00 ? `S_LDR1 : {6{1'bx}};
                        
                            `OPCODE_STR: state = op == 2'b00 ? `S_STR1 : {6{1'bx}};

                            `OPCODE_HALT: state = `S_HALT;

                            default: state = 6'bxxxxxx;
                        endcase
                    //end 
                end

                // rest of the state changes just go to the next state in the sequence, or go to WAIT if 
                // we just finished the last step of an instruction

                `S_MOV_IMM: state = `S_IF1;

                `S_MOV_1: state = `S_MOV_2;
                `S_MOV_2: state = `S_MOV_3;
                `S_MOV_3: state = `S_IF1;

                `S_ADD_1: state = `S_ADD_2;
                `S_ADD_2: state = `S_ADD_3;
                `S_ADD_3: state = `S_ADD_4;
                `S_ADD_4: state = `S_IF1;

                `S_CMP_1: state = `S_CMP_2;
                `S_CMP_2: state = `S_CMP_3;
                `S_CMP_3: state = `S_IF1;

                `S_AND_1: state = `S_AND_2;
                `S_AND_2: state = `S_AND_3;
                `S_AND_3: state = `S_AND_4;
                `S_AND_4: state = `S_IF1;

                `S_MVN_1: state = `S_MVN_2;
                `S_MVN_2: state = `S_MVN_3;
                `S_MVN_3: state = `S_IF1;

                `S_LDR1: state = `S_LDR2;
                `S_LDR2: state = `S_LDR3;
                `S_LDR3: state = `S_LDR4;
                `S_LDR4: state = `S_LDR5;
                `S_LDR5: state = `S_IF1;

                `S_STR1: state = `S_STR2;
                `S_STR2: state = `S_STR3;
                `S_STR3: state = `S_STR4;
                `S_STR4: state = `S_STR5;
                `S_STR5: state = `S_STR6;
                `S_STR6: state = `S_IF1;

                `S_HALT: state = `S_HALT;

                default: state = 6'bxxxxxx;
            endcase
        
        end
    end


    //state output
    always_comb begin
        next = {14{1'b0}};
        next2 = {7{1'b0}};
        w = 0;

        // change state machine outputs based off of current state 
        case (state)
            `S_RST: next2 = {1'b0, 1'b0, 1'b1, 1'b1, `MNONE, 1'b0};

            //              {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
            `S_IF1: next2 = {1'b0, 1'b1, 1'b0, 1'b0, `MREAD, 1'b0};

            `S_IF2: next2 = {1'b1, 1'b1, 1'b0, 1'b0, `MREAD, 1'b0};

            `S_UPC: next2 = {1'b0, 1'b0, 1'b1, 1'b0, `MNONE, 1'b0};

            // write = 1
            `S_MOV_IMM: next = {`NSEL_RN, `VSEL_IMM, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; 

            // loadb = 1
            `S_MOV_1: next = {`NSEL_RM, 4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // loadc = 1, asel = 1, bsel = 0
            `S_MOV_2: next = {3'b000, 4'b0000, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0};

            // write = 1
            `S_MOV_3: next = {`NSEL_RD, `VSEL_C, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; 

            // loadb = 1
            `S_ADD_1: next = {`NSEL_RM, 4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // loada = 1
            `S_ADD_2: next = {`NSEL_RN, 4'b0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // loadc = 1, asel = 0, bsel = 0
            `S_ADD_3: next = {3'b000, 4'b0000, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // write = 1
            `S_ADD_4: next = {`NSEL_RD, `VSEL_C, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; 

            // loadb = 1
            `S_CMP_1: next = {`NSEL_RM, 4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // loada = 1
            `S_CMP_2: next = {`NSEL_RN, 4'b0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // loads = 1, asel = 0, bsel = 0
            `S_CMP_3: next = {3'b000, 4'b0000, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0}; 

            // loadb = 1
            `S_AND_1: next = {`NSEL_RM, 4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};

            // loada = 1
            `S_AND_2: next = {`NSEL_RN, 4'b0000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // loadc = 1, asel = 0, bsel = 0
            `S_AND_3: next = {3'b000, 4'b0000, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // write = 1
            `S_AND_4: next = {`NSEL_RD, `VSEL_C, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; 

            // loadb = 1
            `S_MVN_1: next = {`NSEL_RM, 4'b0000, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; 

            // loadc = 1, asel = 1, bsel = 0
            `S_MVN_2: next = {3'b000, 4'b0000, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0}; 

            // write = 1
            `S_MVN_3: next = {`NSEL_RD, `VSEL_C, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; 

            //load Rn into A
            `S_LDR1: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RN, `VSEL_MDATA, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b1, 1'b0, 1'b0, `MREAD, 1'b0};
            end

            //add A to sximm5 (bsel = 1), load into C
            //bsel = 1, loadc = 1
            `S_LDR2: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RN, `VSEL_MDATA, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b0};
            end

            //load C into data address reg
            //load_addr = 1
            `S_LDR3: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RN, `VSEL_MDATA, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b1};
            end

            //sets up connections to make a request to access memory at ddress Rn+sximm5
            //addr_sel = 0
            `S_LDR4: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RD, `VSEL_MDATA, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b0};
            end

            //load the memory value into Rd
            `S_LDR5: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RD, `VSEL_MDATA, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b0};
            end

            //loada = 1, addr_sel = 1
            `S_STR1: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RN, `VSEL_MDATA, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b1, 1'b0, 1'b0, `MREAD, 1'b0};
            end
            
            // bsel = 1
            `S_STR2: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RN, `VSEL_MDATA, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b0};
            end

            // load_addr = 1, addr_sel = 0
            `S_STR3: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RN, `VSEL_MDATA, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b1};
            end

            //loadb = 1
            `S_STR4: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RD, `VSEL_MDATA, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b0};
            end


            //loadc = 1, asel = 1
            `S_STR5: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RD, `VSEL_MDATA, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MREAD, 1'b0};
            end

            // write mode for memory
            `S_STR6: begin
                //     {nsel, vsel, loada, loadb, loadc, loads, asel, bsel, write}
                next = {`NSEL_RD, `VSEL_MDATA, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
                //      {load_ir, addr_sel, load_pc, reset_pc, mem_cmd, load_addr}
                next2 = {1'b0, 1'b0, 1'b0, 1'b0, `MWRITE, 1'b0};
            end


            //no need for default because we already have default values for next and next2 (in case we forget)

        endcase
        
    end

endmodule

// definition of sign_extension module
module sign_extend(in, out);
    parameter n = 5;
    parameter m = 16;

    input [n - 1 : 0] in;
    output reg [m - 1 : 0] out;

    // extend sign based off of most significant bit of the input
    always_comb begin
        if (in[n - 1] == 0) 
            out = {{(m - n){1'b0}}, in};
        else 
            out = {{(m - n){1'b1}}, in};
    end

endmodule

module mux3(in0, in1, in2, s, out);
    parameter n = 1;
    input [n-1: 0] in0;
    input [n-1: 0] in1;
    input [n-1: 0] in2;
    input [2:0] s;
    output reg [n-1: 0] out;

    //if select is 0, then out should be in0 (the input marked to be outputted when select is set to 0), 
    //otherwise select should be 1 and output is in1 (the input marked to be outputted when select is set to 1)
    always_comb begin
        case(s) 
            3'b001: out = in0;
            3'b010: out = in1;
            3'b100: out = in2;
            default: out = {n{1'bx}};
        endcase
    end
endmodule
