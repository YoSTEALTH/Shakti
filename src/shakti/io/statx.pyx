cdef class Statx(statx):
    '''
        Type
            path:   str
            flags:  int
            mask:   int
            dir_fd: int
            return: None

        Example
            >>> stat = await Statx('/path/to/some_file.ext')
            >>> stat.isfile
            True
            >>> stat.stx_size
            123

            # with context manager
            >>> async with Statx('/path/to/some_file.ext') as stat:
            ...     stat.isfile
            True
            ...     stat.stx_size
            123

        Flags
            - TODO

        Mask
            - TODO

        Note
            - Refer to `help(Statx)` to see further details. 
    '''
    def __cinit__(self,
                  str path not None,
                  int flags=0,
                  unsigned int mask=0,
                  int dir_fd=__AT_FDCWD):
        self._path = path.encode()
        self._mask = mask
        self._flags = flags
        self._dir_fd = dir_fd

    # midsync
    def __await__(self):
        return self.__aenter__().__await__()

    async def __aenter__(self):
        if self.__awaited__:
            return self
        self.__awaited__ = True
        cdef SQE sqe = SQE()
        io_uring_prep_statx(sqe, self, self._path, self._flags, self._mask,  self._dir_fd)
        await sqe
        return self

    async def __aexit__(self, *errors):
        if any(errors):
            return False


async def exists(str path not None)-> bool:
    ''' Check Path Exists

        Type
            path:   str
            return: bool

        Example
            >>> if await exists('some/path'):
            ...     # do stuff
    '''
    cdef:
        bytes   _path = path.encode()
        SQE     sqe = SQE(1, False)
    io_uring_prep_statx(sqe, None, _path)
    await sqe
    if sqe.result == -ENOENT:  # FileNotFoundError
        return False
    return True
