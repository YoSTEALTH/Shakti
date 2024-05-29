from liburing.common cimport iovec, io_uring_prep_close
from liburing.file cimport io_uring_prep_openat, io_uring_prep_read
from ..event.entry cimport SQE


async def random(unsigned int length)-> bytes:
    ''' Async Random

        Example
            >>> await random(3)
            b'4\x98\xde'
    '''
    if length == 0:  return b''
    cdef:
        SQE             sqe = SQE(), sqes = SQE(2)
        bytearray       buffer = bytearray(length)
        unsigned int    result
    # open
    io_uring_prep_openat(sqe, b'/dev/random')
    await sqe
    # read & close
    io_uring_prep_read(sqes, sqe.result, buffer, length)
    io_uring_prep_close(sqes[1], sqe.result)
    await sqes
    return bytes(buffer if sqes.result == length else buffer[:sqes.result])
