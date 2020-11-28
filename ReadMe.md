
mobileNet_layerBreakdown_V0.3.xlsx
	Excel breakdown of each layer, dimensions and memory usage

mobile_net_sdk_submission.c 
	latest SDK C file for using convolution on miniZED
	Same as used in demo

demo_ints.c
	testbench for normal convolution and pointwise convolution
	based on Milder's orignial CLP setup

Documentation
	report and presentation
	report and presentation assets
	
pytorch scripts
	contains pycharm project filesm and data related to extracted
	weights from mobilenet implementation

TB_scripts
	All scripts used to verify basic functionality of the system.
	Some in python, some in C, one in C#

Verilog files
	Copies of unused project files but could be used in future design iterations)
	
mobilenet_submission.xpr.zip
	Xilinx Vivado project
	(Caution: the convolutional unit is named bram_mult, don't want to rename it and break project) 
