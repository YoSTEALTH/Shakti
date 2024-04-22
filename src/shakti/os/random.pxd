from liburing.common cimport iovec, io_uring_prep_close
from liburing.file cimport io_uring_prep_openat, io_uring_prep_readv
from ..event.entry cimport SQE
