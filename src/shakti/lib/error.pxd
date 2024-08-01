cdef class CancelledError(Exception):
    pass  # __module__ = BaseException.__module__
    # TODO: to be used in "io.event.run"


cdef class UnsupportedOperation(Exception):
    pass  # __module__ = OSError.__module__


cdef class ConnectionNotEstablishedError(Exception):
    pass  # __module__ = ConnectionError.__module__


cdef class DirExistsError(Exception):
    pass  # __module__ = FileExistsError.__module__
