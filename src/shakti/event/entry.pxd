from libc.errno cimport errno
from liburing.queue cimport __IOSQE_ASYNC, io_uring_sqe, io_uring_sqe_set_data
from liburing.time cimport timespec, io_uring_prep_timeout
from liburing.error cimport trap_error


cpdef enum JOBS:
    ENTRY = 1U << 0  # 1
    # OTHER = 1U << 1  # 2


cdef class Entry:
    cdef:
        __u8            job
        io_uring_sqe    sqe
        public object   coro
        __s32           result
        # list            holder
