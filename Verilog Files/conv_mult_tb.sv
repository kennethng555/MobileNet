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
            .iFM_we(iFM_we),
            
            .kernel_addr(kernel_addr),
            .kernel_rddata(kernel_rddata),
            .kernel_wrdata(kernel_wrdata),
            .kernel_we(kernel_we),
            
            .oFM_addr(oFM_addr),
            .oFM_rddata(oFM_rddata),
            .oFM_wrdata(oFM_wrdata),
            .oFM_we(oFM_we)
        );

        iFM_memory_sim iFM(
            .clk(clk),
            .reset(reset),
            .bram_addr(iFM_addr), 
            .bram_rddata(iFM_rddata),
            .bram_wrdata(iFM_wrdata),
            .bram_we(iFM_we)
        );
        
        kernel_memory_sim kernelFM(
            .clk(clk),
            .reset(reset),
            .bram_addr(kernel_addr), 
            .bram_rddata(kernel_rddata),
            .bram_wrdata(kernel_wrdata),
            .bram_we(kernel_we)
        );
        
        oFM_memory_sim oFM(
            .clk(clk),
            .reset(reset),
            .bram_addr(oFM_addr), 
            .bram_rddata(oFM_rddata),
            .bram_wrdata(oFM_wrdata),
            .bram_we(oFM_we)
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
    parameter N = 3;
    
    logic [N*HEIGHT*WIDTH-1:0][31:0] mem;
    int i;
    initial 
    begin
        for(i=0; i<N*HEIGHT*WIDTH; i=i+1) begin
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