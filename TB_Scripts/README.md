mobileNetV2_weight_Scripts.sln
	Found largest and smallest weight values
	Finds percentage that was below 10^-10
	Writes new weights to file as int32

pointwiseTest.py
	basic python script for pointwise/expansion operation

depthwise.py
	testbench for depthwise convolution; Writes to output files

DepthwiseTest_sample_outputs
	Examples of outputs generated from depthwise.py

Bottleneck.py
	assembled expansion, depthwise and pointwise for expected outputs

test_image.h
	intended to be imported initial input of entire mobile net
