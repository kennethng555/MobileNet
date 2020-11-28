# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 03:17:43 2020

@author: Kennt
"""

import numpy as np
import os

HEIGHT = 5;
CHANNELS = 5;

KERNEL = 3;
PADDING = 1;

DONE_R = int(HEIGHT/2)+1;

#import random
#weights = []
#for i in range(0,CHANNELS*CHANNELS*E_RATIO*KERNEL*KERNEL):
#    weights.append(random.randint(1,20))
#W = np.asarray(weights).reshape(CHANNELS*E_RATIO,CHANNELS,KERNEL,KERNEL)
#
#image = []
#for i in range(0,HEIGHT*HEIGHT*CHANNELS):
#    image.append(random.randint(1,20))
#I = np.asarray(image).reshape(HEIGHT,HEIGHT,HEIGHT)

weights = np.zeros([CHANNELS*KERNEL*KERNEL,1])
for i in range(0,CHANNELS*KERNEL*KERNEL):
    weights[i] = i+1;
W = np.asarray(weights).reshape(CHANNELS,KERNEL,KERNEL)
np.savetxt('DepthwiseTestWeights.txt', weights, fmt='%f', newline = '\n')
filehandle = open('DepthwiseTestWeights.txt', 'rb+')
filehandle.seek(-1, os.SEEK_END)
filehandle.truncate()

image = np.zeros([(HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*CHANNELS,1])
for i in range(0,(HEIGHT+2*PADDING)*(HEIGHT+2*PADDING)*CHANNELS):
    image[i] = i+2;
I = np.asarray(image).reshape(CHANNELS,(HEIGHT+2*PADDING),(HEIGHT+2*PADDING))
np.savetxt('DepthwiseTestImage.txt', image, fmt='%f', newline = '\n')
filehandle = open('DepthwiseTestImage.txt', 'rb+')
filehandle.seek(-1, os.SEEK_END)
filehandle.truncate()

output = np.zeros([CHANNELS,HEIGHT,HEIGHT])
for j in range(0, HEIGHT):
    for k in range(0, HEIGHT):
        output[:,j,k] = output[:,j,k] + np.multiply(W,I[:,j:j+KERNEL,k:k+KERNEL]).sum(axis=2).sum(axis=1)
o = output.reshape(CHANNELS*HEIGHT*HEIGHT,1)
np.savetxt('DepthwiseTestOutput.txt', o, fmt='%f', newline = '\n')
filehandle = open('DepthwiseTestOutput.txt', 'rb+')
filehandle.seek(-1, os.SEEK_END)
filehandle.truncate()