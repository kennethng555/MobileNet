`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/19/2020 10:53:31 PM
// Design Name: 
// Module Name: mult_acc_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mult_tb();

    logic clk, reset;
    logic [31:0] ps_control;
    logic [31:0] pl_status;
    
    logic [31:0] iFM_addr;
    logic [31:0] iFM_rddata;
    logic [31:0] iFM_wrdata;
    logic [3:0]  iFM_we;

    logic [31:0] kernel_addr;
    logic [31:0] kernel_rddata;
    logic [31:0] kernel_wrdata;
    logic [3:0]  kernel_we;
    
    logic [31:0] oFM_addr;
    logic [31:0] oFM_rddata;
    logic [31:0] oFM_wrdata;
    logic [3:0]  oFM_we;


         mult conv(
            .clk(clk),
            .reset(reset),
            .ps_control(ps_control),
            .pl_status(pl_status),
            
            .iFM_addr(iFM_addr),
            .iFM_rddata(iFM_rddata),
            .iFM_wrdata(iFM_wrdata),
            .iFM_we(iFM_we)

        );

        iFM_memory_sim iFM(
            .clk(clk),
            .reset(reset),
            .bram_addr(iFM_addr), 
            .bram_rddata(iFM_rddata),
            .bram_wrdata(iFM_wrdata),
            .bram_we(iFM_we)
        );
        
    initial clk=0;
    always #5 clk = ~clk;

    initial begin
        ps_control = 0;
        reset = 1;
       
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1; reset = 0;

        @(posedge clk);
        @(posedge clk);
        #1; ps_control = 1;

        wait(pl_status[0] == 1'b1);
        
        @(posedge clk);
        #1; ps_control = 0;
        
        wait(pl_status[0] == 1'b0);
        $stop;
        
    end
endmodule



module iFM_memory_sim(
    input         clk,
    input         reset,
    input        [31:0] bram_addr,
    output logic [31:0] bram_rddata,
    input        [31:0] bram_wrdata,
    input         [3:0] bram_we);

    parameter HEIGHT = 4;   // Feature map X dimension
    parameter WIDTH = 4;    // Feature Map Y dimension
    parameter N = 1;
    
    logic [N*HEIGHT*WIDTH-1:0][31:0] mem;
    int i;
    initial 
    begin
        for(i=0; i<N*HEIGHT*WIDTH; i=i+1) begin
            mem[i] = i+1;
        end
        //mem[16] = 10000;
        if (1)
        begin
        mem[0] = 362860358;                                                                            
        mem[1] = 61391368;                                                                             
        mem[2] = 1659597974;                                                                           
        mem[3] = 783080366;                                                                            
        mem[4] = 510756338;                                                                            
        mem[5] = 1047070989;                                                                           
        mem[6] = 541198206;                                                                            
        mem[7] = 1090721080;                                                                           
        mem[8] = 778591567;                                                                            
        mem[9] = 1829386774;                                                                           
        mem[10] = 632447655;                                                                           
        mem[11] = 1022145498;                                                                          
        mem[12] = 1315433754;                                                                          
        mem[13] = 488928044;                                                                           
        mem[14] = 1461990909;                                                                          
        mem[15] = 192739358; 
        end
    end // initial
    always @(posedge clk)
    begin

        bram_rddata <= mem[bram_addr[12:2]];
        if (bram_we == 4'hf)
            mem[bram_addr[12:2]] <= bram_wrdata;
        else if (bram_we != 0)
            $display("ERROR: Memory simulation model only implemented we = 0 and we=4'hf. Simulation will be incorrect.");              
    end



endmodule // memory_sim


module testbench;

reg [31:0] sqr;

//Verilog function to find square root of a 32 bit number.
//The output is 16 bit.
function [63:0] sqrt;
parameter IN = 64;
parameter OUT = 32;
    input [IN-1:0] num;  //declare input
    //intermediate signals.
    reg [100:0] a;
    reg [100:0] q;
    reg [100:0] left,right,r;    
    integer i;
begin
    //initialize all the variables.
    a = num;
    q = 0;
    i = 0;
    left = 0;   //input to adder/sub
    right = 0;  //input to adder/sub
    r = 0;  //remainder
    //run the calculations for 16 iterations.
    for(i=0;i<OUT;i=i+1) begin 
        right = {q,r[OUT+1],1'b1};
        left = {r[OUT-1:0],a[IN-1:IN-2]};
        a = {a[IN-2:0],2'b00};    //left shift by 2 bits.
        if (r[OUT+1] == 1) //add if r is negative
            r = left + right;
        else    //subtract if r is positive
            r = left - right;
        q = {q[OUT-1:0],!r[OUT+1]};       
    end
    sqrt = q;   //final assignment of output.
end
endfunction //end of Function

//simulation-Apply inputs.
    initial begin
        sqr = sqrt(64'd4);    #100;
        sqr = sqrt(64'd9);  #100;
        sqr = sqrt(64'd4000000);    #100;
        sqr = sqrt(64'd96100);  #100;
        sqr = sqrt(64'd25); #100;
        sqr = sqrt(64'd100000000);  #100;
        sqr = sqrt(64'd33); #100;
        sqr = sqrt(64'd3300);   #100;
        sqr = sqrt(64'd330000); #100;
        sqr = sqrt(64'd3300000000); #100;
        sqr = sqrt(64'd4294967296); #100;
        sqr = sqrt(64'd4294967295); #100;
    end
      
endmodule



