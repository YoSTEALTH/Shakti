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
        unicode         msg
        io_uring        ring = io_uring()
        unsigned int    coro_len = __checkup(entries, coroutine)

    io_uring_queue_init(entries, ring, flags)
    try:
        __prep_coroutine(ring, coroutine, coro_len)
        return __event_loop(ring, entries)
    finally:
        io_uring_queue_exit(ring)


cdef unsigned int __checkup(unsigned int entries, tuple coroutine):
    cdef:
        unicode         msg
        unsigned int    i, max_entries = 32768, coro_len = len(coroutine)

    if entries < coro_len:
        __close_all_coroutine(coroutine, coro_len)
        msg = f'`run()` - `entries` is set too low! entries: {entries!r}'
        raise ValueError(msg)
    elif coro_len > max_entries:
        __close_all_coroutine(coroutine, coro_len)
        msg = f'`run()` - `entries` is set too high! max entries: {max_entries!r}'
        raise ValueError(msg)

    # pre-check
    msg = '`run()` only accepts `CoroutineType`, like `async` function.'
    __check_coroutine(coroutine, coro_len, msg)
    return coro_len


cdef inline void __check_coroutine(tuple coroutine, unsigned int coro_len, unicode msg):
    for i in range(coro_len):
        if not isinstance(coroutine[i], CoroutineType):
            __close_all_coroutine(coroutine, coro_len)
            raise TypeError(msg)


cdef inline void __close_all_coroutine(tuple coroutine, unsigned int coro_len) noexcept:
        cdef unsigned int i
        for i in range(coro_len):
            try:
                coroutine[i].close()
            except:
                pass  # ignore error while trying to close


cdef inline void __prep_coroutine(io_uring ring,
                                  tuple coroutine,
                                  unsigned int coro_len,
                                  bint sub_coro=False):
    cdef:
        SQE             sqe
        unicode         msg
        PyObject *      ptr
        unsigned int    i

    for i in range(coro_len):
        sqe = SQE()
        Py_XINCREF(ptr := <PyObject*>sqe)
        sqe.job = CORO
        sqe.coro = coroutine[i]
        sqe.sub_coro = sub_coro
        io_uring_prep_nop(sqe)
        io_uring_sqe_set_data64(sqe, <__u64>ptr)
        io_uring_put_sqe(ring, sqe)


cdef list __event_loop(io_uring ring, unsigned int entries):
    cdef:
        SQE             sqe, _sqe
        bint            sub_coro
        list            r = []
        __s32           res
        __u64           user_data
        object          coro, value
        unicode         msg
        PyObject*       ptr
        io_uring_cqe    cqe = io_uring_cqe()
        unsigned int    index=0, counter=0, cq_ready=0

    # event manager
    while counter := ((io_uring_submit(ring) if io_uring_sq_ready(ring) else 0) + counter-cq_ready):
        if io_uring_wait_cqe(ring, cqe) != 0:
            continue
        cq_ready = 0
        for index in range(io_uring_for_each_cqe(ring, cqe)):
            res, user_data = cqe.get_index(index)
            if not user_data:
                continue
            cq_ready += 1
            if (ptr := <PyObject*><uintptr_t>user_data) is NULL:
                raise RuntimeError('`engine()` - received `NULL` from `user_data`')
            sqe = <SQE>ptr
            sqe.result = res
            if sqe.job & CORO:
                Py_XDECREF(ptr)
                value = None    # start coroutine
            else:
                value = False   # bogus value
            if not (coro := sqe.coro):
                continue
            sub_coro = sqe.sub_coro
            while True:
                try:
                    sqe = coro.send(value)
                except StopIteration as e:
                    if not sqe.sub_coro:
                        r.append(e.value)
                else:
                    if sqe.job & ENTRY:
                        sqe.coro = coro
                        sqe.sub_coro = sub_coro
                    elif sqe.job & ENTRIES:
                        sqe.job = NOJOB         # change first job
                        _sqe = sqe[sqe.len-1]   # last entry
                        _sqe.coro = coro
                        _sqe.sub_coro = sub_coro
                    elif sqe.job & RING:
                        value = ring
                        continue
                    else:
                        msg = f'`run()` received unrecognized `job` {JOBS(sqe.job).name}'
                        raise NotImplementedError(msg)

                    if not io_uring_put_sqe(ring, sqe):
                        counter += io_uring_submit(ring)
                        if not io_uring_put_sqe(ring, sqe):  # try again
                            msg = '`run()` - length of `sqe > entries`'
                            raise RuntimeError(msg)
                break
        if cq_ready:
            io_uring_cq_advance(ring, cq_ready)  # free seen entries
    return r
