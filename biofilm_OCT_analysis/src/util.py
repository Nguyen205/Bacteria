"""
Utility functions
"""

from src.options import get, get_filename
import os

EPS = 1e-5 # for various floating-point safety checks

def require_exists(name : str, file : bool):
    if file:
        if not os.path.isfile(name):
            raise ValueError(f'Missing expected file {name}')
    else:
        if not os.path.exists(name):
            raise ValueError(f'Path {name} does not exist')

def format_multiline(s : str) -> str:
    s = s.strip()
    return '\n'.join([x.lstrip() for x in s.split('\n')])

def _print_internal(msg : str):
    if msg == "":
        print()
        return
    filename = get_filename()
    if filename is not None:
        print(f'Option file {filename}: ', end='')
    print(msg)

def print_normal(msg : str = ""):
    if not get('quiet'):
        _print_internal(msg)

def print_verbose(msg : str = ""):
    if get('verbose'):
        _print_internal(msg)

def exit_error():
    return get('exit_error')