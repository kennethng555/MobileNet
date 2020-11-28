# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 22:06:53 2020

@author: Kennt
"""

import numpy as np

HEIGHT = 3;
IN_CHANNELS = 2;
OUT_CHANNELS = 3;

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

weights = np.zeros(IN_CHANNELS*OUT_CHANNELS)
for i in range(0,IN_CHANNELS*OUT_CHANNELS):
    weights[i] = i+1;
W = np.asarray(weights).reshape(OUT_CHANNELS,IN_CHANNELS)

image = np.zeros(HEIGHT*HEIGHT*IN_CHANNELS)
for i in range(0,HEIGHT*HEIGHT*IN_CHANNELS):
    image[i] = i+2;
I = np.asarray(image).reshape(IN_CHANNELS,HEIGHT,HEIGHT)

output = np.zeros([OUT_CHANNELS,HEIGHT,HEIGHT])
for j in range(0, HEIGHT):
    for k in range(0, HEIGHT):
        for i in range(0, OUT_CHANNELS):
            output[i,j,k] = output[i,j,k] + np.multiply(W[i],I[:,j,k]).sum()
o = output.reshape(OUT_CHANNELS*HEIGHT*HEIGHT)