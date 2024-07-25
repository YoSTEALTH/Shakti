from cpython.object cimport PyObject
from cpython.ref cimport Py_XINCREF
from liburing.lib.type cimport __u8, __u16, __s32, __u64
from liburing.queue cimport IOSQE_ASYNC, IOSQE_IO_HARDLINK, IOSQE_IO_LINK, \
                            io_uring_sqe_set_flags, io_uring_sqe_set_data64, io_uring_sqe, \
                            io_uring_prep_nop
from liburing.helper cimport io_uring_put_sqe
from liburing.error cimport trap_error, index_error


cpdef enum JOBS:
    NOJOB   = 0
    CORO    = 1U << 0   # 1
    RING    = 1U << 1   # 2
    ENTRY   = 1U << 2   # 3
    ENTRIES = 1U << 3   # 4


cdef class SQE(io_uring_sqe):
    cdef:
        __u8            job
        bint            sub_coro, error
        object          coro
        tuple           _coro
        unsigned int    flags, link_flag
        readonly __s32  result


# cpdef enum __entry_define__:
#     IOSQE_ASYNC = __IOSQE_ASYNC
#     IORING_TIMEOUT_BOOTTIME = __IORING_TIMEOUT_BOOTTIME
#     IORING_TIMEOUT_REALTIME = __IORING_TIMEOUT_REALTIME
