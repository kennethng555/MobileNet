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
    
    logic [31:0] BRAM_addr;
    logic [31:0] BRAM_rddata;
    logic [31:0] BRAM_wrdata;
    logic [3:0]  BRAM_we;


         stdConv conv(
            .clk(clk),
            .reset(reset),
            .ps_control(ps_control),
            .pl_status(pl_status),
            
            .BRAM_addr(BRAM_addr),
            .BRAM_rddata(BRAM_rddata),
            .BRAM_wrdata(BRAM_wrdata),
            .BRAM_we(BRAM_we)
            
        );

        BRAM_memory_sim BRAM(
            .clk(clk),
            .reset(reset),
            .bram_addr(BRAM_addr), 
            .bram_rddata(BRAM_rddata),
            .bram_wrdata(BRAM_wrdata),
            .bram_we(BRAM_we)
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



module BRAM_memory_sim(
    input         clk,
    input         reset,
    input        [31:0] bram_addr,
    output logic [31:0] bram_rddata,
    input        [31:0] bram_wrdata,
    input         [3:0] bram_we);

    parameter N = 2;  //iFM Depth
    parameter M = 2;    //oFM Depth
    
    parameter K = 3;    //Kernel Size
    parameter KC = K;   //Assume square kernel size
    parameter KR = K;   //Assume Square kernel size
    
    parameter iFM_R = 15; //Assume square input    
    parameter iFM_C = 15; //Assume square input
    
    parameter oFM_R = iFM_R - K + 1;    //Assume Square output
    parameter oFM_C = iFM_C - K + 1;    //Assume Square output
    
    parameter KERNEL_DEPTH = N;         //Number of Kernel should match iFM depth
    
    parameter sizeof_iFM = iFM_R * iFM_C * N;
    parameter sizeof_KERN = KR * KC * M * N;
    parameter sizeof_oFM = oFM_R * oFM_C * M;
      
      
    logic [sizeof_iFM + sizeof_KERN + sizeof_oFM - 1:0][31:0] mem;
    int i = 0;
    int j = 3;
    initial 
    begin
        //iFM
        for(i = 0; i < sizeof_iFM; i=i+1) 
        begin
            mem[i] = i + 1;
        end
        
        //Kernel
        for(i = sizeof_iFM; i < sizeof_iFM + sizeof_KERN; i = i + 1) 
        begin
            mem[i] = j ;
            j = j + 1;
            //mem[i] = j ;
            //j = j - 1;
        end
        
        //oFM
        for(i = sizeof_iFM + sizeof_KERN; i < sizeof_iFM + sizeof_KERN + sizeof_oFM; i = i + 1) 
        begin
            mem[i] = 0;
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

/*
module kernel_memory_sim(
    input         clk,
    input         reset,
    input        [31:0] bram_addr,
    output logic [31:0] bram_rddata,
    input        [31:0] bram_wrdata,
    input         [3:0] bram_we);

    parameter HEIGHT = 3;   // Feature map X dimension
    parameter WIDTH = 3;    // Feature Map Y dimension
    parameter N = 3;
    parameter M = 3;
    
    logic [M*N*HEIGHT*WIDTH-1:0][31:0] mem;
    int i;
    initial 
    begin
        for(i=0; i<M*N*HEIGHT*WIDTH; i=i+1) begin
            mem[i] = i+1;
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
*/

/*
module oFM_memory_sim(
    input         clk,
    input         reset,
    input        [31:0] bram_addr,
    output logic [31:0] bram_rddata,
    input        [31:0] bram_wrdata,
    input         [3:0] bram_we);

    parameter HEIGHT = 2;   // Feature map X dimension
    parameter WIDTH = 2;    // Feature Map Y dimension
    parameter M = 3;
    
    logic [M*HEIGHT*WIDTH-1:0][31:0] mem;
    int i;
    initial 
    begin
        for(i=0; i<M*HEIGHT*WIDTH; i=i+1) begin
            mem[i] = 0;
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
*/