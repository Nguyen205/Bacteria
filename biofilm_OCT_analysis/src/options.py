'''
Option management variables

Note that, while management variables are global, 
  they should _only_ be modified in this file

This setup is quite engineered to help with error messaging around options

The reason these are global is to try and avoid passing a context everywhere
'''

import src.util
import json
import os

PRIMITIVE = int | float | bool | str

def _is_primitive(value : any) -> bool:
    """
    We do lots of runtime type checking, so helpers are important
    """
    return isinstance(value, int) or \
        isinstance(value, float) or \
        isinstance(value, bool) or \
        isinstance(value, str)

class Option:
    """
    Maintains information about options summarized in data/options.json
    Manually written to make extensions straightforward
    """
    _min : int | None
    _max : int | None
    _path : str | None
    _check_exists : bool | None
    _require_above_mode : int | None
    _extension : str | None
    _nullable : bool | None
    _typ : type

    def __init__(self, info : dict[str, any]):
        assert isinstance(info, dict)
        assert 'name' in info
        assert isinstance(info['name'], str)

        lowered = {}
        for k in info:
            assert isinstance(k, str)
            lowered[k.lower()] = info[k]
        info = lowered

        assert 'type' in info
        assert isinstance(info['type'], str)
        info['type'] = info['type'].lower()
        assert info['type'] in ('string', 'int', 'float', 'bool')
        if info['type'] == 'string':
            assert 'nullable' in info
            assert 'path' in info
            if info['path']:
                assert 'check_exists' in info

        self._min = None
        self._max = None
        self._path = None
        self._check_exists = None
        self._require_above_mode = None
        self._extension = None
        self._nullable = None
        self._typ = _string_to_type(info['type'])

        if self._typ in (int, float):
            if 'min' in info:
                self._min = info['min']
            if 'max' in info:
                self._min = info['max']

        if self._typ == str:
            if 'path' in info:
                self._path = info['path']
            if 'nullable' in info:
                self._nullable = info['nullable']
            if 'check_exists' in info:
                self._check_exists = info['check_exists']
            if 'extension' in info:
                self._extension = info['extension']

    def min_valid(self) -> bool:
        return self._min is not None

    def max_valid(self) -> bool:
        return self._max is not None

    def path_valid(self) -> bool:
        return self._path is not None
    
    def check_exists_valid(self) -> bool:
        return self._check_exists is not None

    def extension_valid(self) -> bool:
        return self._extension is not None

    @property
    def typ(self) -> type:
        return self._typ

    @property
    def min(self) -> int:
        assert self._min is not None
        return self._min

    @property
    def max(self) -> int:
        assert self._max is not None
        return self._max

    @property
    def path(self) -> str:
        assert self._path is not None
        return self._path

    @property
    def check_exists(self) -> bool:
        assert self._check_exists is not None
        return self._check_exists

    @property
    def extension(self) -> str:
        assert self._extension is not None
        return self._extension

    @property
    def nullable(self) -> bool:
        assert self._nullable is not None
        return self._nullable

    def _maybe_str(self, name : str, value : PRIMITIVE | None) -> str:
        if value is None:
            return ''
        return f', {name} : {value}'

    def __str__(self) -> str:
        formatted : str = f'''
            {{typ : {self._typ}
                {self._maybe_str("min", self._min)}
                {self._maybe_str("max", self._max)}
                {self._maybe_str("path", self._path)}
                {self._maybe_str("check_exists", self._check_exists)}
                {self._maybe_str("require_above_mode", self._require_above_mode)}
                {self._maybe_str("extension", self._extension)}
            }}
        '''
        formatted = ''.join([x.strip() for x in formatted.strip().split('\n')])
        return formatted

    def __repr__(self) -> str:
        return f'<Option {self.__str__()}>'

# Singleton class
class OctaOptions:
    """
    Holds all of our options in one place for easy access throughout OCTA
    This could be done with a context instead, but a singleton is convenient
    """
    _data : dict[str, PRIMITIVE] | None = None
    _option_overview : dict[str, list[str]] | None = None
    _options : dict[str, Option] | None = None
    _filename : str | None = None
    DATA_FILE = 'src/data/options.json'

    def __init__(self):
        raise AssertionError('Cannot instantiate an OctaOption class')

    @classmethod
    def initialize(self):
        """
        Manual class initilization for the singleton class object
        """
        # Resets all of the options
        # Uses old setup if a new run is happening
        assert not OctaOptions.is_initialized()

        src.util.require_exists(OctaOptions.DATA_FILE, True)
        with open(OctaOptions.DATA_FILE) as f:
            option_overview = json.load(f)
        OctaOptions._option_overview, OctaOptions._options = \
            OctaOptions._unpack_option_json(option_overview)
        
    @classmethod
    def reset_options(self, flattened_data : dict[str, PRIMITIVE], 
        filename : str | None):
        assert isinstance(flattened_data, dict)
        for key, value in flattened_data.items():
            assert isinstance(key, str)
            assert _is_primitive(value)

        OctaOptions._data = flattened_data
        OctaOptions._filename = filename

    @classmethod
    def option_names(self) -> list[str]:
        option_classes = OctaOptions._option_overview.values()
        result = []
        for option_class in option_classes:
            for option in option_class:
                result.append(option)
        return result

    @classmethod
    def is_initialized(self):
        return OctaOptions._options is not None and \
            OctaOptions._option_overview is not None

    @classmethod
    def has_options(self):
        assert OctaOptions.is_initialized()
        return OctaOptions._data is not None

    @classmethod
    def add(self, name : str, value : PRIMITIVE):
        assert OctaOptions.has_options()
        assert name not in OctaOptions._data
        assert isinstance(value, OctaOptions._options[name].typ)
        OctaOptions._data[name] = value

    @classmethod
    def get(self, name : str) -> PRIMITIVE:
        assert OctaOptions.has_options()

        if name not in OctaOptions._data:
            raise ValueError(f'Invalid option name {name}')

        return OctaOptions._data[name]

    @classmethod
    def get_filename(self) -> str | None:
        assert OctaOptions.has_options
        return OctaOptions._filename

    @classmethod
    def contains(self, name : str) -> bool:
        assert OctaOptions.has_options()
        return name in OctaOptions._data

    @classmethod
    def valid_option(self, name : str) -> bool:
        assert OctaOptions.has_options()
        return name in OctaOptions._options

    @classmethod
    def option_type(self, name : str) -> type:
        assert OctaOptions.is_initialized()
        return self._options[name].typ

    @classmethod
    def _unpack_option_json(self, data : dict[str, list]) -> \
        tuple[dict[str, list[str]], dict[str, Option]]:
        headers : dict[str, list[str]] = {}
        options : dict[str, dict[str, any]] = {}
        assert isinstance(data, dict)
        for key, val in data.items():
            assert isinstance(key, str)
            assert isinstance(val, list)
            headers[key] = []
            for option in val:
                new_option : dict[str, any] = Option(option)

                name = option['name']
                headers[key].append(name)
                options[name] = new_option

        return headers, options

def initialize():
    """
    Initializes our options, must be called before options can be used
    """
    OctaOptions.initialize()

def _validate_number(option : Option, name : str, result : int | float, 
commands : dict[str, PRIMITIVE] | None = None):
    if option.min_valid() and result < option.min:
        raise ValueError(f'Value for {name} must be at least {option.min}')
    if option.max_valid() and result > option.max:
        raise ValueError(f'Value for {name} mut be at most {option.max}')
    return result

def _validate_string(option : Option, name : str, result : str, 
commands : dict[str, PRIMITIVE] | None = None):
    if not option.path: # it's not a path, no extra checks
        return result

    if commands is None:
        overwrite = get('overwrite')
    else:
        overwrite = commands['overwrite']

    if commands is None:
        quiet = get('quiet')
    else:
        quiet = commands['quiet']

    if option.check_exists: # since it's a path, check_exists required
        if not os.path.exists(result):
            raise ValueError(f'Option {name} with path {result} does not exist')

    elif not overwrite:
        if os.path.exists(result):
            print(f"Option {name} will overwrite {result}")
            inp = input("Continue (y/n): ")
            if inp.strip().lower() != 'y':
                exit()
    
    elif not quiet:
        print(f"Option {name} overwriting {result}")

    if option.extension_valid():
        if not result.endswith(f'.{option.extension}'):
            raise ValueError(f'Invalid extension for {result}, \
                .{option.extension} expected')

    return result

def _validate(option : Option, name : str, result : PRIMITIVE, 
commands : dict[str, PRIMITIVE] | None = None):
    if option.typ == bool:
        return result
    elif option.typ in (int, float):
        return _validate_number(option, name, result, commands)
    else:
        return _validate_string(option, name, result, commands)

def validate_options(data : dict[str, dict[str, PRIMITIVE]], 
filename : str | None = None) -> dict[str, PRIMITIVE]:
    """
    Checks that the given option is reasonable and outputs a "pretty" result
    This primarily exists to make error messages comprehensible
      when the options file is messed up in some way
    """
    assert OctaOptions.is_initialized()
    assert 'command' in data
    assert 'verbose' in data['command']
    assert 'overwrite' in data['command']
    assert 'quiet' in data['command']
    commands = data['command']
    flattened_data = {}

    for block_name, block in data.items():
        assert block_name in OctaOptions._option_overview
        for key, value in block.items():
            option = OctaOptions._options[key]
            assert key in OctaOptions._option_overview[block_name]
            typ = option.typ
            if typ == str and option.nullable:
                assert value is False or isinstance(value, str)
            else:
                assert isinstance(value, typ)
            flattened_data[key] = _validate(option, key, value, commands)

    for option in OctaOptions.option_names():
        if not option in flattened_data:
            if filename is not None:
                print(f'ERROR: missing option {option} in file {filename}')
                exit()
            else:
                flattened_data[option] = _input_type_safe(option)
    return flattened_data

def reset_options(options : dict[str, Option], filename : str | None):
    OctaOptions.reset_options(options, filename)

def get(name : str) -> PRIMITIVE:
    assert OctaOptions.is_initialized()
    if not OctaOptions.valid_option(name):
        raise ValueError(f'Invalid option {name}')

    return OctaOptions.get(name)

def get_filename() -> str | None:
    return OctaOptions.get_filename()

# Constants when reading from the datafile
HEIGHT = 'height'
WIDTH = 'width'
def get_folder(folder_type : str):
    return get(folder_type + '_folder')

def get_result(result_type : str):
    return get(result_type + '_results')

def _as_constrained(name : str, inp : str) -> PRIMITIVE:
    """
    Checks information about metadata for clean output
    """
    assert OctaOptions.is_initialized()
    option = OctaOptions._options[name]
    if option.typ == bool:
        lowered = inp.lower()
        if lowered not in ('false', 'true'):
            raise ValueError(f'Bool expected, got {inp}')
        if lowered == 'false':
            return False
        return True
        
    result : PRIMITIVE = option.typ(inp)

    if option.typ in (int, float):
        return _validate_number(result)

    if option.typ == str:
        return _validate_string(result)

    raise AssertionError(f'Invalid internal type {option["type"]}')

def _string_to_type(typ : str) -> type:
    """
    Helper to read from options
    """
    if typ == 'string':
        return str
    if typ == 'int':
        return int
    if typ == 'float':
        return float
    if typ == 'bool':
        return bool
    raise ValueError(f'Invalid string type {typ}')

def _input_type_safe(name : str) -> PRIMITIVE:
    while(True):
        typ = OctaOptions.option_type(name)
        inp = input(f'Give a value for {name} of type {typ}(Type `exit` to exit): ')
        inp = inp.strip()
        if inp.lower() == 'exit':
            exit()
        try:
            result = _as_constrained(name, inp)
            return result
        except ValueError as e:
            print(f'Invalid input, {str(e)} (Type `exit` to exit)')