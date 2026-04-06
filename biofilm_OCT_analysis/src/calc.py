"""
Core functions for calculating information about image matrices

Unlike image_mod, all these functions are _not_ stateful and so return something
"""

import numpy as np
import numpy.typing as npt
import src.util
import math
from src.image_data import ImageData
from src.calculated_data import Calculated

def image_histogram(image : ImageData) -> tuple[npt.NDArray[np.float64], npt.NDArray[np.float64]]:
    """
    Calculates a histogram of the image data

    """

    # Assumes the image is grayscale
    arr, bins = np.histogram(image.gs, list(range(257)))
    return (arr, bins)

def triangle_method(hist : npt.NDArray[np.float64], num_bins: int) -> float:
    """
    Calculates the "cutoff" for thresholding individual pixels
    Requires image metadata to be given in hist to properly calculate cutoffs
    Note that this function is intended to match the MATLAB reference code
      it is _not_ the most cutting edge thresholding approach
      you can do much better!
    """
    def get_max_indices(arr : npt.NDArray[np.float64] | list[float]) -> tuple[float, list[int]]:
        max_indices = []
        max_val = float('-inf')
        for index, value in enumerate(arr):
            if math.isclose(value, max_val, rel_tol=src.util.EPS):
                max_indices.append(index)
            elif value > max_val:
                max_indices = [index]
                max_val = value
        return max_val, max_indices
        
    max_val, max_indices = get_max_indices(hist)

    # Has to be a separate loop to manage max_val cutoff properly
    first_non_zero = -1
    last_non_zero = -1
    for index, value in enumerate(hist):
        if value > max_val * src.util.EPS:
            if first_non_zero == -1:
                first_non_zero = index
            last_non_zero = index

    if first_non_zero == -1 or last_non_zero == -1:
        raise ValueError(f'Invalid histogram, all zeroes calculated: {hist}')

    avg_index = sum(max_indices) / len(max_indices) # average _index_ of a max
    lspan = avg_index - first_non_zero
    rspan = last_non_zero - avg_index
    flipped = False
    if rspan > lspan:
        hist = np.flip(hist) # flip is fine, fliplr for matching previous
        a = num_bins - last_non_zero - 1 # we use -1 cause 0-indexing with num_bins!
        b = num_bins - avg_index - 1
        flipped = True
    else:
        a = first_non_zero
        b = avg_index
    
    diff = b - a
    m = max_val / diff
    L = []
    for x1 in range(int(diff)):
        y1 = hist[x1 + a]
        beta = y1 + (x1 / m)
        x2 = beta / (m + 1 / m)
        y2 = m * x2
        L.append(((y2 - y1)**2 + (x2 - x1)**2)**.5)

    _, max_l_indices = get_max_indices(L)

    # we add 2 extra to account for zero indexing (twice, once for `a` and once for l_indices)
    level = a + 2 + sum(max_l_indices) / len(max_l_indices)

    if flipped:
        level = num_bins - level + 1

    return level / num_bins

def build_calculated(image : ImageData) -> Calculated:
    """
    Calculates statistical information about the given image
    """
    height, width = image.gsm.shape
    z_scale = ImageData._height * 1000. / height
    x_scale = ImageData._width * 1000. / width

    z_local_corr = []
    for corrected in image.h_plot_corr:
        if corrected.is_reg():
            z_local_corr.append((height - corrected.value) * z_scale)
        else:
            width -= 1

    avg = sum(z_local_corr) / len(z_local_corr)
    mem_length = avg
    abs_diffs = [abs(x - avg) for x in z_local_corr]
    ra = float(1./len(z_local_corr) * 
        sum(abs_diffs))
    # 1./numel(Z_local_corr(:)) .* sum(abs(Z_local_corr(:) -
    #   mean(Z_local_corr(:)))) ./ mean(Z_local_corr(:));    
    ra2 = 1 / len(z_local_corr) * sum(abs_diffs) / avg
    result = Calculated(mem_length, ra, ra2, 0.0, 
        (0.0, 0.0, 0.0, 0.0), 0.0, 0, 0., 0., 0.)

    return result