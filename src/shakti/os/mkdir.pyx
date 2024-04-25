from liburing.lib.type cimport mode_t, __AT_FDCWD
from liburing.os cimport io_uring_prep_mkdirat
from ..event.entry cimport SQE


async def mkdir(str path not None, mode_t mode=0o777, *, int dir_fd=__AT_FDCWD):
    '''
        Example
            >>> await mkdir('create-directory')
    '''
    cdef:
        SQE sqe = SQE()
        bytes _path = path.encode()
    io_uring_prep_mkdirat(sqe, _path, mode, dir_fd)
    await sqe


# TODO: makedirs
