from ..lib.error cimport UnsupportedOperation


cdef class AsyncBase:
    cdef:
        bint    __awaited__
        unicode msg
