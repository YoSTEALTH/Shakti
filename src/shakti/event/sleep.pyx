from libc.errno cimport ETIME
from liburing.error cimport trap_error
from liburing.time cimport timespec, io_uring_prep_timeout
from .entry cimport SQE


async def sleep(double second, unsigned int flags=0):
    '''
        Type
            second: int | float     # double
            flags:  int             # unsigned
            return: None

        Flags
            IORING_TIMEOUT_BOOTTIME
            IORING_TIMEOUT_REALTIME

        Example
            >>> await sleep(1)      # 1 second
            >>> await sleep(0.001)  # 1 millisecond
    '''
    if second < 0:
        raise ValueError('`sleep(second)` can not be `< 0`')

    cdef:
        timespec    ts = timespec(second)  # prepare timeout
        SQE         sqe = SQE(1, False)
    io_uring_prep_timeout(sqe, ts, 0, flags)  # note: `count=1` means no timer!
    await sqe
    # note: `ETIME` is returned as result for successfully timing-out.
    if sqe.result != -ETIME:
        trap_error(sqe.result)
