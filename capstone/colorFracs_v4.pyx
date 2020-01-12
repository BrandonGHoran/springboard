from libc.stdio cimport *
import cython
import numpy as npP
cimport numpy as np
from libc.math cimport ceil

#in v3, I add the function to return the reconstructed image
#in v4, I add the function to return both fracs and reconstructedImage at the same time, as well as the function to get the cR, cG, cB from the raw image and the cL


def colorsToLabels(image_, colors_, cL_):

    cdef np.ndarray cL = cL_
    cdef int lencL = len(cL)
    cdef np.ndarray cR = npP.zeros(lencL)
    cdef np.ndarray cG = npP.zeros(lencL)
    cdef np.ndarray cB = npP.zeros(lencL)

    cdef np.ndarray image = image_
    cdef np.ndarray colors = colors_

    cdef list cs = [cR, cG, cB]

    cs = get_cRcGcB(image, colors, cs, cL)

    return cs[0], cs[1], cs[2]

cdef get_cRcGcB(np.ndarray image, np.ndarray colors, list cs, np.ndarray cL):

    cdef np.ndarray cR = cs[0]
    cdef np.ndarray cG = cs[1]
    cdef np.ndarray cB = cs[2]

    cdef int c = 0

    cdef int i = 0
    cdef int j = 0

    cdef np.ndarray color = colors[0]

    for i in range(0, len(image)):
        for j in range(0, len(image[0])):
            color = colors[cL[c]]
            cR[c] = color[0]
            cG[c] = color[1]
            cB[c] = color[2]
            c+=1

    cs = [cR, cG, cB]

    return cs

def colorFrac(image_, colors_, cR_, cG_, cB_, cL_, nColors_, reconstructImages_):
    
    cdef np.ndarray cR = cR_
    cdef np.ndarray cG = cG_
    cdef np.ndarray cB = cB_
    cdef np.ndarray cL = cL_
    cdef np.ndarray image = image_
    cdef np.ndarray colors = colors_
    cdef int nColors = nColors_
    cdef np.ndarray reconstructedImage = image

    cdef int callSwitch = reconstructImages_

    #cdef np.ndarray tup = [0] (npP.zeros(1))

    cdef np.ndarray fracs = npP.zeros(nColors, dtype = npP.float)

    #cdef np.ndarray indices = npP.zeros(1)
    #cdef np.ndarray sublistColors = npP.zeros(1)
    
    cdef np.ndarray color = npP.zeros(3)

    cdef list fracs_img = [fracs, reconstructedImage]

    #v2 usese a colorMap which converts the color lookup to constant time which works for 
    #cases when the colors are integers
    cdef np.ndarray colorMap = npP.zeros(shape=(256,256,256))
    colorMap = fillColorMap(cR, cG, cB, cL, len(cR), colorMap)

    if callSwitch == 0:
        return calcFracs(image, fracs, cL, colorMap)
    elif callSwitch == 1:
        return reconstruct_im(image, fracs, cL, colorMap, reconstructedImage, colors)
    else:
        return both(image, fracs_img, cL, colorMap, colors)

cdef np.ndarray fillColorMap(np.ndarray cR, np.ndarray cG, np.ndarray cB, np.ndarray cL, int size, np.ndarray colorMap):

    cdef int i = 0
    for i in range(0, size):
        colorMap[cR[i]][cG[i]][cB[i]] = cL[i]
    return colorMap

cdef list both(np.ndarray image, list fracs_img, np.ndarray cL, np.ndarray colorMap, np.ndarray colors):

    cdef int lencL = len(cL)
    cdef int R = -1
    cdef int G = -1
    cdef int B = -1

    cdef int label = -1

    cdef int i = -1
    cdef int j = -1

    cdef np.ndarray fracs = fracs_img[0]
    cdef np.ndarray reconstructedImage = fracs_img[1]

    for i in range(0, len(image)):
        for j in range(0, len(image[0])):
            color = image[i][j]
            R = color[0]
            G = color[1]
            B = color[2]
            label = int(colorMap[R][G][B])
            fracs[label] += 1
            reconstructedImage[i][j][0] = colors[label][0]
            reconstructedImage[i][j][1] = colors[label][1]
            reconstructedImage[i][j][2] = colors[label][2]

    fracs/=(len(image)*len(image[0]))
    fracs_img = [fracs, reconstructedImage]

    return fracs_img



cdef np.ndarray calcFracs(np.ndarray image, np.ndarray fracs, np.ndarray cL, np.ndarray colorMap):

    cdef int lencL = len(cL)
    cdef int R = -1
    cdef int G = -1
    cdef int B = -1

    cdef int label = -1

    cdef int i = -1
    cdef int j = -1

    for i in range(0, len(image)):
        for j in range(0, len(image[0])):
            color = image[i][j] #comes from image
            R = color[0]
            G = color[1]
            B = color[2]
            label = int(colorMap[R][G][B])
            fracs[label] += 1

    fracs/=(len(image)*len(image[0]))
    return fracs

cdef np.ndarray reconstruct_im(np.ndarray image, np.ndarray fracs, np.ndarray cL, np.ndarray colorMap, np.ndarray reconstructedImage, np.ndarray colors):

    cdef int lencL = len(cL)
    cdef int R = -1
    cdef int G = -1
    cdef int B = -1

    cdef int label = -1

    cdef int i = -1
    cdef int j = -1

    for i in range(0, len(image)):
        for j in range(0, len(image[0])):
            color = image[i][j]
            R = color[0]
            G = color[1]
            B = color[2]
            label = int(colorMap[R][G][B])
            #fracs[label] += 1
            #set new color
            reconstructedImage[i][j][0] = colors[label][0]
            reconstructedImage[i][j][1] = colors[label][1]
            reconstructedImage[i][j][2] = colors[label][2]

    #fracs/=(len(image)*len(image[0]))
    #return fracs
    return reconstructedImage
