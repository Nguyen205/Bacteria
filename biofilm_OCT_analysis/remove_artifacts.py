import numpy as np
from PIL import Image
import sys
import os
import pathlib

class ImageFile:
    def __init__(self, blackout : str):
        self.blackout = blackout
        self.blackout_data = read_image_full(blackout)

    def __str__(self):
        return f'({self.blackout}, {self.blackout_data.shape})'
    def __repr__(self):
        return f'ImageFiles{str(self)}'

def read_image_full(filename : str) -> np.ndarray:
    assert os.path.basename(filename).startswith('blackout')
    assert filename.endswith('.tif'), f'{filename} does not end with .tif'
    result = np.array(Image.open(filename))
    if len(result.shape) == 3: # Awful, but whatever, it runs for testing
        result = np.array([[sum(x[:3]) / 3 for x in y] for y in result])
    return result

def get_files() -> tuple[str, list[ImageFile]]:
    loc = sys.argv[1]
    assert os.path.exists(loc)    
    if os.path.isfile(loc):
        return os.path.dirname(loc), [loc]
    file_map = {}
    file_list : list[ImageFile] = []
    for file in os.listdir(loc):
        filename = os.path.join(loc, file)
        if os.path.isfile(filename):
            if file.startswith('blackout'):
                file_list.append(ImageFile(filename))
                
    return loc, file_list 

def write_image_file(path : str, image : np.ndarray):
    if len(image.shape) == 3:
        color = lambda x : np.uint8(255 * x)
        Image.fromarray(color(image), mode='RGB').save(path)
    else:
        Image.fromarray(image).save(path)

def write_image_files(root : str, image_data : ImageFile):
    assert image_data.blackout.endswith('.tif')
    assert type(image_data) == ImageFile
    path = os.path.join(root, os.path.basename(image_data.blackout))
    write_image_file(path, image_data.blackout_data)

def remove_artifacts(image_data : ImageFile):
    image = image_data.blackout_data
    prev_bottom = -1
    for col in range(image.shape[1]):
        for row in range(image.shape[0]-1, -1, -1):
            if image[row,col]:
                if prev_bottom == -1:
                    prev_bottom = row
                elif row - prev_bottom < 10:
                    prev_bottom = row
                else: # correction
                    prev_col = col - 1
                    # delete artifact
                    for drow in range(image.shape[0]-1, -1, -1):
                        image[drow,col] = False
                    for arow in range(prev_bottom, -1, -1):
                        image[arow, col] = True
                        if not image[arow,prev_col]: # end cleanup
                            break
                break # done with column

def main():
    if len(sys.argv) != 2:
        print('Give exactly one argument (name of folder or file)')
        print('Note that only files with prefixes gsm and bw are worked on')
        exit()
    root, images = get_files()
    results = os.path.join(root, 'removed_artifacts/')
    if os.path.exists(results):
        print(f'Will overwrite existing path {results}')
        check = input('ok? (y/n): ')
        if check.lower() != 'y':
            print('ok, exiting')
            exit()
    pathlib.Path(results).mkdir(parents=True, exist_ok=True)
    for image_data in images:
        remove_artifacts(image_data)
        write_image_files(results, image_data)

if __name__ == "__main__":
    main()