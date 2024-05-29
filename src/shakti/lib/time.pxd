from  posix.time cimport CLOCK_MONOTONIC, clockid_t, timespec, \
                         clock_gettime as __clock_gettime


cdef inline double clock_gettime(clockid_t flag) noexcept nogil:
    ''' Clock Get Time

        Example
            >>> clock_gettime()
            >>> clock_gettime(CLOCK_MONOTONIC_RAW)

        Flags
            CLOCK_REALTIME
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

        Note
            - `clock_gettime` is vDSO thus won't incur a syscall.
            - This is meant to be internal function, as Python user can use `time.clock_gettime()`
    '''
    cdef timespec ts
    __clock_gettime(flag, &ts)
    return ts.tv_sec + (ts.tv_nsec / 1_000_000_000)


cdef class Timeit:
    cdef:
        bint print
        double eclipsing_time
        readonly double total_time
