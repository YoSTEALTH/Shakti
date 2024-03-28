from types import coroutine


cdef class Entry:
    ''' Entry | Entries Base Class '''

    def __repr__(self):
        return f'{self.__class__.__name__}(job={self.job!r}, sqe={self.sqe!r}, ' \
               f'coro={self.coro!r}, result={self.result!r}, holder={self.holder!r})'


@coroutine
def sleep(double second, __u8 flags=0, *, bint error=False) -> None:
    '''
        Type
            second: int | float     # double
            flags:  int             # unsigned
            error:  bool            # default: False
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
        Entry entry = Entry()
        io_uring_sqe sqe = io_uring_sqe()
        timespec ts = timespec(second)  # prepare timeout

    sqe.flags = IOSQE_ASYNC
    io_uring_sqe_set_data(sqe, entry)

    io_uring_prep_timeout(sqe, ts, 0, flags)  # note: `count=1` means no timer!

    entry.job = ENTRY
    entry.sqe = sqe  # hold reference to `sqe`

    entry = yield entry
    # note: `ETIME` is returned as result for successfully timing-out.
    if error and entry.result != -errno.ETIME:
        trap_error(entry.result)

    # TODO: need to include flags for python users to use.
