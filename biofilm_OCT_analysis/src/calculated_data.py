"""
Class definition for calculated data
"""

class Todo:
    """
    Type to indicate uncertain types
    Arguably not needed, but I'll leave this in for now
    Newer versions of Python also make this cleaner
    """
    pass

class Calculated(object):
    """
    Maintains information about statistics we've calculated
    Basically a fancy struct to pass this information around
    """
    def __init__(self, mem_length : float, ra : float, ra2 : float,
    porosity : float, run_lengths : tuple[float, float, float, float],
    diffusion : float, connectivity : int,
    fractal : float, area : float, area_ratio : float):
        assert type(mem_length) == float
        assert type(ra) == float
        assert type(porosity) == float
        # assert type(run_lengths) == Todo
        assert type(diffusion) == float
        assert type(connectivity) == int
        assert type(fractal) == float
        assert type(area) == float
        assert type(area_ratio) == float

        self._mem_length = mem_length
        self._ra = ra
        self._ra2 = ra2
        self._porosity = porosity
        self._run_lengths = run_lengths
        self._diffusion = diffusion
        self._connectivity = connectivity
        self._fractal = fractal
        self._area = area
        self._area_ratio = area_ratio

    def __str__(self) -> str:
        return f'Calculated'
    
    def __repr__(self) -> str:
        return f'Calculated data (...)'

    @property
    def mem_length(self) -> float:
        return self._mem_length

    @property
    def ra(self) -> float:
        return self._ra

    @property
    def ra2(self) -> float:
        return self._ra2

    @property
    def porosity(self) -> float:
        return self._porosity

    @property
    def run_lengths(self) -> Todo:
        return self._run_lengths

    @property
    def diffusion(self) -> float:
        return self._diffusion
    
    @property
    def connectivity(self) -> int:
        return self._connectivity

    @property
    def fractal(self) -> float:
        return self._fractal

    @property
    def area(self) -> float:
        return self._area

    @property
    def area_ratio(self) -> float:
        return self._area_ratio