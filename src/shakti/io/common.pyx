from liburing.common cimport io_uring_prep_close, io_uring_prep_close_direct
from ..event.entry cimport SQE


async def close(unsigned int fd, bint direct=False):
    '''
        Example
            >>> await close(fd)

            >>> await close(index, True)  # direct descriptor

        Note
            - Set `direct=True` to close direct descriptor & `fd` can be used to supply file index.
    '''
    cdef SQE sqe = SQE()
    if direct:
        io_uring_prep_close_direct(sqe, fd)
    else:
        io_uring_prep_close(sqe, fd)
    await sqe
