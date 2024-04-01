cimport posix.time as T


cpdef double time(T.clockid_t flag=?)


cdef class Timeit:
    cdef:
        bint print
        double eclipsing_time
        public double total_time


cpdef enum __time_define__:
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
