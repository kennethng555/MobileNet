`timescale 1ns / 1ps

module mult(
    input         clk,
    input         reset,
    input  [31:0] ps_control,
    output [31:0] pl_status,
    
    
    output [31:0] iFM_addr,
    input  [31:0] iFM_rddata,
    output [31:0] iFM_wrdata,
    output [3:0]  iFM_we,
    
    output [31:0] kernel_addr,
    input  [31:0] kernel_rddata,
    output [31:0] kernel_wrdata,
    output [3:0]  kernel_we,
    
    output [31:0] oFM_addr,
    input  [31:0] oFM_rddata,
    output [31:0] oFM_wrdata,
    output [3:0]  oFM_we
    
    
    );

    wire clr, load, done_load, calc, done_calc;
    
    datapath dp(
		.clk(clk),
		.reset(reset),
		.clr(clr),
		
		.load(load),
		.calc(calc),
		
		.done_load(done_load),
		.done_calc(done_calc),
		
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
		
	
                     
    ctrlpath cp(
		.clk(clk),
		.reset(reset),
		.clr(clr),
		
		.ps_control(ps_control),
		.pl_status(pl_status),

		.load(load),
		.done_load(done_load),
		.calc(calc), 
		.done_calc(done_calc)

	);
                     


endmodule


module datapath(
		input             clk,
		input             reset,
		input             clr,
		output reg [31:0] iFM_addr,
		input      [31:0] iFM_rddata,
		output reg [31:0] iFM_wrdata,
		output reg [3:0]  iFM_we,
		
		output reg [31:0] kernel_addr,
		input      [31:0] kernel_rddata,
		output reg [31:0] kernel_wrdata,
		output reg [3:0]  kernel_we,

		output reg [31:0] oFM_addr,
		input      [31:0] oFM_rddata,
		output reg [31:0] oFM_wrdata,
		output reg [3:0]  oFM_we,
		
		input             load,
		input             calc,
		output			  done_load,
		output            done_calc
	);
    

    
    parameter M =3;
    parameter N = 3;
    parameter K = 3;    //Kernel Size
    parameter KC = K;
    parameter KR = K;
    parameter oFM_R = iFM_R - K + 1;
    parameter oFM_C = iFM_C - K + 1;
    
    parameter iFM_R = 4;
    parameter iFM_C = 4;
    parameter KERNEL_DEPTH = N;
    
    parameter BYTE_OFFSET = 4; //byte addressing for words requires addressing multiples of 4
    
    reg        [31:0] m;
    reg        [31:0] n;
    reg        [31:0] kr;
    reg        [31:0] kc;
    reg        [31:0] oFM_r;
    reg        [31:0] oFM_c;
    reg        done_calc_w;
    reg        done_load_w;
    
    //DEBUG VARS    
    reg         [31:0]DEBUG_iFM_addr;
    reg         [31:0]DEBUG_oFM_addr; 
    reg         [31:0]DEBUG_kernel_addr;  
    reg         [31:0]DEBUG_inst_sum;
    
    
    always @(iFM_rddata, kernel_rddata, oFM_rddata)
    begin
        oFM_wrdata = iFM_rddata * kernel_rddata + oFM_rddata;
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

        
        if (clr) 
        begin
            m <= 0;
            n <= 0;
            kr <= 0;
            kc <= 0;
            oFM_r <= 0;
            oFM_c <= 0;
            
            done_calc_w <= 0;
            done_load_w <= 0;
            
            iFM_addr <= 0;
            iFM_we <= 0;
            iFM_wrdata <=0;
            
            kernel_addr <= 0;
            kernel_we <= 0;
            kernel_wrdata<= 0;
            
            
            oFM_addr <=0;
            oFM_we <= 0;
            //oFM_wrdata <=0;
            
        end
        
        else if (load)
        begin
            /*Writes*/

            if (done_calc_w ==1)
                 oFM_we <= 0;
            /*Address udpates*/
            /*Matrix was flattened, use this to traverse rows properly*/
            
            // 123         123            285
            // 456         123
            // 789         123
            
            /*Jump by Nsize of N*/    
            iFM_addr    <= BYTE_OFFSET * (           //byte addressing
                           n * iFM_C * iFM_R         //Stack feature maps 
                          + iFM_C * (kr + oFM_r)     // r + kc        
                          + kc+ oFM_c                // c + kc
            ); 
                         
            
            /*Stack everything on top of one another*/
            kernel_addr <=    BYTE_OFFSET * (    // Byte adressing
                              m * KC * KR * N    //Which output feature map we're working on
                          +   n * KC * KR        //which input feature map we're working on
                          +  kr * KC             //Row of instance kernel
                          +  kc                  //Column of instance kernel 
            );       
        
            /*traverse the output feature map normally*/
            oFM_addr <= BYTE_OFFSET *(
                         m * oFM_R * oFM_C 
                        +   oFM_r * oFM_C //Rows of outFM
                        +  oFM_c          //columns of out FM
            ); 
            done_load_w <= 1;
            
            if (oFM_c == oFM_C-1 && oFM_r == oFM_R-1 && kc == K-1 && kr == K-1 && n == N-1 && m==M-1)
            begin
                //finished
                oFM_we <= 0; /* Finished writing output features maps, you're completely done */
                done_calc_w <= 1;
            end
    
        end
        
        else if (calc)
        begin
            oFM_we <= 4'hf; /*Always write*/
            
            /* Start Loop counter starting with highest frequency looper */
            if (oFM_c < oFM_C - 1) begin
                oFM_c <= oFM_c + 1;
            end
            
            else if(oFM_r < oFM_R - 1)
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
    
            else if(n < N-1)
            begin
                oFM_c  <= 0;
                oFM_r  <= 0;
                kc <= 0;
                kr <= 0;
                n <= n + 1;
            end
    
            else if(m < M-1)
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
                oFM_we <= 4'hf; /* Finished writing output features maps, you're completely done */
            end
        end//end calc   
    end //end clock
    
    assign done_calc = done_calc_w;
    assign done_load = done_load_w;
    
    
    /*debug signals*/
    always @ (iFM_addr,oFM_addr,kernel_addr,iFM_rddata,kernel_rddata) 
    begin
        DEBUG_iFM_addr = iFM_addr/4;    
        DEBUG_oFM_addr = oFM_addr/4;
        DEBUG_kernel_addr = kernel_addr/4;
        DEBUG_inst_sum = iFM_rddata * kernel_rddata;
    end
    
    
    
endmodule
 
module ctrlpath(
		input         clk, 
		input         reset, 
		output        clr,
		
		output        load,
		input         done_load,
		output        calc,
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
        
        else if (state == 1) begin  //calculate 
            if (done_load == 1)
                next_state = 2;
            else
                next_state = 1;
        end
    
        else if (state == 2) begin
            if (done_calc == 1)
                next_state = 3;
            else
                next_state = 1;
        end
        else if (state == 3) begin
                next_state = 0; //HUZZAH. FINISHED
        end
        

    end 

    // Assign output values
    assign clr = (state == 0);
    assign load = (state == 1 );
    assign calc = (state == 2);
    assign pl_status = (state == 3) ? 1 : 0;
        
endmodule






