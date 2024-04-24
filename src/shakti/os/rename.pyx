from liburing.lib.type cimport *
from liburing.os cimport io_uring_prep_renameat
from ..event.entry cimport SQE


async def rename(str old_path not None,
                 str new_path not None,
                 int flags=__RENAME_NOREPLACE,
                 *,
                 int old_dir_fd=__AT_FDCWD,
                 int new_dir_fd=__AT_FDCWD)-> None:
    ''' Rename File | Dirctory

        Example
            >>> await rename('old-name.txt', 'new-name.txt')

        Flag
            - RENAME_EXCHANGE
                - Atomically exchange `old_path` and `new_path`.
                - Both pathnames must exist but may be of different types
            - RENAME_NOREPLACE (set as default)
                - Don't overwrite `new_path` of the rename.
                - Raises an `OSError` if `new_path` already exists.
            - RENAME_WHITEOUT
                - This operation makes sense only for overlay/union filesystem implementations.

        Note
            - `rename` can also be used to move file/dir as well.

        Version
            linux 5.11
    '''
    cdef:
        SQE     sqe = SQE()
        bytes   _old_path = old_path.encode()
        bytes   _new_path = new_path.encode()
    io_uring_prep_renameat(sqe, _old_path, _new_path, old_dir_fd, new_dir_fd, flags)
    await sqe


cpdef enum __rename_define__:
    RENAME_NOREPLACE = __RENAME_NOREPLACE
    RENAME_EXCHANGE = __RENAME_EXCHANGE
    RENAME_WHITEOUT = __RENAME_WHITEOUT
