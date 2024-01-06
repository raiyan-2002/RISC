// WARNING: This is NOT the autograder that will be used mark you.  
// Passing the checks in this file does NOT (in any way) guarantee you 
// will not lose marks when your code is run through the actual autograder.  
// You are responsible for designing your own test benches to verify you 
// match the specification given in the lab handout.

module cpu_tb;
    //IMPORTANT FOR WHOM IT MAY CONCERN: 
    //this testbench was NOT copied from autograder
    reg [3:0] KEY;
    reg [9:0] SW;
    wire [9:0] LEDR; 
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    reg err;

    lab7_top #("calc.txt") DUT(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);

    wire [8:0] PC;
    assign PC = DUT.CPU.PC;
    wire [15:0] mdata;
    assign mdata = DUT.CPU.mdata;
    wire [8:0] next_pc;
    assign next_pc = DUT.CPU.next_pc;
    wire load_ir;
    assign load_ir = DUT.CPU.load_ir;
    wire load_addr;
    assign load_addr = DUT.CPU.load_addr;
    wire [8:0] data_addr;
    assign data_addr = DUT.CPU.data_addr;
    wire [5:0] state;
    assign state = DUT.CPU.FSM.state;
    wire load_pc, reset_pc, addr_sel;
    assign load_pc = DUT.CPU.load_pc;
    assign reset_pc = DUT.CPU.reset_pc;
    assign addr_sel = DUT.CPU.addr_sel;
    wire [8:0] pcplus;
    assign pcplus = DUT.CPU.pcplus;
    wire [2:0] opcode;
    wire [1:0] op;
    assign opcode = DUT.CPU.opcode;
    assign op = DUT.CPU.op;
    wire[1:0] mem_cmd;
    wire[8:0] mem_addr;
    wire[15:0] read_data, write_data;
    assign mem_cmd = DUT.mem_cmd;
    assign mem_addr = DUT.mem_addr;
    assign read_data = DUT.read_data;
    assign write_data = DUT.write_data;

    wire write_top, write_bottom;
    wire dout_enable, dout_top,dout_bottom;
    wire [15:0] din,dout;
    reg sw_enable, ledr_enable;
    wire [15:0] floating_out;
    assign write_top = DUT.write_top;
    assign write_bottom = DUT.write_bottom;
    assign dout_enable = DUT.dout_enable;
    assign dout_top = DUT.dout_top;
    assign dout_bottom = DUT.dout_bottom;
    assign dout = DUT.dout;
    assign sw_enable = DUT.sw_enable;
    assign ledr_enable = DUT.ledr_enable;
    assign floating_out = DUT.floating_out;

    wire MEMwrite;
    assign MEMwrite = DUT.MEM.write;

    reg [15:0] mem [2**8-1:0];
    assign mem = DUT.MEM.mem;
    wire MEMdin = DUT.MEM.din;
    wire MEMdout = DUT.MEM.dout; 



    initial forever begin
        KEY[0] = 1; #5;
        KEY[0] = 0; #5;
    end

    initial begin
        err = 0;
        KEY[1] = 1'b0; // reset asserted
        // check if program from Figure 6 in Lab 7 handout can be found loaded in memory
        // if (DUT.MEM.mem[0] !== 16'b1101000000000101) begin err = 1; $display("FAILED: mem[0] wrong; please set data.txt using Figure 6"); $stop; end
        // if (DUT.MEM.mem[1] !== 16'b0110000000100000) begin err = 1; $display("FAILED: mem[1] wrong; please set data.txt using Figure 6"); $stop; end
        // if (DUT.MEM.mem[2] !== 16'b1101001000000110) begin err = 1; $display("FAILED: mem[2] wrong; please set data.txt using Figure 6"); $stop; end
        // if (DUT.MEM.mem[3] !== 16'b1000001000100000) begin err = 1; $display("FAILED: mem[3] wrong; please set data.txt using Figure 6"); $stop; end
        // if (DUT.MEM.mem[4] !== 16'b1110000000000000) begin err = 1; $display("FAILED: mem[4] wrong; please set data.txt using Figure 6"); $stop; end
        // if (DUT.MEM.mem[5] !== 16'b1010101111001101) begin err = 1; $display("FAILED: mem[4] wrong; please set data.txt using Figure 6"); $stop; end

        @(posedge KEY[0]); // wait until next falling edge of clock

        KEY[1] = 1'b1; // reset de-asserted, PC still undefined if as in Figure 4

        #10; // waiting for RST state to cause reset of PC

        // NOTE: your program counter register output should be called PC and be inside a module with instance name CPU
        if (DUT.CPU.PC !== 9'b0) begin err = 1; $display("FAILED: PC is not reset to zero."); $stop; end


        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 1 *before* executing MOV R0, X

        if (DUT.CPU.PC !== 9'h1) begin err = 1; $display("FAILED: PC should be 1."); $stop; end
        //


        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 2 *after* executing MOV R0, X

        if (DUT.CPU.PC !== 9'h2) begin err = 1; $display("FAILED: PC should be 2."); $stop; end
        if (DUT.CPU.DP.REGFILE.R0 !== 16'd13) begin err = 1; $display("FAILED: R0 should be 13."); $stop; end  // because MOV R0, X should have occurred
        //check instruction line 1
        

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 3 *after* executing LDR R1, [R0]

        if (DUT.CPU.PC !== 9'h3) begin err = 1; $display("FAILED: PC should be 3."); $stop; end
        if (DUT.CPU.DP.REGFILE.R1 !== 16'd14) begin err = 1; $display("FAILED: R1 should be 14. Looks like your LDR isn't working."); $stop; end
        //check instruction line 2
        
        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 4 *after* executing MOV R2, Y

        if (DUT.CPU.PC !== 9'h4) begin err = 1; $display("FAILED: PC should be 4."); $stop; end
        if (DUT.CPU.DP.REGFILE.R0 !== 16'h0140) begin err = 1; $display("FAILED: R0 isn't working."); $stop; end
        // check instruction line 3

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
    
        if (DUT.CPU.PC !== 9'h5) begin err = 1; $display("FAILED: PC should be 5."); $stop; end
        if (DUT.CPU.DP.REGFILE.R1 !== 16'h0100) begin err = 1; $display("FAILED: R1 isn't working."); $stop; end
        // check instruction line 4

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'h6) begin err = 1; $display("FAILED: PC should be 6."); $stop; end
        if (DUT.CPU.DP.REGFILE.R2 !== 16'h1) begin err = 1; $display("FAILED: R2 isn't working."); $stop; end
        // check instruction line 5

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'h7) begin err = 1; $display("FAILED: PC should be 7."); $stop; end
        if (LEDR[7:0] !== 8'b1) begin err = 1; $display("FAILED: R1 isn't working."); $stop; end
        // check instruction line 6

        SW[7:0] = 8'd17;

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'h8) begin err = 1; $display("FAILED: PC should be 8."); $stop; end
        if (DUT.CPU.DP.REGFILE.R3 !== 16'd17) begin err = 1; $display("FAILED: Looks like your R3 isn't working."); $stop; end
        // check instruction line 7

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'h9) begin err = 1; $display("FAILED: PC should be 9."); $stop; end
        if (DUT.CPU.DP.REGFILE.R2 !== 16'd2) begin err = 1; $display("FAILED: Looks like your R2 isn't working."); $stop; end
        // check instruction line 8

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'ha) begin err = 1; $display("FAILED: PC should be 10."); $stop; end
        if (LEDR[7:0] !== 8'd2) begin err = 1; $display("FAILED: Looks like your R2 isn't working."); $stop; end
        // check instruction line 9

        SW[7:0] = 8'd19;

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'hb) begin err = 1; $display("FAILED: PC should be 11."); $stop; end
        if (DUT.CPU.DP.REGFILE.R4 !== 8'd19) begin err = 1; $display("FAILED: Looks like your R4 isn't working."); $stop; end
        // check instruction line 10

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'hc) begin err = 1; $display("FAILED: PC should be 12."); $stop; end
        if (DUT.CPU.DP.REGFILE.R5 !== 8'd36) begin err = 1; $display("FAILED: Looks like your R5 isn't working."); $stop; end
        // check instruction line 11

        @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
        if (DUT.CPU.PC !== 9'hd) begin err = 1; $display("FAILED: PC should be 13."); $stop; end
        if (LEDR[7:0] !== 8'd36) begin err = 1; $display("FAILED: Looks like your LEDR isn't working."); $stop; end
        // check instruction line 12

        if (~err) $display("INTERFACE OK");
        $stop;
    end
endmodule

// //state encoding
// `define S_WAIT 3'b000
// `define S_IMM 3'b001
// `define S_MOV 3'b010
// `define S_ADD 3'b011
// `define S_CMP 3'b100
// `define S_AND 3'b101
// `define S_MVN 3'b110

// module cpu_tb();

//     reg[15:0] in;
//     reg load, s, reset, clk, err;
    
    
//     wire w, N, V, Z;
//     wire [15:0] out;

//     cpu lab6(
//         .clk (clk),
//         .reset (reset),
//         .s (s),
//         .load (load),
//         .in (in),
//         .out (out),
//         .N (N),
//         .V (V),
//         .Z (Z),
//         .w (w)
//     );

//     reg [15:0] neg = 16'b1111_1111_1111_0101;

//     initial begin
//         forever begin
//             clk = 0; #5;
//             clk = 1; #5;
//         end
//     end

//     initial begin
//         //initialize
//         err = 0;
//         reset = 1;
//         s = 0;
//         load = 0;
//         in = 16'b0;
//         #10;
//         reset = 0;
//         #10;
        
//         in = 16'b110_10_000_000_00_111; //MOV R0, #7
//         load = 1;
//         #10; // loads instruction
//         load = 0;
//         s = 1;
//         #10; //starts fsm
//         s = 0;
//         @(posedge w); //wait for w to turn high, signalling the completion and back to w
//         while (PC ==)
//         #10
//         if (lab6.DP.REGFILE.R0 != 7) begin
//             err = 1; 
//             $display("FAILED: MOV R0, #7  -- Regs[R0]=%h is wrong, expected %h", lab6.DP.REGFILE.R0, 7); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b110_10_001_000_00_010; //MOV R1, #2
//         load = 1;
//         #10; //loads instruction
//         load = 0;
//         s = 1;//#
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R1 != 2) begin
//             err = 1; 
//             $display("FAILED: MOV R1, #2  -- Regs[R1]=%h is wrong, expected %h", lab6.DP.REGFILE.R1, 2); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_00_000_010_00_001; //ADD R2, R0, R1;
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R2 != 9) begin
//             err = 1; 
//             $display("FAILED: ADD R2, R0, R1  -- Regs[R2]=%h is wrong, expected %h", lab6.DP.REGFILE.R2, 9); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_01_000_000_00_001; //CMP R0, R1;
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if ({N, V, Z} != 3'b000) begin
//             err = 1; 
//             $display("FAILED: CMP R0, R1  -- NVZ=%b is wrong, expected %b", {N,V,Z}, 3'b000); 
//             $stop; 
//         end

//         @(negedge clk);

//         in = 16'b110_10_001_00000111; //MOV R1, #7
//         load = 1;
//         #10; //loads instruction
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w); //w is high when fsm is back
//         #10;
//         if (lab6.DP.REGFILE.R1 != 7) begin
//             err = 1; 
//             $display("FAILED: MOV R1, #7  -- Regs[R1]=%h is wrong, expected %h", lab6.DP.REGFILE.R1, 7); 
//             $stop; 
//         end
//         @(negedge clk);


//         in = 16'b101_01_000_000_00_001; //CMP R0, R1;
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if ({N, V, Z} != 3'b001) begin
//             err = 1; 
//             $display("FAILED: CMP R0, R1  -- NVZ=%b is wrong, expected %b", {N,V,Z}, 3'b001); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b110_10_000_00001010; // MOV R0, #10;
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R0 != 10) begin
//             err = 1; 
//             $display("FAILED: MOV R0, #10  -- Regs[R]=%h is wrong, expected %h", lab6.DP.REGFILE.R0, 10); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b110_00_000_001_01_000; // MOV R1, R0, LSL #1
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R1 != 20) begin
//             err = 1; 
//             $display("FAILED: MOV R1, R0, LSL #1 -- Regs[R1]=%h is wrong, expected %h", lab6.DP.REGFILE.R1, 20); 
//             $stop; 
//         end
//         @(negedge clk);


//         in = 16'b110_00_000_010_10_001; // MOV R2, R1, LSR #1
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R2 != 10) begin
//             err = 1; 
//             $display("FAILED: MOV R2, R1, LSR #1; -- Regs[R2]=%h is wrong, expected %h", lab6.DP.REGFILE.R2, 10); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b110_00_000_011_00_010; // MOV R3, R2
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R3 != 10) begin
//             err = 1; 
//             $display("FAILED: MOV R3, R2 -- Regs[R3]=%h is wrong, expected %h", lab6.DP.REGFILE.R3, 10); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_10_010_100_00_011; // AND R4, R2, R3
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R4 != 10) begin
//             err = 1; 
//             $display("FAILED: AND R4, R2, R3 -- Regs[R4]=%h is wrong, expected %h", lab6.DP.REGFILE.R4, 10); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_10_010_100_00_001; // AND R4, R2, R1
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R4 != 0) begin
//             err = 1; 
//             $display("FAILED: AND R4, R2, R1 -- Regs[R4]=%h is wrong, expected %h", lab6.DP.REGFILE.R4, 0); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_11_000_100_00_010; // MVN R4, R2
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R4 != neg) begin
//             err = 1; 
//             $display("FAILED: MVN R4, R2 -- Regs[R4]=%h is wrong, expected %h", lab6.DP.REGFILE.R4, neg); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_11_000_101_01_010; // MVN R5, R2, LSR #1
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         neg = 16'b1111_1111_1110_1011;
//         if (lab6.DP.REGFILE.R5 != neg) begin
//             err = 1; 
//             $display("FAILED: MVN R5, R2, LSR #1 -- Regs[R5]=%h is wrong, expected %h", lab6.DP.REGFILE.R5, neg); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b110_10_000_0000_0111; // MOV R0, #7
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R0 != 7) begin
//             err = 1; 
//             $display("FAILED: MOV R0, #7 -- Regs[R0]=%h is wrong, expected %h", lab6.DP.REGFILE.R0, 7); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b110_10_001_0000_0010; // MOV R1, #2
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R1 != 2) begin
//             err = 1; 
//             $display("FAILED: MOV R1, #2 -- Regs[R1]=%h is wrong, expected %h", lab6.DP.REGFILE.R1, 2); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_10_000_110_00_001; // AND R6, R0, R1
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R6 != 2) begin
//             err = 1; 
//             $display("FAILED: AND R6, R0, R1 -- Regs[R6]=%b is wrong, expected %b", lab6.DP.REGFILE.R6, 2); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_10_000_110_01_001; // AND R6, R0, R1, LSL #1
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R6 != 4) begin
//             err = 1; 
//             $display("FAILED: AND R6, R0, R1, LSL #1 -- Regs[R6]=%b is wrong, expected %b", lab6.DP.REGFILE.R6, 4); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b101_10_000_110_10_001; // AND R6, R0, R1, LSR #1
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R6 != 1) begin
//             err = 1; 
//             $display("FAILED: AND R6, R0, R1, LSR #1 -- Regs[R6]=%b is wrong, expected %b", lab6.DP.REGFILE.R6, 1); 
//             $stop; 
//         end
//         @(negedge clk);

//         in = 16'b110_10_110_0000_1100; // MOV R6, #12
//         load = 1;
//         #10;
//         load = 0;
//         s = 1;
//         #10;
//         s = 0;
//         @(posedge w);
//         #10;
//         if (lab6.DP.REGFILE.R6 != 12) begin
//             err = 1; 
//             $display("FAILED: MOV R6, #12 -- Regs[R6]=%h is wrong, expected %h", lab6.DP.REGFILE.R6, 12); 
//             $stop; 
//         end
//         @(negedge clk);


//         $display("passed");
//         $stop; //maybe remove this later ig



//     end

    

// endmodule