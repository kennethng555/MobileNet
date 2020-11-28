`timescale 1ns / 1ps

module stdConv(
    input         clk,
    input         reset,
    input  [31:0] ps_control,
    output [31:0] pl_status,
    
    
    output [31:0] BRAM_addr,
    input  [31:0] BRAM_rddata,
    output [31:0] BRAM_wrdata,
    output [3:0]  BRAM_we
    
    );

    wire clr,
         load_iFM,
         load_kern,
         load_oFM,
         calc,
        
         done_load_iFM,
         done_load_kern,
         done_load_oFM,
         calc_done,
         done_calc;
    
    datapath dp(
		.clk(clk),
		.reset(reset),
		.clr(clr),
		
		.load_iFM(load_iFM),
		.load_kern(load_kern),
		.load_oFM(load_oFM),
		.calc(calc),
		.calc_done(calc_done),
		
		.done_calc(done_calc),
		
		.BRAM_addr(BRAM_addr),
		.BRAM_rddata(BRAM_rddata),
		.BRAM_wrdata(BRAM_wrdata),
		.BRAM_we(BRAM_we)

	);
		
	
                     
    ctrlpath cp(
		.clk(clk),
		.reset(reset),
		.clr(clr),
		
		.ps_control(ps_control),
		.pl_status(pl_status),

		.load_iFM(load_iFM),
		.load_kern(load_kern),
		.load_oFM(load_oFM),
        .calc_done(calc_done),
		.calc(calc), 
		
		.done_calc(done_calc)

	);
                     


endmodule


module datapath(
		input             clk,
		input             reset,
		input             clr,
		output reg [31:0] BRAM_addr,
		input      [31:0] BRAM_rddata,
		output reg [31:0] BRAM_wrdata,
		output reg [3:0]  BRAM_we,
		
		input             load_iFM,
		input             load_kern,
		input             load_oFM,
		input             calc,
		input             calc_done,
		
		output            done_calc
	);
    

    
    parameter N = 2;    //iFM Depth
    parameter M = 2;    //oFM Depth
    
    parameter K = 3;    //Kernel Size
    parameter KC = K;   //Assume square kernel size
    parameter KR = K;   //Assume Square kernel size

    parameter iFM_R = 15; //Assume square input    
    parameter iFM_C = 15; //Assume square input
    
    parameter oFM_R = iFM_R - K + 1;    //Assume Square output
    parameter oFM_C = iFM_C - K + 1;    //Assume Square output
    
    parameter KERNEL_DEPTH = N;         //Number of Kernel should match iFM depth
    
    parameter BYTE_OFFSET = 4; //byte addressing for words requires addressing multiples of 4
    
    parameter iFM_ADDR_START = 0;                                   //Starting address; Byte based; First Address overall    
    parameter WEIGHT_ADDR_START = iFM_ADDR_START + iFM_R * iFM_C * N *(BYTE_OFFSET);//Starting address; Byte based; Stacked on iFM
    parameter oFM_ADDR_START = WEIGHT_ADDR_START + K * K * M * N * (BYTE_OFFSET);//Starting address; Byte based; Stack on weights
    //M Words of size BYTE_OFFSET (aka 4 bytes per word)
    
    
    //***STACK DESCRIPTION**//
    
    /*
    ***TOP_OF_STACK***
        oFM_Addr[M]     //iFM_addr + N + K + M
        .
        ..
        ...             //Incrementing M values
        oFM_Addr[2]          //iFM_addr + N + K + 2
        oFM_Addr[1]          //iFM_addr + N + K + 1
        oFM_Addr[0]          //iFM_addr + N + K 
        kernel[k]            //iFM_addr + N + K - 1
        .
        ..
        ...             //Incrementing K values
        kernel[2]            //iFM_addr + 2
        kernel[1]            //iFM_addr + 1
        kernel[0]            //iFM_addr + N
        iFM_Addr[N]          //iFM_addr + N-1 
        .
        ..
        ...             //Incrementing N Values
        iFM_Addr[2]         //iFM_addr + 2
        iFM_Addr[1]         //iFM_addr + 1
        iFM_Addr[0]         //iFM_addr  (counting up to N)
    ***BOTTOM_OF_STACK***
    */
    
    /*Instance variables that will count up to Capitalized versions*/
    reg        [31:0] m;
    reg        [31:0] n;
    reg        [31:0] kr;
    reg        [31:0] kc;
    reg        [31:0] oFM_r;
    reg        [31:0] oFM_c;
    
    /*Status signal (to be detected by Control path)*/
    reg        done_calc_w;

    /*Absolute Addresses*/
    reg        [31:0]iFM_addr;
    reg        [31:0]oFM_addr;
    reg        [31:0]kern_addr;
    
    //DEBUG VARS
    /*Relative Addresses*/   
    
    ///* 
    reg         [31:0]DEBUG_iFM_addr;   
    reg         [31:0]DEBUG_oFM_addr; 
    reg         [31:0]DEBUG_kern_addr;  
    reg         [31:0]DEBUG_BRAM_addr;
    //*/ 
    reg         [31:0]iFM_readIn;
    reg         [31:0]kern_readIn;
    reg         [31:0]oFM_readIn;

    
    //Combinational (MAC)
    always @(iFM_readIn, kern_readIn, oFM_readIn)
    begin
        BRAM_wrdata = iFM_readIn * kern_readIn + oFM_readIn;
    end
    
    always @(BRAM_rddata,load_iFM,load_kern,load_oFM,calc)
    begin
    /*
        if(load_iFM == 1)
        begin
            iFM_readIn = BRAM_rddata;
        end
        else if(load_kern == 1)
        begin
            iFM_readIn = BRAM_rddata;
        end
        else if(load_oFM == 1)
        begin
            kern_readIn = BRAM_rddata;
        end
        else if(calc == 1)
        begin
            oFM_readIn = BRAM_rddata;
        end
    */
    end
    
    // Incrementer
	/*
	for(m=0; m<M; m++)
		for(n=0; n<N; n++)
			for(i=0; i<K; i++)
				for(j=0; j<K; j++)
					for(r=0; r<R; r++)
						for(c=0; c<C; c++)
							O[m][r][c]+=W[m][n][i][j]*I[n][r+i][c+j] 

*/
    always @(posedge clk) 
    begin
    
        /*DEBUG*/
        /*Word addressing index */

        /*********************************************************************************************************************/
        if (clr) 
        begin
            m <= 0;
            n <= 0;
            kr <= 0;
            kc <= 0;
            oFM_r <= 0;
            oFM_c <= 0;

            done_calc_w <= 0;
            
            iFM_addr  <= iFM_ADDR_START;
            kern_addr <= WEIGHT_ADDR_START;
            oFM_addr  <= oFM_ADDR_START;
      
            BRAM_addr <= iFM_ADDR_START;
            BRAM_we <= 0;
            
            iFM_readIn <= BRAM_rddata;
            kern_readIn <= 0;
            oFM_readIn <= 0;
        end
        /*********************************************************************************************************************/
        else if (load_iFM)
        begin
            BRAM_we <= 0;
            /*Address udpates*/
            /*Matrix was flattened, use this to traverse rows properly*/
            // 123         123            285
            // 456         123
            // 789         123
            
            BRAM_addr <= kern_addr;

            if (oFM_c == oFM_C-1 && oFM_r == oFM_R-1 && kc == K-1 && kr == K-1 && n == N-1 && m==M-1)
            begin
                //finished
                BRAM_we <= 0; /* Finished writing output features maps, you're completely done */
                done_calc_w <= 1;
            end   
        end
        /*********************************************************************************************************************/
        else if (load_kern)
        begin
            BRAM_addr <= oFM_addr;
            iFM_readIn <= BRAM_rddata;
        end
        /*********************************************************************************************************************/
        else if (load_oFM)
        begin
            BRAM_addr <= oFM_addr;
            kern_readIn <= BRAM_rddata;

            
       
           
        end
        /*********************************************************************************************************************/
        else if (calc)
        begin
            oFM_readIn <= BRAM_rddata;
            BRAM_we <= 4'hf; 
            
            if (oFM_c < oFM_C - 1)
            begin
            oFM_c <= oFM_c + 1;
            end
            
            else if(oFM_r < oFM_R - 1 )
            begin
             oFM_c <=0;
             oFM_r <= oFM_r + 1;
            end
            
            else if(kc < K - 1)
            begin
             oFM_c  <= 0;
             oFM_r  <= 0;
             kc <= kc + 1;
            end
            
            else if(kr < K - 1)
            begin
             oFM_c  <= 0;
             oFM_r  <= 0;
             kc <= 0;
             kr <= kr + 1;
            end
            
            else if(n < N - 1)
            begin
             oFM_c  <= 0;
             oFM_r  <= 0;
             kc <= 0;
             kr <= 0;
             n <= n + 1;
            end
            
            else if(m < M - 1)
            begin
             oFM_c  <= 0;
             oFM_r  <= 0;
             kc <= 0;
             kr <= 0;
             n <= 0;
             m <= m + 1;
            end
            
            else
            begin
            //BRAM_we <= 4'hf; /* Finished writing output features maps, you're completely done */
            end
        end//end calc   
        /*********************************************************************************************************************/
        else if (calc_done)
        begin
           BRAM_we <= 0; 
           BRAM_addr  <= BYTE_OFFSET * (           //byte addressing
                         n * iFM_C * iFM_R         //Stack feature maps 
                        + iFM_C * (kr + oFM_r)     // r + kc        
                        + kc+ oFM_c                // c + kc
                      ); 
        
           
            /*Jump by Nsize of N*/    
           iFM_addr    <= BYTE_OFFSET * (           //byte addressing
                       n * iFM_C * iFM_R         //Stack feature maps 
                      + iFM_C * (kr + oFM_r)     // r + kc        
                      + kc+ oFM_c                // c + kc
           ); 
           
           /*Stack everything on top of one another*/
           kern_addr <= WEIGHT_ADDR_START +  BYTE_OFFSET * (    // Byte adressing
                          m * KC * KR * N    //Which output feature map we're working on
                      +   n * KC * KR        //which input feature map we're working on
                      +  kr * KC             //Row of instance kernel
                      +  kc                  //Column of instance kernel 
           );
           
           /*traverse the output feature map normally*/
           oFM_addr <= oFM_ADDR_START + BYTE_OFFSET *(
                     m * oFM_R * oFM_C 
                    +   oFM_r * oFM_C //Rows of outFM
                    +  oFM_c          //columns of out FM
           ); 
           
        end//end calc   
        /*********************************************************************************************************************/
       
       
        else begin
            BRAM_we <= 0;
        end
    end //end clock
    
    assign done_calc = done_calc_w;
    
    
    /*debug signals*/
    
    always @ (iFM_addr,oFM_addr,kern_addr,iFM_readIn,kern_readIn,BRAM_addr) 
    begin
        DEBUG_iFM_addr = iFM_addr/4;
        DEBUG_kern_addr = (kern_addr - WEIGHT_ADDR_START)/4;
        DEBUG_oFM_addr = (oFM_addr - oFM_ADDR_START)/4 ;
        
        DEBUG_BRAM_addr = BRAM_addr/4;
    end
    
    
    
endmodule
 
 
 
module ctrlpath(
		input         clk, 
		input         reset, 
		output        clr,
		
		output        load_iFM,
		output        load_kern,
		output        load_oFM,
		
		output        calc,
		output        calc_done,
		
		input         done_calc,
		
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
        end
        
        else if (state == 1) begin  //load a iFM
                next_state = 2;
        end
        
        else if (state == 2) begin  //Load a weight
                next_state = 3;
        end
        
        else if (state == 3) begin  //Load prev result

                next_state = 4;
        end
        
        else if (state == 4) begin  //Load prev result

                next_state = 5;
        end
    
        else if (state == 5) begin //Calculate a result
            if (done_calc == 1)
                next_state = 6;
            else
                next_state = 1;
        end
        
        else if (state == 6) begin
                next_state = 0;     //HUZZAH. FINISHED
        end
        

    end 

    // Assign output values
    assign clr = (state == 0);
    assign load_iFM = (state == 1 );
    assign load_kern = (state == 2);
    assign load_oFM = (state == 3);
    assign calc = (state == 4);
    assign calc_done = (state == 5);
    assign pl_status = (state == 6) ? 1 : 0;
        
endmodule






