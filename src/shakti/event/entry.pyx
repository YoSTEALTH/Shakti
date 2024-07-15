from types import CoroutineType


cdef class SQE(io_uring_sqe):

    # note: `num` is used by `io_uring_sqe`
    def __init__(self, __u16 num=1, bint error=True, *,
                 unsigned int flags=0, unsigned int link_flag=IOSQE_IO_HARDLINK):
        ''' Shakti Queue Entry

            Type
                num:        int  - number of entries to create
                error:      bool - automatically raise error
                flags:      int
                link_flag: int
                return:     None

            Example
                # single
                >>> sqe = SQE()
                >>> io_uring_prep_openat(sqe, b'/dev/zero')
                >>> await sqe
                >>> sqe.result  # fd
                4

                # multiple
                >>> sqe = SQE(2)
                >>> io_uring_prep_openat(sqe[0], b'/dev/zero')
                >>> io_uring_prep_openat(sqe[1], b'/dev/zero')
                >>> await sqe
                >>> sqe[0].result  # fd
                4
                >>> sqe[1].result  # fd
                5

                # context manager
                >>> async with SQE() as sqe:
                ...     io_uring_prep_openat(sqe, b'/dev/zero')
                >>> sqe.result  # fd
                4

                # do not catch & raise error for `sqe.result`
                >>> SQE(123, False)  # or
                >>> SQE(123, error=False)

            Note
                - `SQE.user_data` is automatically set by `SQE()`.
                - Multiple sqe's e.g: `SQE(2)` are linked using `IOSQE_IO_HARDLINK`
                - context manger runs await in `__aexit__` thus need to check result
                outside of `aysnc with` block
        '''
        self.error = error
        self.flags = flags
        if not (link_flag & (IOSQE_IO_LINK | IOSQE_IO_HARDLINK)):
            raise ValueError('SQE(link_flag) must be `IOSQE_IO_HARDLINK` or `IOSQE_IO_LINK`')
        self.link_flag = link_flag

    def __getitem__(self, unsigned int index):
        cdef SQE sqe
        if self.ptr is not NULL:
            if index == 0:
                return self
            elif self.len and index < self.len:
                if (sqe := self.ref[index-1]) is not None:
                    return sqe  # return from reference cache
                # create new reference class
                sqe = SQE(0)  # `0` is set to indicated `ptr` memory is not managed
                sqe.ptr = &self.ptr[index]
                self.ref[index-1] = sqe  # cache sqe as this class attribute
                return sqe
        index_error(self, index, 'out of `sqe`')

    def __await__(self):
        cdef:
            SQE     sqe
            __u16   i

        if self.len == 1:  # single
            self.job = ENTRY
            self.coro = None
            self.result = 0
            io_uring_sqe_set_flags(self, self.flags)
            io_uring_sqe_set_data64(self, <__u64><void*>self)
        elif 1025 > self.len > 1:  # multiple
            for i in range(self.len):
                if i:
                    sqe = self[i]
                    sqe.coro = None
                    sqe.result = 0
                    io_uring_sqe_set_data64(sqe, <__u64><void*>sqe)
                    if i < self.len-1:  # middle
                        sqe.job = NOJOB
                        io_uring_sqe_set_flags(sqe, self.flags | self.link_flag)
                    else:  # last
                        sqe.job = ENTRIES
                        io_uring_sqe_set_flags(sqe, self.flags)
                else:  # first
                    self.job = ENTRIES
                    self.coro = None
                    self.result = 0
                    io_uring_sqe_set_flags(self, self.flags | self.link_flag)
                    io_uring_sqe_set_data64(self, <__u64><void*>self)
        else:
            raise NotImplementedError('num > 1024')

        yield self

        if self.error:
            if self.len == 1:
                trap_error(self.result)
            else:
                for i in range(self.len):
                    trap_error(self[i].result)
        # else: don't catch error

    # midsync
    def __aexit__(self, *errors):
        if any(errors):
            return False
        return self  # `await self`

    async def __aenter__(self):
        return self


# working on:
# async def task(*coroutines: CoroutineType, bint error=False):
#     ''' Task Coroutine coroutines

#         Type
#             coro:   CoroutineType
#             error:  bool
#             return: any

#         Example
            
#             >>> async def hi():
#             ...     return 'bye!'
            
#             # usage-1
#             >>> r = await task(hi())
#             >>> r
#             'bye!'

#             # usage-2
#             >>> r = await task(hi(), hi(), hi())
#             >>> r
#             ['bye!', 'bye!', 'bye!']

#             # usage-3
#             >>> while True:
#             ...     addr = await server.accept()
#             ...     await task(handler(addr))
#     '''
#     cdef unsigned int coro_len = len(coroutines)
#     # object send = _getframe(0).f_globals['coro'].send

#     if coro_len < 1:
#         raise ValueError('`task(coroutines)` not provided!')
#     elif coro_len > 1:
#         raise NotImplementedError('task() multiple coroutines')

#     cdef:
#         SQE         sqe
#         unicode     msg
#         PyObject *  ptr
    
#     for i in range(coro_len):
#         try:
#             if not isinstance(coro := coroutines[i], CoroutineType):
#                 msg = '`run()` only accepts `CoroutineType`, ' \
#                       'like async function. Refer to `help(run)`'
#                 raise TypeError(msg)
#             sqe = SQE()
#             Py_XINCREF(ptr := <PyObject*>sqe)
#             sqe.job = TASK
#             sqe.coro = coro
#             io_uring_prep_nop(sqe)
#             io_uring_sqe_set_flags(sqe, IOSQE_ASYNC)
#             io_uring_sqe_set_data64(sqe, <__u64>ptr)
#             io_uring_put_sqe(ring, sqe)
#             await sqe
#         except StopIteration:
#             print('TASK StopIteration', i)


# async def task(*coroutines: CoroutineType, bint error=False)-> list[object]:
#     ''' Task Coroutine coroutines

#         Type
#             coro:   CoroutineType
#             error:  bool
#             return: any

#         Example
#             >>> async def hi():
#             ...     return 'bye!'
#             >>> r = await task(hi())
#             >>> r
#             'bye!'

#             # usage
#             >>> while True:
#             ...     addr = await server.accept()
#             ...     await task(handler(addr))
#     '''
#     cdef:
#         unsigned int coro_len = len(coroutines)
#         # object send = _getframe(0).f_globals['coro'].send

#     if coro_len < 1:
#         raise ValueError('`task(coroutines)` not provided!')
#     elif coro_len > 1:
#         raise NotImplementedError('task() multiple coroutines')

#     cdef SQE sqe = SQE()
#     try:
#         for i in range(coro_len):
#             if not isinstance(coro := coroutines[i], CoroutineType):
#                 msg = '`run()` only accepts `CoroutineType`, ' \
#                       'like async function. Refer to `help(run)`'
#                 raise TypeError(msg)
#             sqe.job = TASK
#             sqe.coro = coro.send
#             io_uring_prep_nop(sqe)
#             io_uring_sqe_set_flags(sqe, IOSQE_ASYNC)
#             io_uring_sqe_set_data64(sqe, <__u64><PyObject*>sqe)
#             io_uring_put_sqe(ring, sqe)
#             Py_XINCREF(ptr)
#     except StopIteration:
#         pass
#     else:
#         pass
#     sqe.job = CORO
#     await sqe


# from types import CoroutineType


# cdef class SQE(io_uring_sqe):

#     # note: `num` is used by `io_uring_sqe`
#     def __init__(self, __u16 num=1, bint error=True, *,
#                  unsigned int flags=IOSQE_ASYNC, unsigned int link_flag=IOSQE_IO_HARDLINK):
#         ''' Shakti Queue Entry

#             Type
#                 num:        int  - number of entries to create
#                 error:      bool - automatically raise error
#                 flags:      int
#                 link_flag: int
#                 return:     None

#             Example
#                 # single
#                 >>> sqe = SQE()
#                 >>> io_uring_prep_openat(sqe, b'/dev/zero')
#                 >>> await sqe
#                 >>> sqe.result  # fd
#                 4

#                 # multiple
#                 >>> sqe = SQE(2)
#                 >>> io_uring_prep_openat(sqe[0], b'/dev/zero')
#                 >>> io_uring_prep_openat(sqe[1], b'/dev/zero')
#                 >>> await sqe
#                 >>> sqe[0].result  # fd
#                 4
#                 >>> sqe[1].result  # fd
#                 5

#                 # context manager
#                 >>> async with SQE() as sqe:
#                 ...     io_uring_prep_openat(sqe, b'/dev/zero')
#                 >>> sqe.result  # fd
#                 4

#                 # do not catch & raise error for `sqe.result`
#                 >>> SQE(123, False)  # or
#                 >>> SQE(123, error=False)

#             Note
#                 - `SQE.user_data` is automatically set by `SQE()`.
#                 - Multiple sqe's e.g: `SQE(2)` are linked using `IOSQE_IO_HARDLINK`
#                 - context manger runs await in `__aexit__` thus need to check result
#                 outside of `aysnc with` block
#         '''
#         self.error = error
#         self.flags = flags
#         if not (link_flag & (IOSQE_IO_LINK | IOSQE_IO_HARDLINK)):
#             raise ValueError('SQE(link_flag) must be one of `IOSQE_IO_HARDLINK` or `IOSQE_IO_LINK`')
#         self.link_flag = link_flag

#     def __getitem__(self, unsigned int index):
#         cdef SQE sqe
#         if self.ptr is not NULL:
#             if index == 0:
#                 return self
#             elif self.len and index < self.len:
#                 if (sqe := self.ref[index-1]) is not None:
#                     return sqe  # return from reference cache
#                 # create new reference class
#                 sqe = SQE(0)  # `0` is set to indicated `ptr` memory is not managed
#                 sqe.ptr = &self.ptr[index]
#                 self.ref[index-1] = sqe  # cache sqe as this class attribute
#                 return sqe
#         index_error(self, index, 'out of `sqe`')

#     def __await__(self):
#         cdef:
#             __u16       i
#             # PyObject *  ptr
#             SQE         sqe

#         if self.len == 1:  # single
#             self.job = ENTRY
#             self.coro = None
#             self.result = 0
#             io_uring_sqe_set_flags(self, self.flags)
#             io_uring_sqe_set_data64(self, <__u64><PyObject*>self)
#         elif 1025 > self.len > 1:  # multiple
#             for i in range(self.len):
#                 if i:
#                     sqe = self[i]
#                     sqe.coro = None
#                     sqe.result = 0
#                     io_uring_sqe_set_data64(sqe, <__u64><PyObject*>sqe)
#                     if i < self.len-1:  # middle
#                         sqe.job = NOJOB
#                         io_uring_sqe_set_flags(sqe, self.flags | self.link_flag)
#                     else:  # last
#                         sqe.job = ENTRIES
#                         io_uring_sqe_set_flags(sqe, self.flags)
#                 else:  # first
#                     self.job = ENTRIES
#                     self.coro = None
#                     self.result = 0
#                     io_uring_sqe_set_flags(self, self.flags | self.link_flag)
#                     io_uring_sqe_set_data64(self, <__u64><PyObject*>self)
#         else:
#             raise NotImplementedError('entries > 1024')

#         yield self
#         print('self len:', self.len, 'self.error:', self.error)
#         if self.error:
#             if self.len == 1:
#                 trap_error(self.result)
#             else:
#                 for i in range(self.len):
#                     trap_error(self[i].result)
#         # else: don't catch error

#     # midsync
#     def __aexit__(self, *errors):
#         if any(errors):
#             return False
#         return self  # `await self`

#     async def __aenter__(self):
#         return self


# # async def task(*coroutines: CoroutineType, bint error=False)-> list[object]:
# #     ''' Task Coroutine coroutines

# #         Type
# #             coro:   CoroutineType
# #             error:  bool
# #             return: any

# #         Example
# #             >>> async def hi():
# #             ...     return 'bye!'
# #             >>> r = await task(hi())
# #             >>> r
# #             'bye!'

# #             # usage
# #             >>> while True:
# #             ...     addr = await server.accept()
# #             ...     await task(handler(addr))
# #     '''
# #     cdef:
# #         unsigned int coro_len = len(coroutines)
# #         # object send = _getframe(0).f_globals['coro'].send

# #     if coro_len < 1:
# #         raise ValueError('`task(coroutines)` not provided!')
# #     elif coro_len > 1:
# #         raise NotImplementedError('task() multiple coroutines')

# #     cdef SQE sqe = SQE()
# #     try:
# #         for i in range(coro_len):
# #             if not isinstance(coro := coroutines[i], CoroutineType):
# #                 msg = '`run()` only accepts `CoroutineType`, ' \
# #                       'like async function. Refer to `help(run)`'
# #                 raise TypeError(msg)
# #             sqe.job = TASK
# #             sqe.coro = coro.send
# #             io_uring_prep_nop(sqe)
# #             io_uring_sqe_set_flags(sqe, IOSQE_ASYNC)
# #             io_uring_sqe_set_data64(sqe, <__u64><PyObject*>sqe)
# #             io_uring_put_sqe(ring, sqe)
# #             Py_XINCREF(ptr)
# #     except StopIteration:
# #         pass
# #     else:
# #         pass
# #     sqe.job = CORO
# #     await sqe
