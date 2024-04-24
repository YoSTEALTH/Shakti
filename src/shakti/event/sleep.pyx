from libc.errno cimport ETIME
from liburing.lib.type cimport __u64, uint8_t
from liburing.error cimport trap_error
from liburing.queue cimport IOSQE_ASYNC, io_uring_sqe_set_flags, io_uring_sqe_set_data64
from liburing.time cimport timespec, io_uring_prep_timeout
from .entry cimport ENTRY, SQE


async def sleep(double second, uint8_t flags=0)-> None:
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

    sqe.job = ENTRY
    io_uring_prep_timeout(sqe, ts, 0, flags)  # note: `count=1` means no timer!
    io_uring_sqe_set_flags(sqe, IOSQE_ASYNC)
    io_uring_sqe_set_data64(sqe, <__u64><void*>sqe)  # just get `sqe` address
    await sqe
    # note: `ETIME` is returned as result for successfully timing-out.
    if sqe.result != -ETIME:
        trap_error(sqe.result)
