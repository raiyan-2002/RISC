module shifter(in,shift,sout);
    input [15:0] in;
    input [1:0] shift;
    output reg [15:0] sout;
    
    always_comb begin
        // shift according to shift input 
        case(shift)
            //if shift operation code is 00, then no shift
            2'b00: sout = in;

            //if shift operation is 01, shift one bit to the left
            2'b01: sout = in << 1;

            //if shift operation is 10, shift one bit to the right
            2'b10: sout = in >> 1;

            //if shift operation is 11, shift one bit to the right, 
            //and set output's most significant bit (output[15]) to be equal to input[15]
            2'b11: begin
                sout = in >> 1;
                sout[15] = in[15];
            end  
        endcase
    end
endmodule
