from libc.errno cimport ETIME
from liburing.lib.type cimport __u64, uint8_t
from liburing.error cimport trap_error
from liburing.queue cimport IOSQE_ASYNC, io_uring_sqe_set_flags, io_uring_sqe_set_data64
from liburing.time cimport timespec, io_uring_prep_timeout
from .entry cimport ENTRY, SQE
