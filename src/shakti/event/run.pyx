from types import CoroutineType


def run(*coroutine: tuple, unsigned int entries=1024, unsigned int flags=0) -> None:
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
    run_c(coroutine, entries, flags)


cdef void run_c(tuple coroutine, unsigned int entries=1024, unsigned int flags=0) except *:
    cdef:
        io_uring        ring = io_uring()
        io_uring_sqe    sqe
        io_uring_cqe    c, cqe = io_uring_cqe()
        Entry           entry, event
        unsigned int    coro_len, index, cqe_ready=0, counter=0
        str             msg

    if entries < (coro_len := len(coroutine)):
        raise ValueError('`run()` - `entries` is set too low!')

    try:  # start `io_uring` engine.
        io_uring_queue_init(entries, ring, flags)

        # prep coroutine to work with `io_uring` event manager
        for index in range(coro_len):
            if not isinstance(coroutine[index], CoroutineType):
                msg = '`run()` only accepts `CoroutineType`, ' \
                      'like async function. Refer to `help(run)`'
                raise TypeError()

            entry = Entry()
            entry.coro = coroutine[index]

            sqe = io_uring_get_sqe(ring)  # get sqe
            io_uring_prep_nop(sqe)
            sqe.flags = __IOSQE_ASYNC
            io_uring_sqe_set_data(sqe, entry)

        # event manager
        while counter := (io_uring_submit(ring) + counter - cqe_ready):
            # print('counter:', counter)
            # get count of how many event(s) are ready
            if not (cqe_ready := io_uring_peek_batch_cqe(ring, cqe, MAX_LINKING)):
                # wait for at least `1` event to be ready.
                io_uring_wait_cqe_nr(ring, cqe, 1)
                continue
            # print('cqe_ready:', cqe_ready)

            # ready event(s)
            for index in range(cqe_ready):
                c = cqe[index]
                event = io_uring_cqe_get_data(c)
                event.result = c.res
                # print('event:', event)
                # print('index:', index)
                # print('c.user_data:', cqe.user_data)
                # print('c.res:', event.result)
                # print('event:', event)
                if not event.coro:  # event(s) without `coro` are just collecting results
                    continue
                try:
                    entry = event.coro.send(event if event.job else None)
                    # note: event without `job` are coroutine initialization
                except StopIteration:
                    pass  # TODO: need to account for coro return values.
                    # print('StopIteration:', event.coro)
                else:
                    if entry.job & ENTRY:
                        if not io_uring_put_sqe(ring, entry.sqe):
                            counter += io_uring_submit(ring)
                            if not io_uring_put_sqe(ring, entry.sqe):  # try again
                                raise ValueError('`run()` - length of `sqe` > `entries`')
                        entry.coro = event.coro
                        entry.sqe = None  # free up `sqe`
                    else:
                        msg = '`run()` received unrecognized `job` %u' % entry.job
                        raise NotImplementedError(msg)
            # free seen entries
            io_uring_cq_advance(ring, cqe_ready)
    finally:
        io_uring_queue_exit(ring)
