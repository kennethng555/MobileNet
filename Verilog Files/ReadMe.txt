batchnorm.v
bathcnorm_c_code.c
batchnorm_tb.sv
	Worked inP&R implementation
	Heavy resource usage made it unfeasible to place in hardware

conv_mult.v
conv_mult_tb.sv
	uses multiple memories and works in simulation
	did not work in P&R implementation

conv_sing_tb_v2.sv
conv_single_v2.v
	single memory read write interface
	V1 did not synthesize. 
	Did not  work in P&R implementation
	
convolution_c_code_v2.c
	Convolution in C to verify operation
