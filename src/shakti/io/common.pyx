cdef class IOBase(AsyncBase):

    cdef inline void closed(self):
        if self.fileno < 0:
            self.msg = f'`{self.__class__.__name__}()` I/O operation on closed'
            raise UnsupportedOperation(self.msg)

    cdef inline void reading(self):
        if not self._reading:
            self.msg = f'`{self.__class__.__name__}()` is not opened in reading "r" mode.'
            raise UnsupportedOperation(self.msg)

    cdef inline void writing(self):
        if not self._writing:
            self.msg = f'`{self.__class__.__name__}()` is not opened in writing "w" mode.'
            raise UnsupportedOperation(self.msg)


async def close(unsigned int fd, bint direct=False):
    '''
        Example
            >>> await close(fd)

            >>> await close(index, True)  # direct descriptor

        Note
            - Set `direct=True` to close direct descriptor & `fd` can be used to supply file index.
    '''
    cdef SQE sqe = SQE()
    if direct:
        io_uring_prep_close_direct(sqe, fd)
    else:
        io_uring_prep_close(sqe, fd)
    await sqe
