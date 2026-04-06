"""
Functions for managing input and output
"""

from PIL import Image
import numpy as np
import numpy.typing as npt
import os
import sys
from typing import Callable
from src.util import print_normal, print_verbose
import src.util
import src.options
from src.image_data import ImageData
import pathlib
import argparse
import toml

class ErrorParser(argparse.ArgumentParser):
    def error(self, message):
        self.print_help()
        sys.stderr.write(f'\nerror: {message}\n')
        sys.exit(2)

# constant parser setup
_PARSER = ErrorParser()
_PARSER.add_argument('option_files', type=str, nargs='+',
    help='The names of the option files or folders (any number of args)')
_PARSER.add_argument('-v','--verbose',action='store_true',
    help='Print verbose information, useful for debugging')
_PARSER.add_argument('-q','--quiet',action='store_true',
    help='Disables all printing except errors, useful for automation')
_PARSER.add_argument('-o','--overwrite',action='store_true',
    help='Overwrite without prompt')
_PARSER.add_argument('-e','--exit-error',action='store_true',
    help='Exit immediately on error')

def validate_options() -> list[tuple[dict[str, src.options.PRIMITIVE]], str | None]:
    """
    Validates the options given by command line arguments

    Returns the list of validated options
    """
    result = _PARSER.parse_args()
    args = vars(result)

    allow_requests = True
    options : list[str] = args['option_files']
    assert len(options) > 0
    if len(options) > 1 or os.path.isdir(options[0]):
        allow_requests = False
    result : list[dict[str, src.options.Option]] = []

    src.options.initialize()
    
    for option in options:
        to_check = []
        if not os.path.exists(option):
            raise ValueError(f'ERROR: Unknown file or folder {option}')
        if os.path.isdir(option):
            for file in os.listdir(option):
                filename = os.path.join(option, file)
                if os.path.isfile(filename):
                    if file.endswith('.toml'):
                        to_check.append(filename)
            if len(to_check) == 0:
                raise ValueError(f'ERROR: folder {option} has no top-level toml files')
        else:
            if not option.endswith('.toml'):
                raise ValueError(f'ERROR: non-toml file {option}')
            to_check = [option]
        for toml_file in to_check:
            data : dict[str, dict[str, any]] = toml.load(toml_file)

            if 'basics' in data:
                assert isinstance(data['basics'], dict)
                for name, value in data['basics'].items():
                    if not args['quiet']: # ordering problem
                        print(f'Using value {value} for option {name}')

            data['command'] = {}
            data['command']['verbose'] = False
            data['command']['quiet'] = False
            data['command']['overwrite'] = False
            data['command']['exit_error'] = False
            if args['verbose']:
                data['command']['verbose'] = True
            if args['quiet']:
                data['command']['quiet'] = True
            if args['overwrite']:
                data['command']['overwrite'] = True
            if args['exit_error']:
                data['command']['exit_error'] = True
            if allow_requests:
                toml_file = None # optional shenanigans
            result.append((src.options.validate_options(data, toml_file), 
                toml_file))

    return result

def reset_options(options : dict[str, src.options.PRIMITIVE], 
    filename : str | None):
    """
    Sets up the global environment
    
    Could this be better?  Yes.  But it works for now
    """
    src.options.reset_options(options, filename)

def _read_image_full(filename : str) -> np.ndarray:
    """
    Helper to read a TIF image into a numpy array
    """
    assert filename.endswith('.tif'), f'{filename} does not end with .tif'
    # Bleugh, this doesn't feel right
    result = np.array(Image.open(filename))
    if len(result.shape) == 3: # Awful, but whatever, it runs for testing
        result = np.array([[sum(x[:3]) / 3 for x in y] for y in result])
    return result

def read_image(image_type : str, filename : str, 
    as_bool : bool = False) -> np.ndarray:
    """
    Reads an image with additional data checking for bw images
    """
    result = _read_image_full(os.path.join(
        src.options.get_folder(image_type), filename))
    if as_bool:
        result = result.astype(bool)
    return result

def parse_name(filename : str, prefix : str) -> str:
    """
    Reads the name of a file to construct an appropriate ImageData
    This is a necessary operation to normalize our suffixes when writing out results
    """
    result = filename[:-4] # cutoff the .tif
    # cutoff the stuff before the last / or \
    result = result[max(result.rfind('/'), result.rfind('\\'))+1:]
    assert result.count(f'{prefix}') == 1, f'file {filename} contains {prefix} more than once'
    result = result[result.find(f'{prefix}')+len(prefix):]
    return result

def _find_image(data : list[ImageData], name : str):
    """
    Searches for the given image from data
    """
    for image in data:
        if image.name == name:
            return image
    raise ValueError(f'Unable to find image with name {name} in data')

def read_prefix(folder : str, prefix : str, data : list[ImageData], 
setter : Callable[[ImageData, npt.NDArray[np.float64]], None], warn : bool = False):
    """
    Annoyingly complex function to check the prefixes of each image in data
    """
    print_verbose(f'Parsing data with prefix {prefix} from folder {folder}')
    build_data = len(data) == 0
    for file in os.listdir(folder):
        filename = os.path.join(folder, file)
        if not os.path.isfile(filename):
            continue

        if file.startswith(f'{prefix}'):
            if not file.endswith('.tif'):
                err = f'All {prefix} files are expected to be .tif files, {file} is not'
                raise ValueError(err)
            filename = os.path.join(folder, file)
            image_data = _read_image_full(filename)
            name = parse_name(filename, prefix)
            if build_data:
                image = ImageData(name)
                setter(image, image_data)    
                data.append(image)
            else:
                setter(_find_image(data, name), image_data)

        else:
            if file.endswith('.tif') and warn:
                print_normal(f'Ignoring TIFF file {file} (not starting with {prefix})')

    if len(data) == 0:
        print(f'No valid files found in {folder}, exiting')
        exit()
    return data

def write_image(image_type : str, image : np.ndarray, filename : str):
    """
    Writes the given image to the given file
    Reformats images to write in RGB to match TIF format
    """
    assert filename.endswith('.tif')
    assert type(image) == np.ndarray, f'Unknown image type {repr(image)}'
    directory = src.options.get_result(image_type)
    pathlib.Path(directory).mkdir(parents=True, exist_ok=True)
    path = os.path.join(directory, filename)
    # Unflattens image shape from the compressed version used throughout OCTA
    if len(image.shape) == 3:
        color = lambda x : np.uint8(255 * x)
        Image.fromarray(color(image), mode='RGB').save(path)
    else:
        Image.fromarray(image).save(path)

def write_csv(csv_name : str, data : list[list[str | int | float]]):
    """
    Writes summarized results into the given CSV
    """
    location = src.options.get_result(csv_name)
    pathlib.Path(os.path.dirname(location)).mkdir(parents=True, exist_ok=True)

    with open(location, 'w') as f:
        for line in data:
            f.write(', '.join([str(x) for x in line]) + '\n')