from liburing.lib.type cimport mode_t, __AT_FDCWD
from liburing.os cimport io_uring_prep_mkdirat
from liburing.error cimport trap_error
from ..event.entry cimport SQE


async def mkdir(object path not None, mode_t mode=0o777, *, int dir_fd=__AT_FDCWD):
    cdef SQE sqe = SQE()
    if type(path) is not bytes:
        path = path.encode()
    io_uring_prep_mkdirat(sqe, path, mode, dir_fd)
    await sqe
    trap_error(sqe.result)

