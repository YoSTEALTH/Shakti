from os import cpu_count
from os.path import join
from tempfile import gettempdir
from setuptools import setup
from Cython.Build import cythonize
from Cython.Compiler import Options
from Cython.Distutils import Extension


debug = False  # <- manually change this
threads = cpu_count()//2 or 1  # use half of cpu resources
liburing_source = join(gettempdir(), 'liburing-source')  # /tmp/liburing-source

# compiler options
Options.docstrings = True
if debug:
    Options.warning_errors = True  # turn all warnings into errors.
    Options.fast_fail = False
    Options.annotate = True  # generate `*.html` file for debugging & optimization.
else:
    Options.warning_errors = False
    Options.fast_fail = True
    Options.annotate = False
extension = [Extension(name='shakti.*',  # where the `.so` will be saved.
                       sources=['src/shakti/*/*.pyx'],
                       language='c',
                       libraries=['uring'],
                       library_dirs=[join(liburing_source, 'src')],
                       include_dirs=[join(liburing_source, 'src/include')],
                       extra_compile_args=['-O3', '-g0'],  # optimize & remove debug symbols+data
                       define_macros=[('CYTHON_TRACE_NOGIL', 1 if debug else 0)])]


if __name__ == '__main__':
    setup(ext_modules=cythonize(extension,
                                nthreads=threads,
                                compiler_directives={
                                    'embedsignature': True,  # show all `__doc__`
                                    'linetrace': True if debug else False,  # enable for coverage
                                    'boundscheck': False,
                                    'wraparound': False,
                                    'language_level': 3}))
