`define VSEL_C 4'b1000
`define VSEL_SXIMM8 4'b0010

module datapath_tb();

        reg clk;
        reg [15:0] sximm8, sximm5;
        reg write, loada, loadb, asel, bsel, loadc, loads;
        reg [3:0] vsel;
        reg [2:0] readnum, writenum;
        reg [1:0] shift, ALUop;

        reg [7:0] PC;
        reg [15:0] mdata;

        wire [15:0] datapath_out;
        wire Z, V, N;

        reg err;

        // instantaite datapath DUT
        datapath DUT( .clk         (clk), // recall from Lab 4 that KEY0 is 1 when NOT pushed
    
                    //things, stuffs, and more
                    .mdata (mdata),
                    .sximm8 (sximm8),
                    .sximm5 (sximm5),
                    .PC (PC),

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
                    .C (datapath_out),
                    .status_out ({Z, V, N})
                );

        wire [15:0] R0 = DUT.REGFILE.R0;
        wire [15:0] R1 = DUT.REGFILE.R1;
        wire [15:0] R2 = DUT.REGFILE.R2;
        wire [15:0] R3 = DUT.REGFILE.R3;
        wire [15:0] R4 = DUT.REGFILE.R4;
        wire [15:0] R5 = DUT.REGFILE.R5;
        wire [15:0] R6 = DUT.REGFILE.R6;
        wire [15:0] R7 = DUT.REGFILE.R7;

        // loop for clock cycles
        initial forever begin
            clk = 0; #5;
            clk = 1; #5;
        end

        // The rest of the inputs to our design under test (datapath) are defined 
        // below.
        initial begin
            // Plot err in your waveform to find out when first error occurs
            err = 0;

            PC = 8'b0000_0000;
            mdata = 16'b0000_0000_0000_0000;
            
            // IMPORTANT: Set all control inputs to something at time=0 so not "undefined"
            sximm8 = 0;
            write = 0; vsel=0; loada=0; loadb=0; asel=0; bsel=0; loadc=0; loads=0;
            readnum = 0; writenum=0;
            shift = 0; ALUop=0;

            // Now, wait for clk -- clock rises at time = 5, 15, 25, 35, ...  Thus, at 
            // time = 10 the clock is NOT rising so it is safe to change the inputs.
            #10; 

            ////////////////////////////////////////////////////////////

            // First 3 suggestions from lab 5 handout
            // MOV R0, #7
            // MOV R1, #2
            // ADD R2, R1, R0, LSL #1

            ////////////////////////////////////////////////////////////

            // MOV R0, #7
            sximm8 = 16'h7; // h for hexadecimal
            writenum = 3'd0;
            write = 1'b1;
            vsel = `VSEL_SXIMM8;
            #10; // wait for clock 
            write = 0;

            // the following checks if MOV was executed correctly
            if (R0 !== 16'h7) begin
            err = 1; 
            $display("FAILED: MOV R0, #7 wrong -- Regs[R0]=%h is wrong, expected %h", R0, 16'h7); 
            $stop; 
            end

            ////////////////////////////////////////////////////////////

            // MOV R1, #2
            sximm8 = 16'h2;
            writenum = 3'd1;
            write = 1'b1;
            vsel = `VSEL_SXIMM8;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            // the following checks if MOV was executed correctly
            if (R1 !== 16'h2) begin 
            err = 1; 
            $display("FAILED: MOV R1, #2 wrong -- Regs[R1]=%h is wrong, expected %h", R1, 16'h2); 
            $stop; 
            end

            ////////////////////////////////////////////////////////////

            // ADD R2,R1, R0, LSL #1
            // step 1 - load contents of R0 into B reg
            readnum = 3'd0; 
            loadb = 1'b1;
            #10; // wait for clock
            loadb = 1'b0; // done loading B, set loadb to zero so don't overwrite A 

            // step 2 - load contents of R1 into A reg 
            readnum = 3'd1; 
            loada = 1'b1;
            #10; // wait for clock
            loada = 1'b0;

            //step 3 - left shift shift the contents of B reg by 1 and add, store in C reg
            shift = 2'b01;
            asel = 1'b0;
            bsel = 1'b0;
            ALUop = 2'b00;
            loadc = 1'b1;
            loads = 1'b1;
            #10; // wait for clock

            loadc = 1'b0;
            loads = 1'b0;

            // step 4 - store contents of C  reg into R2
            write = 1'b1;
            writenum = 3'd2;
            vsel = `VSEL_C;
            #10;
            write = 0;

            // display check results accordingly
            if (R2 !== 16'h10) begin 
                err = 1; 
                $display("FAILED: ADD R2,R1, R0, LSL #1 -- Regs[R2]=%h is wrong, expected %h", R2, 16'h10); 
                $stop; 
            end

            if (datapath_out !== 16'h10) begin 
                err = 1; 
                $display("FAILED: ADD R2,R1, R0, LSL #1 -- datapath_out=%h is wrong, expected %h", R2, 16'h10); 
                $stop;   
            end

            if (Z !== 1'b0) begin
                err = 1; 
                $display("FAILED: ADD R2,R1, R0, LSL #1 -- Z=%b is wrong, expected %b", Z, 1'b0); 
                $stop; 
            end

            ////////////////////////////////////////////////////////////

            // New 3 instructions
            // MOV R3, R2
            // MOV R4, #16
            // SUB R5, R4, R3

            ////////////////////////////////////////////////////////////

            // MOV R3, R2

            // step 1 - load R2 into B reg
            readnum = 2;
            loadb = 1;
            #10;
            loadb = 0;

            // step 2 - add 0 + R2, store in C reg
            shift = 2'b00;
            ALUop = 2'b00;
            asel = 1;
            bsel = 0;
            loadc = 1;
            #10;
            loadc = 0;

            // step 3 - store C reg value into R3
            writenum = 3'd3;
            write = 1;
            vsel = `VSEL_C;
            #10;
            write = 0;

            // display check results accordingly
            if (R3 !== 16'h10) begin
                err = 1; 
                $display("FAILED: MOV R3, R2 -- R3=%h is wrong, expected %h", R3, 16'h10); 
                $stop; 
            end

            ////////////////////////////////////////////////////////////

            // MOV R4, #16

            sximm8 = 16'h10;
            writenum = 3'd4;
            write = 1'b1;
            vsel = `VSEL_SXIMM8;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            // the following checks if MOV was executed correctly
            if (R4 !== 16'h10) begin 
                err = 1; 
                $display("FAILED: MOV R4, #16 wrong -- Regs[R4]=%h is wrong, expected %h", R4, 16'h10); 
                $stop; 
            end

            ////////////////////////////////////////////////////////////

            // SUB R5, R4, R3

            // step 1 - load contents of R3 into B reg
            readnum = 3'd3; 
            loadb = 1'b1;
            #10; // wait for clock
            loadb = 1'b0; // done loading B, set loadb to zero so don't overwrite A 

            // step 2 - load contents of R4 into A reg 
            readnum = 3'd4; 
            loada = 1'b1;

            #10; // wait for clock
            loada = 1'b0;

            //step 3 - subtract contents of A reg and B reg
            shift = 2'b00;
            asel = 1'b0;
            bsel = 1'b0;
            ALUop = 2'b01;
            loadc = 1'b1;
            loads = 1'b1;
            #10; // wait for clock

            loadc = 1'b0;
            loads = 1'b0;

            // step 4 - store contents of C  reg into R5
            write = 1'b1;
            writenum = 3'd5;
            vsel = `VSEL_C;
            #10;
            write = 0;

            // display check results accordingly
            if (R5 !== 16'h0) begin 
                err = 1; 
                $display("FAILED: SUB R5, R4, R3 -- Regs[R5]=%h is wrong, expected %h", R5, 16'h0); 
                $stop; 
            end

            if (datapath_out !== 16'h0) begin 
                err = 1; 
                $display("FAILED: SUB R5, R4, R3 -- datapath_out=%h is wrong, expected %h", R5, 16'h0); 
                $stop; 
            end

            if (Z !== 1'b1) begin
                err = 1; 
                $display("FAILED: SUB R5, R4, R3 -- Z=%b is wrong, expected %b", Z, 1'b1); 
                $stop; 
            end

            ////////////////////////////////////////////////////////////

            // ADD R2,R0, R1, LSR #1
            // step 1 - load contents of R0 into A reg
            readnum = 3'd0; 
            loada = 1'b1;
            #10; // wait for clock
            loada = 1'b0; // done loading B, set loadb to zero so don't overwrite A 

            // step 2 - load contents of R1 into A reg 
            readnum = 3'd1; 
            loadb = 1'b1;
            #10; // wait for clock
            loadb = 1'b0;

            //step 3 - right shift shift the contents of B reg by 1 and add, store in C reg
            shift = 2'b10;
            asel = 1'b0;
            bsel = 1'b0;
            ALUop = 2'b00;
            loadc = 1'b1;
            loads = 1'b1;
            #10; // wait for clock

            loadc = 1'b0;
            loads = 1'b0;

            // step 4 - store contents of C  reg into R2
            write = 1'b1;
            writenum = 3'd2;
            vsel = `VSEL_C;
            #10;
            write = 0;

            
            // display check results accordingly
            if (R2 !== 16'h8) begin 
                err = 1; 
                $display("FAILED: ADD R2,R1, R0, LSR #1 -- Regs[R2]=%h is wrong, expected %h", R2, 16'h8); 
                $stop; 
            end

            if (datapath_out !== 16'h8) begin 
                err = 1; 
                $display("FAILED: ADD R2,R1, R0, LSR #1 -- datapath_out=%h is wrong, expected %h", R2, 16'h8); 
                $stop;   
            end

            if (Z !== 1'b0) begin
                err = 1; 
                $display("FAILED: ADD R2,R1, R0, LSR #1 -- Z=%b is wrong, expected %b", Z, 1'b0); 
                $stop; 
            end

            /////////
            //MOV R6, 16'b0000_0001_1111_1111
            //invert R6 then store it back into R6

            //load 16'b0000_0001_1111_1111 to R6
            sximm8 = 16'b0000_0001_1111_1111;
            writenum = 3'd6;
            write = 1'b1;
            vsel = `VSEL_SXIMM8;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            //load R6 to reg B
            readnum = 3'd6;
            loadb = 1;
            #10; //wait for clock
            loadb = 0;

            //make sure shift is 0
            shift = 2'b00;

            //use ALU to invert bits for R6
            ALUop = 2'b11;
            bsel = 0;
            loadc = 1;
            #10; //clock
            loadc = 0;

            // display check results accordingly
            if (datapath_out !==16'b1111_1110_0000_0000) begin
                err = 1; 
                $display("FAILED: invert R6 -- datapath_out=%b is wrong, expected %b", datapath_out, 16'b1111_1110_0000_0000); 
                $stop; 
            end

            //write the inverted R6 back into R6
            writenum = 3'd6;
            write = 1'b1;
            vsel = `VSEL_C;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            // display check results accordingly
            if (R6 !== 16'b1111_1110_0000_0000) begin 
                err = 1; 
                $display("FAILED: invert R6 -- Regs[R6]=%h is wrong, expected %h", R6, 16'b1111_1110_0000_0000); 
                $stop; 
            end
            //

            /////////
            //MOV R7, 16'b0001_1111_0000_0000
            //shift R7 using special shift, then store back into R7
            //shift R6 using special shift, then store back into R6
            //use the ALU to perform an AND operation between R7 and R6, store it into R0

            //load 16'b0001_1111_0000_0000 to R7
            sximm8 = 16'b0001_1111_0000_0000;
            writenum = 3'd7;
            write = 1'b1;
            vsel = `VSEL_SXIMM8;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            //load R7 to reg B
            readnum = 3'd7;
            loadb = 1;
            #10; //wait for clock
            loadb = 0;

            //use shifter to shift reg B, then pass through ALU without changing it by setting ALU to add mode and Ain to 0, 
            //and load into C
            shift = 2'b11;
            ALUop = 2'b00;
            asel = 1;
            loadc = 1;
            #10; //clock
            asel = 0;
            loadc = 0;
            shift = 2'b00; //reset shift

            // display check results accordingly
            if (datapath_out !==16'b0000_1111_1000_0000) begin
                err = 1; 
                $display("FAILED: special shift R7  -- datapath_out=%b is wrong, expected %b", datapath_out, 16'b0000_1111_1000_0000); 
                $stop; 
            end

            //store special shifted R7 back into R7
            
            writenum = 3'd7;
            write = 1'b1;
            vsel = `VSEL_C;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            // display check results accordingly
            if (R7 !==16'b0000_1111_1000_0000) begin
                err = 1; 
                $display("FAILED: special shift R7  -- R7=%b is wrong, expected %b", R7, 16'b0000_1111_1000_0000); 
                $stop; 
            end

            //now load R6 into B
            readnum = 3'd6;
            loadb = 1;
            #10; //wait for clock
            loadb = 0;

            //use shifter to shift reg B, then pass through ALU without changing it by setting ALU to add mode and Ain to 0, 
            //and load into C
            shift = 2'b11;
            ALUop = 2'b00;
            asel = 1;
            loadc = 1;
            #10; //clock
            asel = 0;
            loadc = 0;
            shift = 2'b00; //reset shift

            // display check results accordingly
            if (datapath_out !==16'b1111_1111_0000_0000) begin
                err = 1; 
                $display("FAILED: special shift R6  -- datapath_out=%b is wrong, expected %b", datapath_out, 16'b1111_1111_0000_0000); 
                $stop; 
            end

            //store special shifted R6 back into R6
            
            writenum = 3'd6;
            write = 1'b1;
            vsel = `VSEL_C;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            // display check results accordingly
            if (R6 !==16'b1111_1111_0000_0000) begin
                err = 1; 
                $display("FAILED: special shift R6  -- R6=%b is wrong, expected %b", R6, 16'b1111_1111_0000_0000); 
                $stop; 
            end

            //now load R7 into A
            readnum = 3'd7;
            loada = 1;
            #10; //clock
            loada = 0;

            //now load R6 into B
            readnum = 3'd6;
            loadb = 1;
            #10; //clock
            loadb = 0;

            //AND R6 with R7, and store into reg C
            ALUop = 2'b10;
            loadc = 1;
            asel = 0;
            bsel = 0;
            #10; //clock
            loadc = 0;
            shift = 2'b00;//reset shift after loading result into reg C

            // display check results accordingly
            if (datapath_out !==16'b0000_1111_0000_0000) begin
                err = 1; 
                $display("FAILED: adding R6 with special shifted R6  -- datapath_out=%b is wrong, expected %b", datapath_out, 16'b0000_1111_0000_0000); 
                $stop; 
            end

            //store result back into R7
            vsel = `VSEL_C;
            writenum = 3'd7;
            write = 1;
            #10; //clock
            write = 0; //turn off write

            // display check results accordingly
            if (R7 !== 16'b0000_1111_0000_0000) begin 
                err = 1; 
                $display("FAILED: store into R7 -- Regs[R6]=%h is wrong, expected %h", R6, 16'b0000_1111_0000_0000); 
                $stop; 
            end

            //store a really negative number into r0
            sximm8 = -30000;
            writenum = 0;
            write = 1;
            vsel = `VSEL_SXIMM8;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            //store a really positive number into r1
            sximm8 = 30000;
            writenum = 1;
            write = 1;
            vsel = `VSEL_SXIMM8;
            #10; // wait for clock 
            write = 0;  // done writing, remember to set write to zero

            //load r1 into A
            readnum = 1;
            loada = 1;
            #10;
            loada = 0;

            //loadr0 into B
            readnum = 0;
            loadb = 1;
            #10;
            loadb = 0;

            //subtract B from A
            ALUop = 2'b01;
            loads = 1;
            #10;
            loads = 0;

            if ({Z,N,V} !== 3'b011) begin //expecting N to be true because it should overflow into negative, expecting V to be true due to overflow
                err = 1; 
                $display("FAILED: CMP R1,R0 -- {Z,N,V}=%b is wrong, expected %b", {Z,N,V}, 3'b011); 
                $stop; 
            end

            // display check results accordingly
            if (err === 0) 
                $display("PASSED");
            else
                $display("FAILED");
            $stop;
        end


endmodule