cimport posix.time as T


cpdef double time(T.clockid_t flag=?)


cdef class Timeit:
    cdef:
        bint print
        double eclipsing_time
        public double total_time
