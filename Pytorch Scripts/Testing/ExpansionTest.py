# -*- coding: utf-8 -*-
"""
Created on Wed Apr 15 13:02:23 2020

@author: Kennt

Description: Prints the output for the expansion layer to cross reference with 
            the output of the Minized or simulation in vivado
"""

import numpy as np

HEIGHT = 3;
KERNEL = 1;
E_RATIO = 6;
CHANNELS = 3;

#Random inputs for Expansion layers
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

#Counter inputs for Expansion layers
weights = np.zeros(CHANNELS*CHANNELS*E_RATIO*KERNEL*KERNEL)
for i in range(0,CHANNELS*CHANNELS*E_RATIO*KERNEL*KERNEL):
    weights[i] = i+1;
W = np.asarray(weights).reshape(CHANNELS*E_RATIO,CHANNELS,KERNEL,KERNEL)

image = np.zeros(HEIGHT*HEIGHT*CHANNELS)
for i in range(0,HEIGHT*HEIGHT*CHANNELS):
    image[i] = i+2;
I = np.asarray(image).reshape(CHANNELS,HEIGHT,HEIGHT)

output = np.zeros([CHANNELS*E_RATIO,HEIGHT,HEIGHT])
for i in range(0, E_RATIO*CHANNELS):
    for j in range(0, CHANNELS):
        output[i,:,:] = output[i,:,:] + W[i][j][0][0] * I[j,:,:]
o = output.reshape(E_RATIO*CHANNELS*HEIGHT*HEIGHT)