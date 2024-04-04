cdef class Timeit:
    ''' Simple Benchmark

        Example
            >>> with Timeit():
            ...     # do stuffs
            ------------------------
            Time: 0.0001280000000000

            # Time Multiple Tests
            >>> with Timeit() as t:
            ...     t.start
            ...     # do stuff 1
            ...     t.stop
            ------------------------
            Stop: 0.0005770000000000
            ...
            ...     t.start
            ...     # do stuff 2
            ...     t.stop
            ------------------------
            Stop: 0.0005860000000000
            ...
            ------------------------
            Time: 0.0011970000000000

            # Disable Total Time Print
            >>> with Timeit(print=False) as t:
            ...     print(t.total_time)
            0.0012300000000000
    '''
    def __cinit__(self, bint print=True):
        self.print = print
        self.total_time = clock_gettime(CLOCK_MONOTONIC)
        self.eclipsing_time = 0

    def __enter__(self):
        return self

    def __exit__(self, *errors):
        self.total_time = clock_gettime(CLOCK_MONOTONIC) - self.total_time
        if self.print:
            print(f'------------------------------\nTotal Time: {self.total_time:.16f}')

    @property
    def start(self)-> double:
        self.eclipsing_time = clock_gettime(CLOCK_MONOTONIC) - self.eclipsing_time
        return self.eclipsing_time

    @property
    def stop(self)-> double:
        cdef double result = clock_gettime(CLOCK_MONOTONIC) - self.eclipsing_time
        if self.print:
            print(f'------------------------\nTime: {result:.16f}\n')
        self.eclipsing_time = 0
        return result
