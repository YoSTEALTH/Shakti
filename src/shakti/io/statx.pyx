cdef class Statx(statx):
    '''
        Example
            >>> stat = await Statx('/path/to/some_file.ext')  # or
            >>> async with Statx('/path/to/some_file.ext') as stat:
            ...     stat.isfile
            True
            ...     stat.stx_size
            123

        Note
            - Refer to `help(Statx)` to see further details. 
    '''
    def __cinit__(self,
                  object path not None,
                  int flags=0,
                  unsigned int mask=0,
                  int dir_fd=__AT_FDCWD):
        self._path = path if type(path) is bytes else path.encode()
        self._mask = mask
        self._flags = flags
        self._dir_fd = dir_fd

    async def __ainit__(self):
        cdef SQE sqe = SQE()
        io_uring_prep_statx(sqe, self, self._path, self._flags, self._mask,  self._dir_fd)
        await sqe
        trap_error(sqe.result)

    # AsyncBase >>> START
    def __await__(self):  # midsync
        return self.__aenter__().__await__()

    async def __aenter__(self):
        if self.__awaited__:
            return self
        r = await self.__ainit__()
        self.__awaited__ = True
        return self if r is None else r

    async def __aexit__(self, *errors):
        if any(errors):
            return False
    # AsyncBase <<< END


async def exists(object path not None):
    ''' Path Exists Check

        Type
            path:   str | bytes
            return: bool

        Example
            >>> if await exists('some/path'):
            ...     # do stuff
    '''
    try:
        await Statx(path)
    except OSError:
        return False
    return True
