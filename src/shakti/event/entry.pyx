cdef class SQE(io_uring_sqe):

    # note: `num` is used by `io_uring_sqe`
    def __init__(self, __u16 num=1, bint error=True, *,
                 unsigned int flags=IOSQE_ASYNC, unsigned int link_flags=IOSQE_IO_HARDLINK):
        ''' Shakti Queue Entry

            Type
                num:        int  - number of entries to create
                error:      bool - automatically raise error
                flags:      int
                link_flags: int
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
        if not (link_flags & (IOSQE_IO_LINK | IOSQE_IO_HARDLINK)):
            raise ValueError('SQE(link_flags) must be `IOSQE_IO_HARDLINK` or `IOSQE_IO_LINK`')
        self.link_flags = link_flags

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
            __u16   i
            SQE     sqe

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
                        io_uring_sqe_set_flags(sqe, self.flags | self.link_flags)
                    else:  # last
                        sqe.job = ENTRIES
                        io_uring_sqe_set_flags(sqe, self.flags)
                else:  # first
                    self.job = ENTRIES
                    self.coro = None
                    self.result = 0
                    io_uring_sqe_set_flags(self, self.flags | self.link_flags)
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

