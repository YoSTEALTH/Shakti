from libc.errno cimport errno
from libc.stdint cimport uint8_t, int32_t
from liburing.time cimport __IORING_TIMEOUT_BOOTTIME, __IORING_TIMEOUT_REALTIME, \
                           timespec, io_uring_prep_timeout
from liburing.queue cimport __IOSQE_ASYNC, io_uring_sqe, io_uring_sqe_set_data
from liburing.error cimport trap_error


cdef class Entry:
    cdef:
        uint8_t         job
        io_uring_sqe    sqe
        public object   coro
        int32_t         result
        # list            holder


cpdef enum JOBS:
    ENTRY = 1U << 0  # 1
    # OTHER = 1U << 1  # 2

cpdef enum __entry_define__:
    IOSQE_ASYNC = __IOSQE_ASYNC
    IORING_TIMEOUT_BOOTTIME = __IORING_TIMEOUT_BOOTTIME
    IORING_TIMEOUT_REALTIME = __IORING_TIMEOUT_REALTIME
