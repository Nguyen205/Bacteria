"""
Core functions for modifying image data

We keep this separate from image_data.py to avoid making that file a _total mess_
Each of these functions modifies the given ImageData in-place,
  though few (TODO any?) actually modify the underlying numpy arrays
"""

import numpy as np
import numpy.typing as npt
from src.image_data import ImageData, OuterBound

def apply_triangle(image : ImageData, level : float):
    bw_threshold = lambda pixel : pixel > int(level * 255)
    image.bw = bw_threshold(image.gs)

def overlay(image : ImageData):
    # Not entirely sure this thing matters tbh, but whatever
    negate = lambda x : 1 - x
    threshold = image.gsm * negate(image.bw)
    result = np.array(np.zeros((*image.gsm.shape, 3)))
    for i in range(len(image.gsm)):
        for j in range(len(image.gsm[i])):
            result[i, j, 0] = image.gsm[i, j]
            result[i, j, 1] = threshold[i, j]
            result[i, j, 2] = threshold[i, j]
    image.bw_overlay = result

def cut(image : ImageData):
    image.bwc = image.bw.copy()
    if not ImageData._cutoff:
        return
    rows = image.gsm.shape[0]
    cols = image.gsm.shape[1]
    gaps : list[int] = []
    for i in range(cols):
        found = False
        for j in range(rows-1, -1, -1): # loop bottom to top
            if image.gsm[j,i] == 0: # Found the line, make it the bottom
                found = True
                gap = rows-j-1
                gaps.append(gap)
                for k in range(rows-1, gap-1, -1): # loop backwards through `j`
                    image.bwc[k,i] = image.bwc[k-gap,i]
                for k in range(gap): # fill the rest up with black
                    image.bwc[k,i] = 0
                break # We found the line and are done
        if not found:
            gaps.append(0)
    image.gaps = gaps
    
    
def _label_connected(array : npt.NDArray[np.int64]) -> list[int]:
    # Assumes array consists of only 0 and -1 values

    # could use a queue, but stacks are faster with a list and are otherwise the same
    def label_from_index(value : int, row : int, col : int) -> int:
        stack = [(row, col)]
        count = 0
        while len(stack) > 0:
            row, col = stack.pop()
            if array[row, col] == value:
                continue
            array[row, col] = value
            count += 1
            rtc = [0]
            ctc = [0]
            if row != 0:
                rtc.append(-1)
            if col != 0:
                ctc.append(-1)
            if row < array.shape[0] - 1:
                rtc.append(1)
            if col < array.shape[1] - 1:
                ctc.append(1)
            for xoff in rtc:
                for yoff in ctc:
                    x = row + xoff
                    y = col + yoff
                    if array[x, y] == -1:
                        stack.append((x, y))
                    elif array[x, y] != 0 and array[x, y] != value:
                        raise ValueError(f'Hit the same cluster twice between {value} and {array[x, y]}')
        return count

    counts : list[int] = []
    for i in range(len(array)):
        for j in range(len(array[0])):
            if array[i, j] == -1:
                count = label_from_index(len(counts) + 1, i, j)
                counts.append(count)

    return counts

def calc_outliers(image : ImageData, out_cutoff : int):
    # list of y-values of first white pixel in each column
    # if we're ignoring the outer columns, those values are replaced with Outerbound
    h_plot_corr : list[OuterBound] = [] 
    height, width = image.gsm.shape
    # Yes, these loops are flipped, this is quite intentional
    for j in range(width):
        found = False
        for i in range(height):
            if image.bwc[i, j] == 1:
                h_plot_corr.append(OuterBound(i))
                found = True
                break
        if not found:
            h_plot_corr.append(OuterBound(height))
            
    negative = lambda x : -1 * x
    clusters = negative(image.bwc)
    np.set_printoptions(threshold=np.inf)
    cluster_counts = _label_connected(clusters)

    result = image.bwc.copy()
    outliers : list[bool] = [False] * width
    # again, flipped loops
    for w in range(width):
        h = h_plot_corr[w].value
        while h < height:
            val = h_plot_corr[w].value
            if clusters[val, w] > 0:
                outl_value = cluster_counts[clusters[val, w] - 1]
            else:
                outl_value = 0
            if clusters[val, w] == 0:
                h_plot_corr[w] = OuterBound(val + 1)
            elif outl_value <= out_cutoff and h < height - 1:
                h_plot_corr[w] = OuterBound(val + 1)
                result[val, w] = 0
                outliers[w] = True
            else:
                break
            h += 1

    if ImageData._side_cutoff:
        for i in range(width):
            if h_plot_corr[i].value != height:
                break
            if outliers[i]:
                h_plot_corr[i].to_edge_outl()
            else:
                h_plot_corr[i].to_blank()
        for i in range(width-1, -1, -1):
            current = h_plot_corr[i]
            if current.is_blank() or current.value != height:
                break
            if outliers[i]:
                h_plot_corr[i].to_edge_outl()
            else:
                h_plot_corr[i].to_blank()

    for i in range(1, len(h_plot_corr)-1):
        if h_plot_corr[i]._val > (height-3) and \
            h_plot_corr[i-1]._val <= (height-30) and \
                h_plot_corr[i+1]._val <= (height-30):
            h_plot_corr[i] = OuterBound(int((h_plot_corr[i-1]._val + \
                h_plot_corr[i+1]._val) / 2))

    image.outl = result
    image.h_plot_corr = h_plot_corr

def _color_spot(arr : npt.NDArray[np.uint8], rindex : int, cindex : int, 
color : list[int], blob_size : int, diamond : bool = False):
    roffsets = [0]
    coffsets = [0]
    for test in range(-blob_size, blob_size + 1):
        if test == 0:
            continue
        if rindex + test >= 0 and rindex + test < arr.shape[0]:
            roffsets.append(test)
        if cindex + test >= 0 and cindex + test < arr.shape[1]:
            coffsets.append(test)
    for yoffset in roffsets:
        for xoffset in coffsets:
            # Diamond!
            if diamond and max(abs(xoffset + yoffset), abs(xoffset - yoffset)) > blob_size:
                continue
            arr[rindex + yoffset, cindex + xoffset] = color

def _show_outliers_on_image(image_arr : npt.NDArray[np.uint8], 
image : ImageData, gaps : list[int] | None = None) ->\
npt.NDArray[np.uint8]:
    # modifies image_arr
    make_colored = lambda x : [x, x, x]
    result = np.array([[make_colored(e) for e in v] 
        for v in image_arr]) # color bashing
    if ImageData._side_cutoff:
        total = 0
        count = 0
        for current in image.h_plot_corr:
            if current.is_reg():
                total += current.value
                count += 1
        avg = int(total / count)
    else:
        total = 0
        for item in image.h_plot_corr:
            if not item.is_blank():
                total += item.value
        avg = int(total / len(image.h_plot_corr))
    
    # Separate loop to avoid artifacts
    for index in range(len(image.h_plot_corr)):
        if (index % (_DASH_SIZE * 2)) < (_DASH_SIZE - 
            _DASH_BLOB - 3): # Dashed line
            if gaps is None: # no dashed line if cutoff
                _color_spot(result, avg, index, 
                    [False, True, False], _DASH_BLOB)

    for index in range(len(image.h_plot_corr)):
        current = image.h_plot_corr[index]
        if current.is_blank():
            continue
        y_value = current.value
        gap = 0
        if gaps is not None:
            gap = gaps[index]
        if y_value >= result.shape[0]:
            y_value = result.shape[0] - 1
        if current.is_reg():
            _color_spot(result, y_value - gap, index, 
                [False, True, False], _BLOB_SIZE, True)
        for pixel in range(gap, y_value):
            if image_arr[pixel - gap][index] != 0:
                _color_spot(result, pixel - gap, index, 
                    [True, False, False], _BLOB_SIZE, True)

    return result

_BLOB_SIZE = 2
_DASH_SIZE = 12
_DASH_BLOB = 3

def show_outliers(image : ImageData):
    result = image.bwc.copy()
    result = _show_outliers_on_image(result, image)
    image.outl2 = result

def show_flattened_outliers(image : ImageData):
    result = image.bw.copy()
    result = _show_outliers_on_image(result, image, image.gaps)
    image.outl3 = result

def show_blackout_gaps(image : ImageData):
    result = image.bw.copy() # doesn't actually matter much
    for col in range(len(image.h_plot_corr)):
        current = image.h_plot_corr[col]
        height = len(image.bw)
        if current.is_blank(): # black out the column
            for row in range(height-1, -1, -1):
                result[row][col] = False
            continue
        y_value = current.value
        gap = image.gaps[col]
        for row in range(height-1, -1, -1):
            if row > height - gap or row < y_value - gap:
                result[row][col] = False
            else:
                result[row][col] = True
        
    image.blackout_gaps = result