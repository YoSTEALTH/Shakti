from cpython.object cimport PyObject
from cpython.ref cimport Py_XINCREF, Py_XDECREF
from liburing.lib.type cimport __s32, __u64, uintptr_t
from liburing.queue cimport io_uring, io_uring_queue_init, io_uring_queue_exit, \
                            io_uring_prep_nop, io_uring_submit, io_uring_cqe, io_uring_sq_ready, \
                            io_uring_cq_advance, io_uring_wait_cqe, io_uring_for_each_cqe, \
                            io_uring_sqe_set_flags, io_uring_sqe_set_data64
from liburing.helper cimport io_uring_put_sqe
from .entry cimport NOJOB, CORO, TASK, ENTRY, ENTRIES, SQE