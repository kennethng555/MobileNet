/*
Summary

1. Calculate the average by looping and summing
    - cycle 1 (load): On N-1, divide that last sum by total elements
2. Calculate the variance by looping and squaring difference between number and average
    - cycle 1 (load): on N-1, take the square root of the variance to get std dev
3. Read and write back (toggle backand forth) the batchnorm
    - cycle 1(load): read a batch norm value and calc based on average and variance
    - cycle 2(calc): write it back with ReLU
    - on N-1, set pl_status to '1' to signal finished operations
    
    DEBUG_xxxx signsls are used to help understand indexing since memory is byte addressed and we're using words
    
    DEBG_addr_xxx will give word addressing
*/





`timescale 1ns / 1ps

module batchNorm(
    input         clk,
    input         reset,
    input  [31:0] ps_control,
    output [31:0] pl_status,
    
    output [31:0] iFM_addr,
    input  [31:0] iFM_rddata,
    output [31:0] iFM_wrdata,
    output [3:0]  iFM_we
    );

    wire    clr,
            load,
            calc,
            done_calc_avg,
            done_calc_var,
            done_calc_bn;

    datapath dp(
		.clk(clk),
		.reset(reset),
		.clr(clr),
		
		.load(load),
		.calc(calc),
		
        .done_calc_avg(done_calc_avg),
        .done_calc_var(done_calc_var),
        .done_calc_bn(done_calc_bn),
		
		.iFM_addr(iFM_addr),
		.iFM_rddata(iFM_rddata),
		.iFM_wrdata(iFM_wrdata),
		.iFM_we(iFM_we)
	);
		       
    ctrlpath cp(
		.clk(clk),
		.reset(reset),
		.clr(clr),
		
		.ps_control(ps_control),
		.pl_status(pl_status),

		.load(load),
        .calc(calc),
        
        .done_calc_avg(done_calc_avg),
        .done_calc_var(done_calc_var),
        .done_calc_bn(done_calc_bn)
	);
                     
endmodule //End top Level

/**************************************************************************/
/*
                 _       _                    _   _     
                | |     | |                  | | | |    
              __| | __ _| |_ __ _ _ __   __ _| |_| |__  
             / _` |/ _` | __/ _` | '_ \ / _` | __| '_ \ 
            | (_| | (_| | || (_| | |_) | (_| | |_| | | |
             \__,_|\__,_|\__\__,_| .__/ \__,_|\__|_| |_|
                                 | |                    
                                 |_|                    
                
 */
/**************************************************************************/

module datapath(
		input             clk,
		input             reset,
		input             clr,
		output reg [31:0] iFM_addr,
		input      [31:0] iFM_rddata,
		output reg [31:0] iFM_wrdata,
		output reg [3:0]  iFM_we,
		
        input             load,
        input             calc,
        
        output            done_calc_avg,
        output            done_calc_var,
        output            done_calc_bn
	);
    
    parameter iFM_R = 4;                //Dimensions of input
    parameter iFM_C = 4;
    parameter TOTAL = iFM_R * iFM_C;    //Total number of items in that 2D space
    
    parameter BYTE_OFFSET = 4; //byte addressing for words requires addressing multiples of 4
    
    reg signed  [63:0] average;
    reg signed  [63:0] sqrt_variance;
    reg signed  [31:0] batchNorm;
    reg         [31:0] index;
    wire signed [31:0] s_iFM_rddata;
    
    reg         done_load_w;
    reg         done_calc_avg_w;
    reg         done_calc_var_w;
    reg         done_calc_bn_w;
    reg         loc_avg_done;
    reg         loc_var_done;  
     
    //DEBUG VARS    
    reg         [31:0]DEBUG_iFM_addr;
    reg         [31:0]DEBUG_SUM;

    //Combinational Batchnorm
    always @(iFM_rddata,average,sqrt_variance)
    begin
        iFM_wrdata = (s_iFM_rddata - average) / sqrt_variance ;    //Batchnorm is instance-x - average divided by std dev
        batchNorm = (s_iFM_rddata - average) / sqrt_variance ;    //Batchnorm is instance-x - average divided by std dev
    end

    /*Synchronous logic*/
    always @(posedge clk) 
    begin
    
        /**************************************/
        /*************   RESET  ***************/
        /**************************************/
        if (clr) 
        begin
            //BRAM memory control
            iFM_addr <= 0;        
            iFM_we <= 0;
            
            //Target Calculations
            average  <=0;         
            sqrt_variance <=0;         
            batchNorm <=0;
            
            // Memory to determine accumulation mode
            loc_avg_done <=0;
            loc_var_done <=0;
            
            //Control signals
            done_calc_avg_w <=0;
            done_calc_var_w <=0;
            done_calc_bn_w <=0;
            done_load_w <=0 ;
            index <= 0;
        
        end
        
        /**************************************/
        /*************   LOAD    **************/
        /**************************************/
        else if(load)
        begin
            
            if(index < TOTAL  )
            begin
                    if (index == TOTAL - 1  )
                    begin
                        iFM_addr  <= 0;      //prep for next loop thru
                    end
                    else
                    begin
                         iFM_addr  <= BYTE_OFFSET * (index +1);      //Update Address
                    end
                   
                    index <= index + 1;
                    
                    //Determine accumulation mode
                    //Find Average
                    if( done_calc_avg_w == 0 && index !=0)
                    begin
                        average <= iFM_rddata + average;    //Accumulate
                    end
                    
                    //Find sqrt_variance
                    else if(done_calc_var_w == 0 && index !=0)
                    begin
                        //Summation of difference squared  = sigma(x - E[x]^2)
                        sqrt_variance <= ((s_iFM_rddata - average) * (s_iFM_rddata - average)) + sqrt_variance;    
                    end
                    
                    //Find Batchnorm
                    else
                    begin
                        iFM_we <= 0;
                        //iFM_wrdata =(iFM_rddata - average) / sqrt_variance ;    //Batchnorm is instance-x - average divided by std dev
                    end

            end//end index check
            
            else
            begin
                index <= 0;
                
                if ( done_calc_avg_w ==0)
                begin
                    //loc_avg_done <= 1;
                    done_calc_avg_w <= 1;
                    average <= (average + iFM_rddata) / TOTAL; //Divide by N
                                                
                end
                else if (done_calc_var_w == 0)
                begin
                    //loc_var_done <= 1;
                    done_calc_var_w <= 1;
                    sqrt_variance <= sqrt((((s_iFM_rddata - average) * (s_iFM_rddata - average)) + sqrt_variance)/TOTAL);//Divide by N and find square root                      
                    iFM_we <= 4'hf;
                end
                else
                begin
                    done_calc_bn_w <= 1;
                end
                
            end
            
        end
        
        /**************************************/
       /*************   CALC    **************/
       /**************************************/
        else if(calc) 
        begin
            if(index < TOTAL && done_calc_bn_w == 0)
            begin
                 
                if (index == TOTAL - 1)
                begin
                    iFM_we <= 0;
                end
                else
                begin
                
                    iFM_we <= 4'hf;
                end
            end
            else
            begin
                iFM_we <= 0;
            end
        end

        
    end //end clock
    
    assign done_calc_avg = done_calc_avg_w;
    assign done_calc_var = done_calc_var_w;
    assign done_calc_bn = done_calc_bn_w;
    assign s_iFM_rddata = iFM_rddata;
    /**************************************************************************/
    /*
                          _      _                 
                         | |    | |                
                       __| | ___| |__  _   _  __ _ 
                      / _` |/ _ \ '_ \| | | |/ _` |
                     | (_| |  __/ |_) | |_| | (_| |
                      \__,_|\___|_.__/ \__,_|\__, |
                                              __/ |
                                             |___/ 
     */
    /**************************************************************************/
    
    /*debug signals*/
    always @ (iFM_addr,iFM_rddata,average) 
    begin
        DEBUG_iFM_addr = iFM_addr/BYTE_OFFSET;    
        DEBUG_SUM = ((iFM_rddata - average) * (iFM_rddata - average)) ;
    end
    /*debug signals*/
    /*
    always @ (iFM_addr,oFM_addr,kernel_addr,iFM_rddata,kernel_rddata) 
    begin
        DEBUG_iFM_addr = iFM_addr/4;    
        DEBUG_oFM_addr = oFM_addr/4;
        DEBUG_kernel_addr = kernel_addr/4;
        DEBUG_inst_sum = iFM_rddata * kernel_rddata;
    end
    */

    /**************************************************************************/
    /***************************Helper functions*******************************/
    /**************************************************************************/
    /*Square root: TODO: check with milder if this is okay*/
    
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
endmodule //End Datapath

/**************************************************************************/
/*
                                    _             _ 
                                   | |           | |
                     ___ ___  _ __ | |_ _ __ ___ | |
                    / __/ _ \| '_ \| __| '__/ _ \| |
                   | (_| (_) | | | | |_| | | (_) | |
                    \___\___/|_| |_|\__|_|  \___/|_|
    
    
 */
/**************************************************************************/

module ctrlpath(
		input         clk, 
		input         reset, 
		output        clr,
		
		output        load,
        output        calc, 
        
        input         done_calc_avg, //Trigger on any kind of finished calculation
        input         done_calc_var, //Trigger on any kind of finished calculation
        input         done_calc_bn, //Trigger on any kind of finished calculation

		input  [31:0] ps_control,
		output [31:0] pl_status
	);
    
    // Current state register and next state signal
    reg [3:0]           state;
    reg [3:0]           next_state;

    // State machine function:
    // state 0: wait for ps_control == 1 (PS start signal)
    // state 1: 
    // state 2: 
    // state 3: 
    // state 4:

    // State register
    always @(posedge clk) begin
        if (reset)
            state <= 0;
        else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @* begin
        if (state == 0) begin   //Load inputs
            if (ps_control[0] == 1)
                next_state = 1;
            else
                next_state = 0;
        end //End state 0
        
        else if (state == 1) begin  //calculate avereage
            if (done_calc_avg == 1)
                next_state = 2;
            else
                next_state = 1;
        end //End state 1
        
        else if (state == 2) begin  //calculate  square root of variance
            if (done_calc_var == 1)
               next_state = 4;
            else
               next_state = 2;
        end //End state 2
        
        else if (state == 3) begin  //load value for batchnorm
               next_state = 4;
        end //End state 3
        
        else if (state == 4) begin  //writeback batchnorm
            if (done_calc_bn == 1)
               next_state = 5;
            else
               next_state = 3;
        end //End state 3

        else if (state == 5) begin  //Finished
               next_state = 0;
        end //End state 3
        
    end //End FSM

    // Assign output values
    assign clr = (state == 0);
    assign load = (state == 1 || state == 2 || state == 3);
    assign calc = (state == 4 );

    assign pl_status = (state == 5) ? 1 : 0;
 
endmodule //End Control






