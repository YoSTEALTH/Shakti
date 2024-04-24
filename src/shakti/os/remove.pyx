from libc.errno cimport ENOENT
from liburing.os cimport io_uring_prep_unlinkat
from liburing.lib.type cimport __AT_FDCWD, __AT_REMOVEDIR
from liburing.error cimport trap_error
from ..event.entry cimport SQE


async def remove(object path not None, bint is_dir=False, *,
                 bint ignore=False, int dir_fd=__AT_FDCWD):
    ''' Remove File | Directory

        Type
            path:   str | bytes
            is_dir: bool
            ignore: bool
            dir_fd: int
            return: None

        Example
            >>> await remove('./file-path.ext')     # remove file
            >>> await remove('./directory/', True)  # remove directory

        Note
            - `ignore=True` - ignore if file/directory does not exists.
            - `dir_fd` paths relative to directory descriptors.

        Version
            Linux 5.11
    '''
    cdef:
        SQE sqe = SQE()
        int flags = __AT_REMOVEDIR if is_dir else 0

    if type(path) is str:
        path = path.encode()

    io_uring_prep_unlinkat(sqe, path, flags, dir_fd)
    await sqe
    if ignore:
        if not (sqe.result & -ENOENT):
            trap_error(sqe.result)
    else:
        trap_error(sqe.result)
