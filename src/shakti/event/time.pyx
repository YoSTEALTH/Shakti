cpdef double time(T.clockid_t flag=T.CLOCK_REALTIME):
    ''' Time

        Example
            >>> time()
            >>> time(CLOCK_MONOTONIC_RAW)

        Flags
            CLOCK_REALTIME  # default
            CLOCK_MONOTONIC
            # Linux-specific clocks
            CLOCK_PROCESS_CPUTIME_ID
            CLOCK_THREAD_CPUTIME_ID
            CLOCK_MONOTONIC_RAW
            CLOCK_REALTIME_COARSE
            CLOCK_MONOTONIC_COARSE
            CLOCK_BOOTTIME
            CLOCK_REALTIME_ALARM
            CLOCK_BOOTTIME_ALARM
    '''
    cdef T.timespec ts
    T.clock_gettime(flag, &ts)
    return ts.tv_sec + (ts.tv_nsec / 1_000_000_000)


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
        self.total_time = time(T.CLOCK_MONOTONIC)
        self.eclipsing_time = 0

    def __enter__(self):
        return self

    def __exit__(self, *errors):
        self.total_time = time(T.CLOCK_MONOTONIC) - self.total_time
        if self.print:
            print(f'------------------------------\nTotal Time: {self.total_time:.16f}')

    @property
    def start(self)-> double:
        self.eclipsing_time = time(T.CLOCK_MONOTONIC) - self.eclipsing_time
        return self.eclipsing_time

    @property
    def stop(self)-> double:
        cdef double result = time(T.CLOCK_MONOTONIC) - self.eclipsing_time
        if self.print:
            print(f'------------------------\nTime: {result:.16f}\n')
        self.eclipsing_time = 0
        return result


# Defined to be accessed by Python
CLOCK_REALTIME = T.CLOCK_REALTIME
CLOCK_MONOTONIC = T.CLOCK_MONOTONIC
# Linux-specific clocks
CLOCK_BOOTTIME = T.CLOCK_BOOTTIME
CLOCK_MONOTONIC_RAW = T.CLOCK_MONOTONIC_RAW
CLOCK_REALTIME_ALARM = T.CLOCK_REALTIME_ALARM
CLOCK_BOOTTIME_ALARM = T.CLOCK_BOOTTIME_ALARM
CLOCK_REALTIME_COARSE = T.CLOCK_REALTIME_COARSE
CLOCK_MONOTONIC_COARSE = T.CLOCK_MONOTONIC_COARSE
CLOCK_THREAD_CPUTIME_ID = T.CLOCK_THREAD_CPUTIME_ID
CLOCK_PROCESS_CPUTIME_ID = T.CLOCK_PROCESS_CPUTIME_ID
