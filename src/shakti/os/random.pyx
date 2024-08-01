from liburing.common cimport iovec, io_uring_prep_close
from liburing.file cimport io_uring_prep_openat, io_uring_prep_read
from ..event.entry cimport SQE


async def random_bytes(unsigned int length)-> bytes:
    ''' Async Random Bytes

        Example
            >>> await random_bytes(3)
            b'4\x98\xde'
    '''
    if length == 0:
        return b''

    cdef:
        SQE             sqe = SQE(), sqes = SQE(2)
        bytearray       buffer = bytearray(length)
        unsigned int    result

    # open
    io_uring_prep_openat(sqe, b'/dev/urandom')
    await sqe
    result = sqe.result  # fd

    # read & close
    io_uring_prep_read(sqes, result, buffer, length)
    io_uring_prep_close(sqes[1], result)
    await sqes
    result = sqes.result

    return bytes(buffer if result == length else buffer[:result])
