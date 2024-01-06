//mem_cmd
`define MNONE 2'b00
`define MREAD 2'b01
`define MWRITE 2'b10

//sseg numbers
`define number0 7'b1000000
`define number1 7'b1111001
`define number2 7'b0100100
`define number3 7'b0110000
`define number4 7'b0011001
`define number5 7'b0010010
`define number6 7'b0000010
`define number7 7'b1111000
`define number8 7'b0000000
`define number9 7'b0010000
`define numberA 7'b0001000
`define numberB 7'b0000011
`define numberC 7'b1000110
`define numberD 7'b0100001
`define numberE 7'b0000110
`define numberF 7'b0001110

// module definition for tri state inverter 
module vtri(in, enable, out);
    parameter n = 1;
    input [n-1:0] in;
    input enable;
    output [n-1:0] out;
    // assign output based on enable signal
    assign out = enable == 1'b1 ? in : {n{1'bz}};
endmodule

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    // declare inputs and outputs
    parameter filename = "data.txt";
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // declare wires for cpu and memory paths
    wire [8:0] PC;
    wire[1:0] mem_cmd;
    wire[8:0] mem_addr;
    wire[15:0] read_data, write_data;
    wire clk,write,reset;
    wire write_top,write_bottom;
    wire dout_enable, dout_top,dout_bottom;
    wire [15:0] dout;
    reg sw_enable, ledr_enable;
    wire [15:0] floating_out;

    // invert key input from board
    assign clk = ~KEY[0];
    assign reset = ~KEY[1];

    // assign valuse to wires between cpu and memotyr paths 
    assign write_top = mem_cmd == `MWRITE ? 1 : 0;
    assign dout_top = mem_cmd == `MREAD ? 1 : 0;
    assign write_bottom = mem_addr[8:8] == 1'b0 ? 1 : 0;
    assign dout_bottom = write_bottom;
    assign write = write_top & write_bottom;
    assign dout_enable = dout_top & dout_bottom;

    // instantiate sseg modules to display PC
    sseg SSEG5(PC[7:4], HEX5);
    sseg SSEG4(PC[3:0], HEX4);
    assign HEX3 = 7'b1111111;
    sseg SSEG2({3'b000, mem_addr[8]}, HEX2);
    sseg SSEG1(mem_addr[7:4], HEX1);
    sseg SSEG0(mem_addr[3:0], HEX0);

    // instantiate tri-state inverter for dout
    vtri #(16) DOUT_TRI(dout, dout_enable, read_data);

    // instantiate paramterized memory module
    RAM #(16, 8, filename) MEM(clk, mem_addr[7:0],mem_addr[7:0],write, write_data,dout);

    // instantaite ram module 
    cpu CPU(.clk (clk),
            .reset (reset),
            .s (s),
            .load (load),
            .in ({16{1'b0}}),
            .out (floating_out),
            .N (N),
            .V (V),
            .Z (Z),
            .w (w),
            .mem_cmd (mem_cmd),
            .mem_addr (mem_addr),
            .read_data (read_data),
            .write_data (write_data),
            .PC(PC)
            );

    //left design this circuit in figure 7 (for switches)
    always_comb begin
        sw_enable = 1'b0;
        if (mem_cmd == `MREAD) begin
            if (mem_addr == 9'h140) 
                sw_enable = 1'b1;
            
        end
    end

    //right design this circuit in figure 7 (for leds)
    always_comb begin
        ledr_enable = 1'b0;
        if (mem_cmd == `MWRITE) begin
            if (mem_addr == 9'h100) 
                ledr_enable = 1'b1;
        end
    end

    // instantiate tri-state inverters for switch inputs
    vtri #(16) SW_TRI({8'h00, SW[7:0]}, sw_enable, read_data);
    // instantiate load enabled led register 
    LE_reg #(8) LED_REG(write_data[7:0], ledr_enable, clk, LEDR[7:0]);
endmodule

module sseg(in,segs);
  input [3:0] in;
  output reg [6:0] segs;

  // NOTE: The code for sseg below is not complete: You can use your code from
  // Lab4 to fill this in or code from someone else's Lab4.  
  //
  // IMPORTANT:  If you *do* use someone else's Lab4 code for the seven
  // segment display you *need* to state the following three things in
  // a file README.txt that you submit with handin along with this code: 
  //
  //   1.  First and last name of student providing code
  //   2.  Student number of student providing code
  //   3.  Date and time that student provided you their code
  //
  // You must also (obviously!) have the other student's permission to use
  // their code.
  //
  // To do otherwise is considered plagiarism.
  //
  // One bit per segment. On the DE1-SoC a HEX segment is illuminated when
  // the input bit is 0. Bits 6543210 correspond to:
  //
  //    0000
  //   5    1
  //   5    1
  //    6666
  //   4    2
  //   4    2
  //    3333
  //
  // Decimal value | Hexadecimal symbol to render on (one) HEX display
  //             0 | 0
  //             1 | 1
  //             2 | 2
  //             3 | 3
  //             4 | 4
  //             5 | 5
  //             6 | 6
  //             7 | 7
  //             8 | 8
  //             9 | 9
  //            10 | A
  //            11 | b
  //            12 | C
  //            13 | d
  //            14 | E
  //            15 | F

    //segment display combinations
  always_comb begin
    case(in)
      0: segs = `number0;
      1: segs = `number1;
      2: segs = `number2;
      3: segs = `number3;
      4: segs = `number4;
      5: segs = `number5;
      6: segs = `number6;
      7: segs = `number7;
      8: segs = `number8;
      9: segs = `number9;
      10: segs = `numberA;
      11: segs = `numberB;
      12: segs = `numberC;
      13: segs = `numberD;
      14: segs = `numberE;
      15: segs = `numberF;
    endcase
  end

endmodule