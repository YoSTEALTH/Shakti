from types import CoroutineType


def run(*coroutine: tuple, unsigned int entries=1024, unsigned int flags=0) -> list[object]:
    '''
        Type
            coroutine:  CoroutineType
            entries:    int
            flags:      int
            return:     None

        Example
            >>> from shakti import Timeit, run, sleep
            ...
            ...
            >>> async def main():
            ...     print('hi', end='')
            ...     for i in range(4):
            ...         if i:
            ...             print('.', end='')
            ...         await sleep(1)
            ...     print('bye!')
            ...
            ...
            >>> if __name__ == '__main__':
            ...     with Timeit():
            ...         run(main())
    '''
    cdef:
        unsigned int    coro_len = len(coroutine)
        io_uring        ring = io_uring()

    if entries < coro_len:
        raise ValueError('`run()` - `entries` is set too low!')

    io_uring_queue_init(entries, ring, flags)
    try:
        initialize(ring, coroutine, coro_len)
        return engine(ring, entries, coro_len)
    finally:
        io_uring_queue_exit(ring)


cdef inline void initialize(io_uring ring, tuple coroutine, unsigned int coro_len):
    cdef:
        unsigned int    i
        SQE             sqe
        str             msg
        PyObject *      ptr

    for i in range(coro_len):
        if not isinstance(coroutine[i], CoroutineType):
            msg = '`run()` only accepts `CoroutineType`, ' \
                  'like async function. Refer to `help(run)`'
            raise TypeError(msg)

        sqe = SQE()
        sqe.job = CORO
        sqe.coro = coroutine[i].send
        io_uring_prep_nop(sqe)
        io_uring_sqe_set_flags(sqe, IOSQE_ASYNC)
        io_uring_sqe_set_data64(sqe, <__u64><void*>sqe)
        io_uring_put_sqe(ring, sqe)
        Py_INCREF(sqe)

cdef inline SQE completion_entry(io_uring_cqe cqe, unsigned int index):
    cdef:
        __s32   result
        __u64   user_data
    result, user_data = cqe.get_index(index)
    sqe = <SQE><void*><uintptr_t>user_data
    sqe.result = result
    if sqe.job & CORO:
        sqe.job = NOJOB
        Py_DECREF(sqe)
    if not sqe.coro:
        return None  # event(s) without `coro` are just collecting results
    return sqe

cdef inline unsigned int submission_entry(io_uring ring, SQE sqe, object send):
    cdef:
        str             msg
        SQE             _sqe
        unsigned int    counter=0

    if sqe.job & ENTRY:
        sqe.coro = send
        if not io_uring_put_sqe(ring, sqe):
            counter += io_uring_submit(ring)
            if not io_uring_put_sqe(ring, sqe):  # try again
                raise RuntimeError('`run()` - length of `sqe > entries`')
    elif sqe.job & ENTRIES:
        sqe.job = NOJOB
        # assign `coro` to last `_sqe`
        _sqe = sqe[sqe.len-1]
        _sqe.coro = send
        del _sqe
        if not io_uring_put_sqe(ring, sqe):
            counter += io_uring_submit(ring)
            if not io_uring_put_sqe(ring, sqe):  # try again
                raise RuntimeError('`run()` - length of `sqe > entries`')
    else:
        msg = '`run()` received unrecognized `job` %u' % sqe.job
        raise NotImplementedError(msg)

    return counter

cdef inline list[object] engine(io_uring ring, unsigned int entries, unsigned int coro_len):
    cdef:
        SQE             sqe
        io_uring_cqe    cqe = io_uring_cqe()
        unsigned int    i, counter=0, cq_ready=0
        list[object]    r = []
        __s32           result
        __u64           user_data

    # event manager
    while counter := ((io_uring_submit(ring) if io_uring_sq_ready(ring) else 0)
                      + counter - cq_ready):
        # get count of how many event(s) are ready and fill `cqe`
        while not (cq_ready := io_uring_peek_batch_cqe(ring, cqe, counter)):
            io_uring_wait_cqe_nr(ring, cqe, 1)  # wait for at least `1` event to be ready.

        for i in range(cq_ready):
            # completion entry
            if not (sqe := completion_entry(cqe, i)):
                continue
            send = sqe.coro
            try:
                sqe = send(True if sqe.job else None)
                # note: event without `job` are coroutine initialization
            except StopIteration as e:
                # print('StopIteration:', e.value)
                r.append(e.value)
                coro_len -= 1
                if coro_len:
                    continue
                io_uring_cq_advance(ring, cq_ready)
                return r
            else:  # submission entry
                counter += submission_entry(ring, sqe, send)
        io_uring_cq_advance(ring, cq_ready)  # free seen entries
