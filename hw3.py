# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import random
image  = [[0 for _ in range(16)] for _ in range(16)]
opMode = {"shift_right":0b0100, "shift_left":0b0101, "shift_up":0b0110, "shift_down":0b0111, "scale_down":0b1000, "scale_up":0b1001, "median_filter":0b1100, "ycbcr":0b1101, "census":0b1110} 

scale  = 0  #0 4x4, 1 2x2, 2, 1x1
origin = 0

with open( './golden4', 'w' ) as golden, open( './indata4', 'w' ) as indata, open( './opmode4', 'w' ) as opmode:
    for i in range(16):
        for j in range(16):
          image[i][j]   =   random.randrange(0, 256)    #random between 0-255
          indata.write('{:08b}\n'.format(image[i][j])) #08b 8bit 高位補0
          print('{:08b}'.format(image[i][j]))
          
    opmode.write('{:04b}'.format(0))   #load image
    op = random.sample(opMode.keys(), 1)[0]
    if op == 'shift_right':
        if scale == 0: #4x4
            if origin % 16 < 12:
                origin +=1
        elif scale == 1: #2x2
            if origin % 16 < 12:
                origin +=2
        elif scale == 2: #1x1
            if origin % 16 < 12:
                origin +=4
                
    elif op == 'shift_left':
        if scale == 0: #4x4
            if origin % 16 > 0:
                origin -=1
        elif scale == 1: #2x2
            if origin % 16 > 1:
                origin -=2
        elif scale == 2: #1x1
            if origin % 16 > 3:
                origin -=4
                
    elif op == 'shift_up':
        if scale == 0: #4x4
            if origin // 16 > 0:
                origin -=1
        elif scale == 1: #2x2
            if origin // 16 > 1:
                origin -=2
        elif scale == 2: #1x1
            if origin // 16 > 3:
                origin -=4
    elif op == 'shift_down':
        if scale == 0: #4x4
            if origin // 16 > 0:
                origin -=1
        elif scale == 1: #2x2
            if origin // 16 > 1:
                origin -=2
        elif scale == 2: #1x1
            if origin // 16 > 3:
                origin -=4
