# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import random

image_R  = [[0 for _ in range(16)] for _ in range(16)]
image_G  = [[0 for _ in range(16)] for _ in range(16)]
image_B  = [[0 for _ in range(16)] for _ in range(16)]
paddingImage  = [[0 for _ in range(18)] for _ in range(18)]
#opMode = {"shift_right":0b0100, "shift_left":0b0101, "shift_up":0b0110, "shift_down":0b0111, "scale_down":0b1000, "scale_up":0b1001, "median_filter":0b1100, "ycbcr":0b1101, "census":0b1110} 
opMode = {"shift_right":0b0100, "shift_left":0b0101, "shift_up":0b0110, "shift_down":0b0111, "scale_down":0b1000, "scale_up":0b1001, "ycbcr":0b1101} 


Four = 0
Two  = 1
One  = 2

scale  = 0  #0 4x4, 1 2x2, 2, 1x1
origin = 0

def  display(f):
    if scale == 0: #4x4
        for i in range(4):
            for j in range(4):
                f.write('{:08b}'.format(image_R[origin//16+i][origin%16+j]))
                f.write('{:08b}'.format(image_G[origin//16+i][origin%16+j]))
                f.write('{:08b}\n'.format(image_B[origin//16+i][origin%16+j]))
    if scale == 1: #2x2
        for i in range(2):
            for j in range(2):
                f.write('{:08b}'.format(image_R[origin//16+2*i][origin%16+2*j]))
                f.write('{:08b}'.format(image_G[origin//16+2*i][origin%16+2*j]))
                f.write('{:08b}\n'.format(image_B[origin//16+2*i][origin%16+2*j]))
    if scale == 2: #1x1    
        f.write('{:08b}'.format(image_R[origin//16][origin%16]))
        f.write('{:08b}'.format(image_G[origin//16][origin%16]))
        f.write('{:08b}\n'.format(image_B[origin//16][origin%16]))

def  ycbcr(f):
    if scale == Four: #4x4
        for i in range(4):
            for j in range(4):
                R = image_R[origin//16+i][origin%16+j]
                G = image_G[origin//16+i][origin%16+j]
                B = image_B[origin//16+i][origin%16+j]
                '''
                f.write('{:08b}_'.format(int(np.round(0.25*R+0.625*G))))
                f.write('{:08b}_'.format(int(np.round(-0.125*R-0.25*G+0.5*B+128))))
                f.write('{:08b}\n'.format(int(np.round(0.5*R-0.375*G-0.125*B+128))))
                '''
                '''
                f.write('{:08b}_'.format(int(np.round((2*R+5*G)/8))))
                f.write('{:08b}_'.format(int(np.round((-R-2*G+4*B+1024)/8))))
                f.write('{:08b}\n'.format(int(np.round((4*R-3*G-B+1024)/8))))
                '''
                Y  = (2*R+5*G)>>3 if (2*R+5*G)&4 ==0 else ((2*R+5*G)>>3)+1
                Cb = (-R-2*G+4*B+1024)>>3 if (-R-2*G+4*B+1024)&4 ==0 else ((-R-2*G+4*B+1024)>>3)+1
                Cr = (4*R-3*G-B+1024)>>3 if (4*R-3*G-B+1024)&4 ==0 else ((4*R-3*G-B+1024)>>3)+1
                
                if Y>=255:
                    Y=255
                if Cb>=255:
                    Cb=255
                if Cr>=255:
                    Cr=255
                
                f.write('{:08b}_'.format(Y))
                f.write('{:08b}_'.format(Cb))
                f.write('{:08b}\n'.format(Cr))
                
    if scale == Two: #2x2
        for i in range(2):
            for j in range(2):
                R = image_R[origin//16+2*i][origin%16+2*j]
                G = image_G[origin//16+2*i][origin%16+2*j]
                B = image_B[origin//16+2*i][origin%16+2*j]
                Y  = (2*R+5*G)>>3 if (2*R+5*G)&4 ==0 else ((2*R+5*G)>>3)+1
                Cb = (-R-2*G+4*B+1024)>>3 if (-R-2*G+4*B+1024)&4 ==0 else ((-R-2*G+4*B+1024)>>3)+1
                Cr = (4*R-3*G-B+1024)>>3 if (4*R-3*G-B+1024)&4 ==0 else ((4*R-3*G-B+1024)>>3)+1
                
                if Y>=255:
                    Y=255
                if Cb>=255:
                    Cb=255
                if Cr>=255:
                    Cr=255
                
                f.write('{:08b}_'.format(Y))
                f.write('{:08b}_'.format(Cb))
                f.write('{:08b}\n'.format(Cr))
    if scale == One: #1x1    
        R = image_R[origin//16][origin%16]
        G = image_G[origin//16][origin%16]
        B = image_B[origin//16][origin%16]
        Y  = (2*R+5*G)>>3 if (2*R+5*G)&4 ==0 else ((2*R+5*G)>>3)+1
        Cb = (-R-2*G+4*B+1024)>>3 if (-R-2*G+4*B+1024)&4 ==0 else ((-R-2*G+4*B+1024)>>3)+1
        Cr = (4*R-3*G-B+1024)>>3 if (4*R-3*G-B+1024)&4 ==0 else ((4*R-3*G-B+1024)>>3)+1
        
        if Y>=255:
            Y=255
        if Cb>=255:
            Cb=255
        if Cr>=255:
            Cr=255
        
        f.write('{:08b}_'.format(Y))
        f.write('{:08b}_'.format(Cb))
        f.write('{:08b}\n'.format(Cr))
        
#def  median(f, n):
    
        
random.seed(3)  #1 ycbcr
with open( './golden4.dat', 'w' ) as golden, open( './indata4.dat', 'w' ) as indata, open( './opmode4.dat', 'w' ) as opmode:
    for i in range(16):
        for j in range(16):
          '''
          image_R[i][j]   =   random.randrange(0, 256)    #random between 0-255
          image_G[i][j]   =   random.randrange(0, 256)
          image_B[i][j]   =   random.randrange(0, 256)
          '''
          image_R[i][j]   =   255    #random between 0-255
          image_G[i][j]   =   0
          image_B[i][j]   =   0
          
          #paddingImage[i+1][j+1]  =   image[i][j]
          indata.write('{:08b}_'.format(image_R[i][j])) #08b 8bit 高位補0
          indata.write('{:08b}_'.format(image_G[i][j]))
          indata.write('{:08b}\n'.format(image_B[i][j]))
          
    opmode.write('{:04b}\n'.format(0))   #load image
    
    
    for op_num in range(240):
        
        op = random.sample(opMode.keys(), 1)[0]
        opmode.write('{:04b}\n'.format(opMode[op]))
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
            display(golden)
                    
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
            display(golden)
                    
        elif op == 'shift_up':
            if scale == 0: #4x4
                if origin // 16 > 0:
                    origin -=1*16
            elif scale == 1: #2x2
                if origin // 16 > 1:
                    origin -=2*16
            elif scale == 2: #1x1
                if origin // 16 > 3:
                    origin -=4*16
            display(golden)
        elif op == 'shift_down':
            if scale == 0: #4x4
                if origin // 16 < 12:
                    origin +=1*16
            elif scale == 1: #2x2
                if origin // 16 < 12:
                    origin +=2*16
            elif scale == 2: #1x1
                if origin // 16 < 12:
                    origin +=4*16
            display(golden)
            
        elif op == 'scale_down':
            if scale == 0: #4x4
                scale = 1
            elif scale == 1: #2x2
                scale = 2
            elif scale == 2: #1x1
                scale =2
            display(golden)
        elif op == 'scale_up':
            if scale == 0: #4x4
                scale = 0
            elif scale == 1: #2x2
                if origin%16 >=13 or origin//16>=13:
                    scale = 1
                else:
                    scale = 0
            elif scale == 2: #1x1
                if origin%16 >=14 or origin//16>=14:
                    scale = 2
                else:
                    scale = 1
            display(golden)
            
        elif op == 'ycbcr':
            ycbcr(golden)
        
        
