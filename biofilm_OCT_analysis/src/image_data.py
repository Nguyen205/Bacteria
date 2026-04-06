"""
Class definition for image data

We treat ImageData as essentially a struct
Image manipulation functions are defined in image_mod.py
"""

import numpy as np
from src.calculated_data import Calculated
from typing import Optional

class OuterBound:
    """
    Essentially an enum intended to provide metadata about a given pixel
    """

    _val: int
    """
    The y-value of the given Pixel in the image
    """

    _typ: int
    """
    Effectively an enumerator indicating how we identify the pixel
    0 = Regular (non-outlier/blank) pixel
    1 = outlier pixel
    2 = blank column (i.e. there's nothing useful to be done)
    """

    def __init__(self, val : int):
        self._val = val
        self._typ = 0

    def is_reg(self) -> bool:
        return self._typ == 0

    def is_edge_outl(self) -> bool:
        return self._typ == 1

    def is_blank(self) -> bool:
        return self._typ == 2

    def to_edge_outl(self):
        self._typ = 1

    def to_blank(self):
        self._typ = 2

    def __repr__(self) -> str:
        return str(512 - self._val)

    @property
    def value(self) -> int:
        assert not self.is_blank()
        return self._val

class ImageData(object):
    """
    Represents the data associated with a single OCT input
    Note that this data includes all images associated with the input
      including calculated intermediate steps _as distinct images_
    Attributes are filled in as they are calculated
    _be careful about preconditions_ -- many methods will break if operations
      are applied out of order for some reason
    """

    _height: int = 0
    """
    Class variable indicating the height of all images
    Must be set in driver.py before use
    """

    _width: int = 0
    """
    Class variable indicating the width of all images
    Must be set in driver.py before use
    """

    _name: str
    """
    The underlying name of the image
    Each image format will be associated with this name 
      along with a distinct suffix
    """

    _gs: Optional[np.ndarray]
    """
    The GS Image associated with this data
    Optional until filled by reading from a file
    """

    _gsm: Optional[np.ndarray]
    """
    The GSM Image associated with this data
    Optional until filled by reading from a file
    """

    _bw_data: Optional[np.ndarray]
    """
    The black-and-white image associated with this data
    Optional until calculated _or_ filled by reading from a file
    """

    _bw_overlay: Optional[np.ndarray]
    """
    The black-and-white image overlayed onto the given GSM file
    May not be useful, but included to match the reference source
    """

    _bwc: Optional[np.ndarray]
    """
    The black-and-white with cutoff image (i.e. removing above the GSM line)
    Optional until calculated _or_ filled by reading from a file
    """

    _outl: Optional[np.ndarray]
    """
    The BWC image with outliers removed
    """

    _outl2: Optional[np.ndarray]
    """
    The BWC image with colors indicating 
      the calculated membrane bounary and points of outlier removal
    """

    _outl3: Optional[np.ndarray]
    """
    The raw BW image with colors indicating 
      the calculated membrane bounary and points of outlier removal
    """

    _blackout_gaps: Optional[np.ndarray]
    """
    An array indicating where each "gap" can be found for outl2 calculation
    """

    def __init__(self, name : str):
        """
        The initializer for ImageData only requires we start with a name
        """
        assert type(name) == str
        self._name = name
        self._gs = None
        self._gsm = None
        self._bw_data = None
        self._bw_overlay = None
        self._bwc = None
        self._outl = None
        self._outl2 = None
        self._outl3 = None
        self._blackout_gaps = None
        self._gaps = None
        self._h_plot_corr = None
        self._data = None

    def __str__(self) -> str:
        if self._gs is None:
            return f'Image {self.name}'
        return f'Image {self.name} : {self._gs.shape}'

    def __repr__(self) -> str:
        if self._gs is None:
            return f'Unresolved image with name {self.name}'
        return f'Image of size {self._gs.shape} with name {self.name}'

    """
    Getters
    """

    @property
    def name(self) -> str:
        return self._name

    @property
    def gs(self) -> Optional[np.ndarray]:
        return self._gs

    @property
    def gsm(self) -> Optional[np.ndarray]:
        return self._gsm

    @property
    def bw(self) -> Optional[np.ndarray]:
        return self._bw_data

    @property
    def bwc(self) -> Optional[np.ndarray]:
        return self._bwc

    @property
    def bw_overlay(self) -> Optional[np.ndarray]:
        return self._bw_overlay

    @property
    def outl(self) -> Optional[np.ndarray]:
        return self._outl

    @property
    def outl2(self) -> Optional[np.ndarray]:
        return self._outl2
    
    @property
    def outl3(self) -> Optional[np.ndarray]:
        return self._outl3
    
    @property
    def blackout_gaps(self) -> Optional[np.ndarray]:
        return self._blackout_gaps

    @property
    def gaps(self) -> Optional[list[int]]:
        return self._gaps

    @property
    def h_plot_corr(self) -> Optional[list[OuterBound]]:
        return self._h_plot_corr

    @property
    def data(self) -> Optional[Calculated]:
        return self._data


    """
    Setters
    """

    @classmethod
    def set_width(self, value : float):
        assert type(value) == float
        self._width = value

    @classmethod
    def set_height(self, value : float):
        assert type(value) == float
        self._height = value

    @classmethod
    def set_cutoff(self, cutoff : bool):
        assert type(cutoff) == bool
        self._cutoff = cutoff

    @classmethod
    def set_side_cutoff(self, side_cutoff : bool):
        assert type(side_cutoff) == bool
        self._side_cutoff = side_cutoff

    @gs.setter
    def gs(self, value : np.ndarray):
        assert type(value) == np.ndarray
        self._gs = value

    # each of the following requires that value have the same dimensions as data
    def _check_inc_data(self, value : np.ndarray):
        assert type(value) == np.ndarray
        assert value.ndim == self._gs.ndim
        assert value.shape == self._gs.shape

    @gsm.setter
    def gsm(self, value : np.ndarray):
        self._check_inc_data(value)
        self._gsm = value

    @bw.setter
    def bw(self, value : np.ndarray):
        self._check_inc_data(value)
        self._bw_data = value

    @bwc.setter
    def bwc(self, value : np.ndarray):
        self._check_inc_data(value)
        self._bwc = value

    @bw_overlay.setter
    def bw_overlay(self, value : np.ndarray):
        self._check_inc_data(value)
        self._bw_overlay = value

    @outl.setter
    def outl(self, value : np.ndarray):
        self._check_inc_data(value)
        self._outl = value

    @outl2.setter
    def outl2(self, value : np.ndarray):
        assert type(value) == np.ndarray
        assert value.ndim == self._gs.ndim + 1
        assert value.shape[:-1] == self._gs.shape
        self._outl2 = value
    
    @outl3.setter
    def outl3(self, value : np.ndarray):
        assert self._outl2 is not None
        assert type(value) == np.ndarray
        assert value.ndim == self._outl2.ndim
        assert value.shape == self._outl2.shape
        self._outl3 = value

    @blackout_gaps.setter
    def blackout_gaps(self, value : np.ndarray):
        self._check_inc_data(value)
        self._blackout_gaps = value

    @gaps.setter
    def gaps(self, value : list[int]):
        assert type(value) == list
        assert len(value) == self._bwc.shape[1]
        self._gaps = value

    @h_plot_corr.setter
    def h_plot_corr(self, value : list[OuterBound]):
        assert type(value) == list
        assert len(value) == self._outl.shape[1]
        self._h_plot_corr = value

    @data.setter
    def data(self, data : Calculated):
        assert type(data) == Calculated
        self._data = data