from os import cpu_count
from os.path import join, dirname
from setuptools import setup
from importlib.util import find_spec
from setuptools.command.build_ext import build_ext
from Cython.Build import cythonize
from Cython.Compiler import Options
from Cython.Distutils import Extension


class BuildExt(build_ext):
    def initialize_options(self):
        super().initialize_options()
        self.parallel = threads  # manually set

    def finalize_options(self):
        super().finalize_options()
        try:
            include_path = join(dirname(find_spec('liburing').origin), 'include')
            self.include_dirs.append(include_path)
        except AttributeError:
            raise ImportError('can not find installed `liburing`') from None


if __name__ == '__main__':
    threads = cpu_count()
    # compiler options
    Options.annotate = False
    Options.fast_fail = True
    Options.docstrings = True
    Options.warning_errors = False

    extension = [Extension(name='shakti.*',  # where the `.so` will be saved.
                           sources=['src/shakti/*/*.pyx'],
                           language='c',
                           extra_compile_args=['-O3', '-g0'])]

    setup(cmdclass={'build_ext': BuildExt},
          ext_modules=cythonize(extension,
                                nthreads=threads,
                                compiler_directives={'language_level': 3,
                                                     'embedsignature': True,  # show `__doc__`
                                                     'boundscheck': False,
                                                     'wraparound': False}))
