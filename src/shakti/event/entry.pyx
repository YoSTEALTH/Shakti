cdef class SQE(io_uring_sqe):
    '''
        Note
            - `SQE.user_data` is automatically set by `SQE()`.
            - Multiple sqe's e.g: `SQE(2)` are linked using `IOSQE_IO_HARDLINK`
    '''
    def __getitem__(self, unsigned int index):
        cdef SQE    sqe
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
            io_uring_sqe_set_flags(self, __IOSQE_ASYNC)
            io_uring_sqe_set_data64(self, <__u64><void*>self)
        elif self.len > 1:  # multiple
            for i in range(self.len):
                if i:
                    sqe = self[i]
                    sqe.coro = None
                    sqe.result = 0
                    io_uring_sqe_set_data64(sqe, <__u64><void*>sqe)
                    if i < self.len-1:  # middle
                        sqe.job = NOJOB
                        io_uring_sqe_set_flags(sqe, __IOSQE_ASYNC | __IOSQE_IO_HARDLINK)
                    else:  # last
                        sqe.job = ENTRIES
                        io_uring_sqe_set_flags(sqe, __IOSQE_ASYNC)
                else:  # first
                    self.job = ENTRIES
                    self.result = 0
                    self.coro = None
                    io_uring_sqe_set_flags(self, __IOSQE_ASYNC | __IOSQE_IO_HARDLINK)
                    io_uring_sqe_set_data64(self, <__u64><void*>self)
        else:
            raise NotImplementedError
        yield self
