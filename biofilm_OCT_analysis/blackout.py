"""
Blacks out pixels above a fixed thin GSM line
This script could be merged with OCTA main, and includes substantially copied code
As a result, this script is minimally commented
"""

import numpy as np
from PIL import Image
import sys
import os
import pathlib

class ImageFiles:
    def __init__(self, filename : str, gsm : bool):
        self._gsm : str | None = None
        self._bw : str | None = None
        self.gsm_image = None
        self.bw_image = None
        if gsm:
            self.gsm = filename
        else:
            self.bw = filename
    @property
    def gsm(self):
        return self._gsm
    @property
    def bw(self):
        return self._bw
    
    @gsm.setter
    def gsm(self, filename : str):
        assert self._gsm is None
        self._gsm = filename
        self.gsm_image = read_image_full(filename)
    @bw.setter
    def bw(self, filename : str):
        assert self._bw is None
        self._bw = filename
        self.bw_image = read_image_full(filename)

    def __str__(self):
        return f'({self.gsm}, {self.bw})'
    def __repr__(self):
        return f'ImageFiles{str(self)}'

def read_image_full(filename : str) -> np.ndarray:
    assert os.path.basename(filename).startswith('gsm') \
        or os.path.basename(filename).startswith('bw'), \
        f'{filename} does not have a basename starting with gsm or bw'
    assert filename.endswith('.tif'), f'{filename} does not end with .tif'
    result = np.array(Image.open(filename))
    if len(result.shape) == 3: # Awful, but whatever, it runs for testing
        result = np.array([[sum(x[:3]) / 3 for x in y] for y in result])
    return result

def get_files() -> tuple[str, list[ImageFiles]]:
    loc = sys.argv[1]
    assert os.path.exists(loc)    
    if os.path.isfile(loc):
        return os.path.dirname(loc), [loc]
    file_map = {}
    file_list : list[ImageFiles] = []
    for file in os.listdir(loc):
        filename = os.path.join(loc, file)
        if os.path.isfile(filename):
            if file.startswith('gsm'):
                suffix = file[3:]
                if suffix in file_map:
                    file_list[file_map[suffix]].gsm = filename
                else:
                    file_map[suffix] = len(file_list)
                    file_list.append(ImageFiles(filename, True))
            if file.startswith('bw'):
                suffix = file[2:]
                if suffix in file_map:
                    file_list[file_map[suffix]].bw = filename
                else:
                    file_map[suffix] = len(file_list)
                    file_list.append(ImageFiles(filename, False))
                
    return loc, file_list 

def write_image_file(path : str, image : np.ndarray):
    if len(image.shape) == 3:
        color = lambda x : np.uint8(255 * x)
        Image.fromarray(color(image), mode='RGB').save(path)
    else:
        Image.fromarray(image).save(path)


def write_image_files(root : str, image_data : ImageFiles):
    assert image_data.gsm.endswith('.tif')
    assert type(image_data) == ImageFiles
    path = os.path.join(root, os.path.basename(image_data.gsm))
    image = image_data.gsm_image
    write_image_file(path, image)
    if image_data.bw is not None:
        assert image_data.bw.endswith('.tif')
        bw_path = os.path.join(root, os.path.basename(image_data.bw))
        bw_image = image_data.bw_image
        write_image_file(bw_path, bw_image)

def blackout_image(image_data : ImageFiles):
    image = image_data.gsm_image
    bw_image = image_data.bw_image
    assert image.shape == bw_image.shape
    for col in range(image.shape[1]):
        found = False
        for row in range(image.shape[0]-1, -1, -1):
            if image[row,col] == 0:
                found = True
                for urow in range(row, image.shape[0]):
                    image[urow, col] = 0
                    bw_image[urow, col] = 0
            if found:
                break
        if not found:
            print(f'Error, no black line found on \
                column {col} of image {image_data.filename}')
            exit()

def main():
    if len(sys.argv) != 2:
        print('Give exactly one argument (name of folder or file)')
        print('Note that only files with prefixes gsm and bw are worked on')
        exit()
    root, images = get_files()
    results = os.path.join(root, 'blackout/')
    if os.path.exists(results):
        print(f'Will overwrite existing path {results}')
        check = input('ok? (y/n): ')
        if check.lower() != 'y':
            print('ok, exiting')
            exit()
    pathlib.Path(results).mkdir(parents=True, exist_ok=True)
    for image_data in images:
        blackout_image(image_data)
        write_image_files(results, image_data)

if __name__ == "__main__":
    main()