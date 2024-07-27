from liburing.common cimport io_uring_prep_close, io_uring_prep_close_direct
from ..event.entry cimport SQE
from ..core.base cimport AsyncBase
from ..lib.error cimport UnsupportedOperation


cdef class IOBase(AsyncBase):
    cdef:
        bint            _reading, _writing
        readonly int    fileno

    cdef inline void closed(self)
    cdef inline void reading(self)
    cdef inline void writing(self)
