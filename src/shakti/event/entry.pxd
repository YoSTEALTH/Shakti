from cpython.ref cimport Py_INCREF, Py_DECREF
from liburing.lib.io_uring cimport *
from liburing.queue cimport io_uring_sqe_set_flags, io_uring_sqe_set_data, \
                            io_uring_sqe_set_data64, io_uring_cqe_get_data64, \
                            io_uring_sqe, io_uring_prep_nop
from liburing.error cimport trap_error, memory_error, index_error


cpdef enum JOBS:
    NOJOB   = 0
    CORO    = 1U << 0   # 1
    CHILD   = 1U << 1   # 2
    ENTRY   = 1U << 2   # 3
    ENTRIES = 1U << 3   # 4


cdef class SQE(io_uring_sqe):
    cdef:
        __u8            job
        readonly __s32  result
        object          coro
        bint            error


cpdef enum __entry_define__:
    IOSQE_ASYNC = __IOSQE_ASYNC
    IORING_TIMEOUT_BOOTTIME = __IORING_TIMEOUT_BOOTTIME
    IORING_TIMEOUT_REALTIME = __IORING_TIMEOUT_REALTIME
