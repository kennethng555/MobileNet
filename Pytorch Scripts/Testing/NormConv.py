# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 03:17:43 2020

@author: Kennt

Description: Prints the output for the normal convolution layer to cross reference with 
            the output of the Minized or simulation in vivado
"""

import numpy as np
import os

HEIGHT = 5;
KERNEL = 1;
PADDING = 0;
IN_CHANNELS = 2;
OUT_CHANNELS = 3;

weights = np.zeros([IN_CHANNELS*OUT_CHANNELS*KERNEL*KERNEL,1])
for i in range(0,IN_CHANNELS*OUT_CHANNELS*KERNEL*KERNEL):
    weights[i] = i+1;
W = np.asarray(weights).reshape(OUT_CHANNELS,IN_CHANNELS,KERNEL,KERNEL)
#np.savetxt('DepthwiseTestWeights.txt', weights, fmt='%f', newline = ',')
#filehandle = open('DepthwiseTestWeights.txt', 'rb+')
#filehandle.seek(-1, os.SEEK_END)
#filehandle.truncate()

image = np.zeros([(HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*IN_CHANNELS,1])
for i in range(0,(HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*IN_CHANNELS):
    image[i] = i+2;
I = np.asarray(image).reshape(IN_CHANNELS,(HEIGHT+2*PADDING),(HEIGHT+2*PADDING))
#np.savetxt('DepthwiseTestImage.txt', image, fmt='%f', newline = ',')
#filehandle = open('DepthwiseTestImage.txt', 'rb+')
#filehandle.seek(-1, os.SEEK_END)
#filehandle.truncate()

output = np.zeros([OUT_CHANNELS,HEIGHT,HEIGHT])
for i in range(0, OUT_CHANNELS):
    for j in range(0, HEIGHT):
        for k in range(0, HEIGHT):
            output[i,j,k] = output[i,j,k] + np.multiply(W[i],I[:,j:j+KERNEL,k:k+KERNEL]).sum(axis=2).sum()
o = output.reshape(OUT_CHANNELS*HEIGHT*HEIGHT,1)
#np.savetxt('DepthwiseTestOutput.txt', o, fmt='%f', newline = ',')
#filehandle = open('DepthwiseTestOutput.txt', 'rb+')
#filehandle.seek(-1, os.SEEK_END)
#filehandle.truncate()