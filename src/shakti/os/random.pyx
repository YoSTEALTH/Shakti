from liburing.common cimport iovec, io_uring_prep_close
from liburing.file cimport io_uring_prep_openat, io_uring_prep_readv
from ..event.entry cimport SQE


async def random(size_t length)-> bytes:
    ''' Async Random

        Example
            >>> await random(3)
            b'4\x98\xde'
    '''
    cdef:
        int fd
        bytes buffer = bytes(length)
        iovec iov = iovec(buffer)
        SQE sqe = SQE(), sqes = SQE(2)

    io_uring_prep_openat(sqe, b'/dev/random')   # open
    await sqe
    fd = sqe.result

    io_uring_prep_readv(sqes[0], fd, iov)       # read &
    io_uring_prep_close(sqes[1], fd)            # close
    await sqes
    
    return buffer
