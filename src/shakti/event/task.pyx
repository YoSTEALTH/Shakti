from liburing.queue cimport io_uring, io_uring_prep_nop
from .entry cimport RING, SQE
from .run cimport __check_coroutine, __prep_coroutine
from types import CoroutineType


async def task(*coroutines: CoroutineType):
    ''' Task Coroutine coroutines

        Type
            coro:   CoroutineType
            return: None

        Example
            >>> async def hi(pos, value):
            ...     await sleep(value)
            ...     print(f'No.{pos}: {value}', flush=True)

            # usage-1
            >>> await task(hi(1, 1))
            No.1: 1

            # usage-2
            >>> await task(hi(1, 1), hi(2, 1), hi(3, 1))
            No.2: 1
            No.3: 1
            No.1: 1

            # usage-3
            >>> while True:
            ...     addr = await accept(server_fd)
            ...     await task(handler(addr))

        Note
            - Completion of `task(async_function, ...)` results will not be ordered.
            - Coroutine supplied into `task` executes concurrently on their own.
    '''
    cdef:
        object          coro
        unicode         msg
        SQE             sqe = SQE(0, error=False)
        unsigned int    i=0, coro_len=len(coroutines)

    if coro_len < 1:
        msg = '`task(coroutines)` not provided!'
        raise ValueError(msg)

    msg = '`run()` only accepts `CoroutineType`, ' \
          'like `async def function():`. Refer to `help(run)`'
    __check_coroutine(coroutines, coro_len, msg)

    sqe.job = RING
    cdef io_uring ring = await sqe
    __prep_coroutine(ring, coroutines, coro_len, True)
