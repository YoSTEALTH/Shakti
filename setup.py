from os import cpu_count
from site import getsitepackages
from os.path import join
from setuptools import setup
from Cython.Build import cythonize
from Cython.Compiler import Options
from Cython.Distutils import Extension


threads = cpu_count()//2 or 1  # use half of cpu resources
liburing_include = [join(i, 'liburing/include') for i in getsitepackages()]
# compiler options
Options.annotate = False
Options.fast_fail = True
Options.docstrings = True
Options.warning_errors = False
extension = [Extension(name='shakti.*',  # where the `.so` will be saved.
                       sources=['src/shakti/*/*.pyx'],
                       language='c',
                       include_dirs=liburing_include,
                       extra_compile_args=['-O3', '-g0'])]


if __name__ == '__main__':
    setup(ext_modules=cythonize(extension,
                                nthreads=threads,
                                compiler_directives={
                                    'embedsignature': True,  # show all `__doc__`
                                    'boundscheck': False,
                                    'wraparound': False,
                                    'language_level': 3}))
