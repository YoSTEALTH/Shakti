from types import CoroutineType
from .entry import JOBS


def run(*coroutine: tuple, unsigned int entries=1024, unsigned int flags=0) -> list:
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
        unsigned int    max_entries = 32768, coro_len = len(coroutine)
        io_uring        ring = io_uring()

    if entries < coro_len:
        raise ValueError('`run()` - `entries` is set too low! entries:', entries)
    elif coro_len > max_entries:
        raise ValueError('`run()` - `entries` is set too high! max entries:', max_entries)
    else:
        io_uring_queue_init(entries, ring, flags)
        try:
            initialize(ring, coroutine, coro_len)
            return engine(ring, entries, coro_len)
        finally:
            io_uring_queue_exit(ring)


cdef void initialize(io_uring ring, tuple coroutine, unsigned int coro_len):
    cdef:
        SQE             sqe
        object          coro
        unicode         msg
        PyObject *      ptr
        unsigned int    i

    for i in range(coro_len):
        if not isinstance(coro := coroutine[i], CoroutineType):
            msg = '`run()` only accepts `CoroutineType`, ' \
                  'like async function. Refer to `help(run)`'
            raise TypeError(msg)
        sqe = SQE()
        Py_XINCREF(ptr := <PyObject*>sqe)
        sqe.job = CORO
        sqe.coro = coro
        io_uring_prep_nop(sqe)
        io_uring_sqe_set_flags(sqe, IOSQE_ASYNC)
        io_uring_sqe_set_data64(sqe, <__u64>ptr)
        io_uring_put_sqe(ring, sqe)


cdef tuple completion_entry(io_uring_cqe cqe, unsigned int index):
    cdef:
        SQE         sqe
        bint        value = True
        __s32       result
        __u64       user_data
        PyObject *  ptr

    result, user_data = cqe.get_index(index)
    if user_data == 0:
        raise RuntimeError('user_data is NULL', user_data)

    if (ptr := <PyObject*><uintptr_t>user_data) is NULL:
        raise RuntimeError('cqe ptr is NULL', result, user_data)

    sqe = <SQE>ptr
    sqe.result = result
    if sqe.job & CORO:
        Py_XDECREF(ptr)
        value = False  # start coroutine
    return sqe.coro, value


cdef list engine(io_uring ring, unsigned int entries, unsigned int coro_len):
    cdef:
        SQE             sqe
        list            r = []
        bint            value
        object          coro
        io_uring_cqe    cqe = io_uring_cqe()
        int             i, counter = 0, cq_ready = 0

    # event manager
    while counter := ((io_uring_submit(ring) if io_uring_sq_ready(ring) else 0)
                      + counter - cq_ready):
        # get count of how many event(s) are ready and fill `cqe`
        while not (cq_ready := io_uring_peek_batch_cqe(ring, cqe, counter)):
            io_uring_wait_cqe_nr(ring, cqe, 1)  # wait for at least `1` event to be ready.

        for i in range(cq_ready):
            coro, value = completion_entry(cqe, i)
            if not coro:
                continue
            try:
                sqe = coro.send(value or None)
            except StopIteration as e:
                # if sqe.job & CORO:  # TODO
                r.append(e.value)
                coro_len -= 1
                if coro_len:
                    continue
                io_uring_cq_advance(ring, cq_ready)
                return r
            else:
                counter += submission_entry(ring, sqe, coro)
        io_uring_cq_advance(ring, cq_ready)  # free seen entries


cdef unsigned int submission_entry(io_uring ring, SQE sqe, object coro):
    cdef:
        unicode         msg
        SQE             _sqe
        unsigned int    counter = 0

    if sqe.job & ENTRY:
        sqe.coro = coro
    elif sqe.job & ENTRIES:
        sqe.job = NOJOB  # change first job
        _sqe = sqe[sqe.len-1]
        _sqe.coro = coro  # last entry
    elif sqe.job & TASK:
        raise NotImplementedError('TASK')
    else:
        msg = f'`run()` received unrecognized `job` {sqe.job}'
        raise NotImplementedError(msg)

    if not io_uring_put_sqe(ring, sqe):
        counter = io_uring_submit(ring)
        if not io_uring_put_sqe(ring, sqe):  # try again
            raise RuntimeError('`run()` - length of `sqe > entries`')
    return counter
