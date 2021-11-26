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
opMode = {"shift_right":0b0100, "shift_left":0b0101, "shift_up":0b0110, "shift_down":0b0111, "scale_down":0b1000, "scale_up":0b1001, "ycbcr":0b1101, "median_filter":0b1100, "census":0b1110} 


Four = 1
Two  = 2
One  = 4

scale  = Four  #0 4x4, 1 2x2, 2, 1x1
origin = 0

def  display(f):
    if scale == Four: #4x4
        for i in range(4):
            for j in range(4):
                f.write('{:08b}'.format(image_R[origin//16+i][origin%16+j]))
                f.write('{:08b}'.format(image_G[origin//16+i][origin%16+j]))
                f.write('{:08b}\n'.format(image_B[origin//16+i][origin%16+j]))
    if scale == Two: #2x2
        for i in range(2):
            for j in range(2):
                f.write('{:08b}'.format(image_R[origin//16+2*i][origin%16+2*j]))
                f.write('{:08b}'.format(image_G[origin//16+2*i][origin%16+2*j]))
                f.write('{:08b}\n'.format(image_B[origin//16+2*i][origin%16+2*j]))
    if scale == One: #1x1    
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
    
        
random.seed(5)  #1 ycbcr
with open( './golden4.dat', 'w' ) as golden, open( './indata4.dat', 'w' ) as indata, open( './opmode4.dat', 'w' ) as opmode:
    for i in range(16):
        for j in range(16):
          
          image_R[i][j]   =   random.randrange(0, 256)    #random between 0-255
          image_G[i][j]   =   random.randrange(0, 256)
          image_B[i][j]   =   random.randrange(0, 256)
          
          '''
          image_R[i][j]   =   255    #random between 0-255
          image_G[i][j]   =   0
          image_B[i][j]   =   0
          '''
          
          #paddingImage[i+1][j+1]  =   image[i][j]
          indata.write('{:08b}_'.format(image_R[i][j])) #08b 8bit 高位補0
          indata.write('{:08b}_'.format(image_G[i][j]))
          indata.write('{:08b}\n'.format(image_B[i][j]))
          
    opmode.write('{:04b}\n'.format(0))   #load image
    
    
    for op_num in range(50):
        
        op = random.sample(opMode.keys(), 1)[0]
        opmode.write('{:04b}\n'.format(opMode[op]))
        #golden.write('//{:04b}\n//{:d}\n'.format(opMode[op],op_num+1))
        #golden.write('//{:04b}\n'.format(opMode[op]))
        if op == 'shift_right':
            if scale == Four: #4x4
                if origin % 16 < 12:
                    origin +=1
            elif scale == Two: #2x2
                if origin % 16 < 12:
                    origin +=2
            elif scale == One: #1x1
                if origin % 16 < 12:
                    origin +=4
            display(golden)
                    
        elif op == 'shift_left':
            if scale == Four: #4x4
                if origin % 16 > 0:
                    origin -=1
            elif scale == Two: #2x2
                if origin % 16 > 1:
                    origin -=2
            elif scale == One: #1x1
                if origin % 16 > 3:
                    origin -=4
            display(golden)
                    
        elif op == 'shift_up':
            if scale == Four: #4x4
                if origin // 16 > 0:
                    origin -=1*16
            elif scale == Two: #2x2
                if origin // 16 > 1:
                    origin -=2*16
            elif scale == One: #1x1
                if origin // 16 > 3:
                    origin -=4*16
            display(golden)
        elif op == 'shift_down':
            if scale == Four: #4x4
                if origin // 16 < 12:
                    origin +=1*16
            elif scale == Two: #2x2
                if origin // 16 < 12:
                    origin +=2*16
            elif scale == One: #1x1
                if origin // 16 < 12:
                    origin +=4*16
            display(golden)
            
        elif op == 'scale_down':
            if scale == Four: #4x4
                scale = Two
            elif scale == Two: #2x2
                scale = One
            elif scale == One: #1x1
                scale = One
            display(golden)
        elif op == 'scale_up':
            if scale == Four: #4x4
                scale = Four
            elif scale == Two: #2x2
                if origin%16 >=13 or origin//16>=13:
                    scale = Two
                else:
                    scale = Four
            elif scale == One: #1x1
                if origin%16 >=14 or origin//16>=14:
                    scale = One
                else:
                    scale = Two
            display(golden)
            
        elif op == 'ycbcr':
            ycbcr(golden)
        elif op == 'median_filter':
            x = origin % 16
            y = origin // 16
            
            if scale == One:
                imageSize = 4
                displaySize = 1
            elif scale == Two:
                imageSize = 8
                displaySize = 2
            elif scale == Four:
                imageSize = 16
                displaySize = 4
            
            while x >= 0:
                x -= scale
            x += scale
            while y >= 0:
                y -= scale
            y += scale
            paddingImage_R  = [[0 for _ in range(imageSize + 2)] for _ in range(imageSize + 2)]
            paddingImage_G  = [[0 for _ in range(imageSize + 2)] for _ in range(imageSize + 2)]
            paddingImage_B  = [[0 for _ in range(imageSize + 2)] for _ in range(imageSize + 2)]
            
            for i in range(imageSize):#padding image initialize
                for j in range(imageSize):
                    paddingImage_R[i+1][j+1]= image_R[y+i*scale][x+j*scale]
                    paddingImage_G[i+1][j+1]= image_G[y+i*scale][x+j*scale]
                    paddingImage_B[i+1][j+1]= image_B[y+i*scale][x+j*scale]
                    
            for i in range(displaySize):
                for j in range(displaySize):
                    sortList_R = []
                    sortList_G = []
                    sortList_B = []
                    paddingImage_R
                    center_y = (origin // 16 //scale) + i
                    center_x = (origin % 16  //scale) + j
                    for filter_row in range(3):
                        for filter_col in range(3):
                            sortList_R.append(paddingImage_R[center_y+1-1+filter_row][center_x+1-1+filter_col]) 
                            sortList_G.append(paddingImage_G[center_y+1-1+filter_row][center_x+1-1+filter_col]) 
                            sortList_B.append(paddingImage_B[center_y+1-1+filter_row][center_x+1-1+filter_col]) 
                            
                    sortList_R.sort()
                    sortList_G.sort()
                    sortList_B.sort()
                    
                    golden.write('{:08b}'.format(sortList_R[4]))
                    golden.write('{:08b}'.format(sortList_G[4]))
                    golden.write('{:08b}\n'.format(sortList_B[4]))
                    
                    
        elif op == 'census':
            x = origin % 16
            y = origin // 16
            
            if scale == One:
                imageSize = 4
                displaySize = 1
            elif scale == Two:
                imageSize = 8
                displaySize = 2
            elif scale == Four:
                imageSize = 16
                displaySize = 4
            
            while x >= 0:
                x -= scale
            x += scale
            while y >= 0:
                y -= scale
            y += scale
            paddingImage_R  = [[0 for _ in range(imageSize + 2)] for _ in range(imageSize + 2)]
            paddingImage_G  = [[0 for _ in range(imageSize + 2)] for _ in range(imageSize + 2)]
            paddingImage_B  = [[0 for _ in range(imageSize + 2)] for _ in range(imageSize + 2)]
            
            for i in range(imageSize):#padding image initialize
                for j in range(imageSize):
                    paddingImage_R[i+1][j+1]= image_R[y+i*scale][x+j*scale]
                    paddingImage_G[i+1][j+1]= image_G[y+i*scale][x+j*scale]
                    paddingImage_B[i+1][j+1]= image_B[y+i*scale][x+j*scale]
                    
            for i in range(displaySize):
                for j in range(displaySize):
                    paddingImage_R
                    center_y = (origin // 16 //scale) + i
                    center_x = (origin % 16  //scale) + j
                    for filter_row in range(3):
                        for filter_col in range(3):
                            if filter_row == 1 and filter_col ==1:
                                continue
                            if paddingImage_R[center_y+1-1+filter_row][center_x+1-1+filter_col] <= paddingImage_R[center_y+1][center_x+1]:
                                golden.write('{:01b}'.format(0))
                            else:
                                golden.write('{:01b}'.format(1))
                    
                                
                    for filter_row in range(3):
                        for filter_col in range(3):
                            if filter_row == 1 and filter_col ==1:
                                continue
                            if paddingImage_G[center_y+1-1+filter_row][center_x+1-1+filter_col] <= paddingImage_G[center_y+1][center_x+1]:
                                golden.write('{:01b}'.format(0))
                            else:
                                golden.write('{:01b}'.format(1))
                    for filter_row in range(3):
                        for filter_col in range(3):
                            if filter_row == 1 and filter_col ==1:
                                continue
                            if paddingImage_B[center_y+1-1+filter_row][center_x+1-1+filter_col] <= paddingImage_B[center_y+1][center_x+1]:
                                golden.write('{:01b}'.format(0))
                            else:
                                golden.write('{:01b}'.format(1))
                            
                    golden.write('\n')
    
                    
                    golden.write('{:08b}'.format(sortList_R[4]))
                    golden.write('{:08b}'.format(sortList_G[4]))
                    golden.write('{:08b}\n'.format(sortList_B[4]))
                    
     
        
