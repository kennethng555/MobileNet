# MobileNet implementation on the MiniZed
This is a hardware implementation of MobileNet meant to be run on the MiniZed.

mobileNet_layerBreakdown_V0.3.xlsx - Excel breakdown of each layer, dimensions and memory usage <br /> 
mobile_net_sdk_submission.c - latest SDK C file for using convolution on miniZED <br /> 
demo_ints.c - testbench for normal convolution and pointwise convolution <br /> 
Documentation - report and presentation <br /> 
pytorch scripts - contains pycharm project files and data related to extracted weights from mobilenet implementation <br /> 
TB_scripts - All scripts used to verify basic functionality of the system. Some in python, some in C, one in C# <br /> 
Verilog files - Copies of unused project files but could be used in future design iterations) <br /> 
mobilenet_submission.xpr.zip - Xilinx Vivado project (Caution: the convolutional unit is named bram_mult, don't want to rename it and break project) 
