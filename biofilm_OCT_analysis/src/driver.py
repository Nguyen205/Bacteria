'''
Functions for abstracting dataflow from main.py
'''

from src.util import print_verbose, print_normal
import src.calc
import src.image_mod
import src.io_manager
import src.util
import src.options
from src.image_data import ImageData

def write_sizes(height : float, width : float):
    assert type(height) == float
    assert type(width) == float
    ImageData.set_height(height)
    ImageData.set_width(width)

def write_cutoff(cutoff : bool, side_cutoff : bool):
    assert type(cutoff) == bool
    assert type(side_cutoff) == bool
    ImageData.set_cutoff(cutoff)
    ImageData.set_side_cutoff(side_cutoff)

def write_bw(data : list[ImageData]):
    print_normal('Calculating thresholds and writing b&w')
    failed_threshold = False
    for image in data:
        hist, bin_edges = src.calc.image_histogram(image)
        hist[0] = 0 # Ignore 0-values for thresholding
        level = src.calc.triangle_method(hist, len(bin_edges) - 1)
        level += 2 / 256 # magic numbers, hooray!  Used for offset, based on ImageJ survey apparently
        src.image_mod.apply_triangle(image, level)
        if not image.bw.any():
            print_normal(f'Image {image._name} failed to threshold')
            failed_threshold = True
            continue
        src.io_manager.write_image('image', image.bw, f'bw_{image.name}.tif')
    if failed_threshold:
        print(f'At least one image failed to threshold, exiting')
        exit()

def read_bw(data : list[ImageData]):
    print_normal('Reading b&w')
    for image in data:
        if image.bw is not None:
            continue
        filename = f'bw_{image.name}.tif'
        print_verbose(f'Attempting to reuse {filename}')
        image.bw = src.io_manager.read_image('bw', filename, True)

def write_bwc(data : list[ImageData]):
    print_normal('Writing b&w with cut')
    failed_threshold = False
    for image in data:
        src.image_mod.cut(image)
        if not image.bwc.any():
            print_normal(f'Image {image._name} failed to cut')
            failed_threshold = True
            continue
        src.io_manager.write_image('image', image.bwc, f'bwc_{image.name}.tif')
    if failed_threshold:
        print(f'At least one image failed to cut, exiting')
        exit()

def read_bwc(data : list[ImageData]):
    print_normal('Reading b&w with cut')
    for image in data:
        if image.bwc is not None:
            continue
        filename = f'bwc_{image.name}.tif'
        print_verbose(f'Attempting to reuse {filename}')
        image.bwc = src.io_manager.read_image('bwc', filename)

def calculate_outliers(data : list[ImageData]):
    print_normal('Determining outliers')
    # TODO: _height fix
    out_area = 360
    out_cutoff = round(out_area/(ImageData._height*1000/data[0].gsm.shape[0]*
        ImageData._width*1000/data[0].gsm.shape[1]))
    for image in data:
        if image.outl is not None:
            raise Exception(f'Unknown error, {image} was pre-assigned outlier')
            
        filename  = f'outl_{image.name}.tif'
        filename2 = f'outl2_{image.name}.tif'
        src.image_mod.calc_outliers(image, out_cutoff)
        src.io_manager.write_image('image', image.outl, filename)
        src.image_mod.show_outliers(image)
        src.io_manager.write_image('image', image.outl2, filename2)
        if ImageData._cutoff:
            filename3 = f'outl3_{image.name}.tif'
            filename_blackout = f'blackout_{image.name}.tif'
            src.image_mod.show_flattened_outliers(image)
            src.io_manager.write_image('image', image.outl3, filename3)
            src.image_mod.show_blackout_gaps(image)
            src.io_manager.write_image('image', image.blackout_gaps, filename_blackout)

def oct_analysis(data : list[ImageData]):
    print_normal('Performing OCT Analysis')
    to_write = [['Filename', 'Mean BF thickness (µm)', 'R_a (µm)', 'R_a\'\'']]
    to_write.append([])
    for image in data:
        image.data = src.calc.build_calculated(image)
        to_write.append([f'bwc_{image.name}.tif', image.data.mem_length,
            image.data.ra, image.data.ra2])
        
    avgs = [0.] * (len(to_write[2]) - 1)
    for x in to_write[2:]:
        for i in range(1, len(to_write[2])):
            avgs[i-1] += x[i]
    avgs = [avg / (len(to_write)-2) for avg in avgs]
    to_write.append(['Averages'] + avgs)
    to_write.insert(-1, [])
    src.io_manager.write_csv('csv', to_write)