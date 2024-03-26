from cpython.ref cimport Py_INCREF, Py_DECREF
from liburing.lib.uring cimport *
from liburing.queue cimport io_uring, io_uring_sqe, io_uring_queue_init, io_uring_get_sqe, \
                            io_uring_prep_nop, io_uring_submit, io_uring_peek_batch_cqe, \
                            io_uring_wait_cqe_nr, io_uring_cqe_get_data, io_uring_sqe_set_data, \
                            io_uring_cq_advance, io_uring_queue_exit, io_uring_cqe
from liburing.helper cimport io_uring_put_sqe
from .entry cimport ENTRY, Entry


cpdef enum:
    MAX_LINKING = 1024
