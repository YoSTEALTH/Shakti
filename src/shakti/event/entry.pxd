from libc.errno cimport errno
from libc.stdint cimport uint8_t, int32_t
from liburing.queue cimport IOSQE_ASYNC, io_uring_sqe, io_uring_sqe_set_data
from liburing.time cimport timespec, io_uring_prep_timeout
from liburing.error cimport trap_error


cpdef enum JOBS:
    ENTRY = 1U << 0  # 1
    # OTHER = 1U << 1  # 2


cdef class Entry:
    cdef:
        uint8_t         job
        io_uring_sqe    sqe
        public object   coro
        int32_t         result
        # list            holder
