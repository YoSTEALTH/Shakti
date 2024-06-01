from libc.errno cimport EAGAIN
from cpython.object cimport PyObject
from cpython.ref cimport Py_XINCREF, Py_XDECREF, Py_INCREF, Py_DECREF
from liburing.lib.type cimport __u8, __s32, __u64, uintptr_t
from liburing.queue cimport IOSQE_ASYNC, \
                            io_uring, io_uring_queue_init, io_uring_queue_exit, \
                            io_uring_prep_nop, io_uring_sqe_set_flags, io_uring_sqe_set_data64, \
                            io_uring_submit, io_uring_cqe, io_uring_sq_ready, \
                            io_uring_peek_batch_cqe, io_uring_wait_cqe_nr, io_uring_cq_advance, \
                            __io_uring_cqe, io_uring_cq_ready, io_uring_submit_and_wait_timeout, \
                            io_uring_peek_cqe, io_uring_wait_cqe, __io_uring_wait_cqe, \
                            io_uring_wait_cqes, io_uring_for_each_cqe, io_uring_cqe_seen, \
                            io_uring_cq_has_overflow
from liburing.helper cimport io_uring_put_sqe
from .entry cimport NOJOB, CORO, TASK, ENTRY, ENTRIES, SQE
