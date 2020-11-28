# -*- coding: utf-8 -*-
"""
Created on Mon May 11 02:56:11 2020

@author: Kennt
"""

import numpy as np
import os

HEIGHT = 32;
KERNEL = 1;
E_RATIO = 2;
CHANNELS = 3;

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

KERNEL = 3;
PADDING = 1;
CHANNELS = CHANNELS*E_RATIO;

weights = np.zeros([CHANNELS*KERNEL*KERNEL,1])
for i in range(0,CHANNELS*KERNEL*KERNEL):
    weights[i] = i+1;
W = np.asarray(weights).reshape(CHANNELS,KERNEL,KERNEL)

image = np.zeros([CHANNELS,(HEIGHT+2*PADDING),(HEIGHT+2*PADDING)])
image[:,1:-1,1:-1] = output
I = np.asarray(image).reshape(CHANNELS,(HEIGHT+2*PADDING),(HEIGHT+2*PADDING))

output = np.zeros([CHANNELS,HEIGHT,HEIGHT])
for j in range(0, HEIGHT):
    for k in range(0, HEIGHT):
        output[:,j,k] = output[:,j,k] + np.multiply(W,I[:,j:j+KERNEL,k:k+KERNEL]).sum(axis=2).sum(axis=1)
o = output.reshape(CHANNELS*HEIGHT*HEIGHT,1)

IN_CHANNELS = CHANNELS;
OUT_CHANNELS = 3;

weights = np.zeros(IN_CHANNELS*OUT_CHANNELS)
for i in range(0,IN_CHANNELS*OUT_CHANNELS):
    weights[i] = i+1;
W = np.asarray(weights).reshape(OUT_CHANNELS,IN_CHANNELS)

image = output
I = np.asarray(image).reshape(IN_CHANNELS,HEIGHT,HEIGHT)

output = np.zeros([OUT_CHANNELS,HEIGHT,HEIGHT])
for j in range(0, HEIGHT):
    for k in range(0, HEIGHT):
        for i in range(0, OUT_CHANNELS):
            output[i,j,k] = output[i,j,k] + np.multiply(W[i],I[:,j,k]).sum()
o = output.reshape(OUT_CHANNELS*HEIGHT*HEIGHT)