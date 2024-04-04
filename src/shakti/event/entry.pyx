from types import coroutine


cdef class Entry:
    ''' Entry | Entries Base Class '''

    def __repr__(self):
        return f'{self.__class__.__name__}(job={JOBS(self.job).name!r}, sqe={self.sqe!r}, ' \
               f'coro={self.coro!r}, result={self.result!r})'  # , holder={self.holder!r})'


@coroutine
def sleep(double second, uint8_t flags=0, *, bint error=False) -> None:
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

    sqe.flags = __IOSQE_ASYNC
    io_uring_sqe_set_data(sqe, entry)
    io_uring_prep_timeout(sqe, ts, 0, flags)  # note: `count=1` means no timer!

    entry.job = ENTRY
    entry.sqe = sqe  # hold reference to `sqe`
    entry = yield entry
    # note: `ETIME` is returned as result for successfully timing-out.
    if error and entry.result != -errno.ETIME:
        trap_error(entry.result)


@coroutine
def entry(io_uring_sqe sqe, *, uint8_t flags=IOSQE_ASYNC, bint error=True)-> int32_t:
    '''
        Type
            sqe:    io_uring_sqe
            *
            flags:  int
            error:  bool
            return: int

        Example
            >>> sqe = io_uring_sqe()
            >>> io_uring_prep_read(sqe, ....)
            >>> result = await entry(sqe)
            123

        Flags
            IOSQE_ASYNC  # always go async (default)

        Note
            - `IOSQE_ASYNC` is passed as default `flags` for all the `sqe`
            - `sqe.user_data` is automatically set by event-manager

        Warning
            - Do not pass flags into `entry` or `sqe.flags` unknowingly!
    '''
    cdef str msg

    if len(sqe) > 1:
        msg = '`entry(sqe)` received `> 1` entries, try using `entries()` or `help(entry)`'
        raise ValueError(msg)

    # only `IOSQE_ASYNC` flag is allowed for now.
    if flags and flags != __IOSQE_ASYNC:
        msg = '`entry()` - Currently `flags` only support `0` or `IOSQE_ASYNC`.'
        raise ValueError(msg)

    cdef Entry entry = Entry()

    sqe.flags |= flags
    io_uring_sqe_set_data(sqe, entry)

    entry.job = ENTRY
    entry.sqe = sqe
    entry = yield entry
    return trap_error(entry.result) if error else entry.result
