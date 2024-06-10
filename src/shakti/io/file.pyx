async def open(str path not None, __u64 flags=0, *,
               __u64 mode=0o660, __u64 resolve=0, int dir_fd=AT_FDCWD)-> int:
    '''
        Type
            path:    str
            flags:   int
            mode:    int
            resolve: int
            dir_fd:  int
            return:  int

        Flags
            O_CREAT
            O_RDWR
            O_RDONLY
            O_WRONLY
            O_TMPFILE
            ...

        Mode
            TODO

        Resolve
            RESOLVE_BENEATH
            RESOLVE_IN_ROOT
            RESOLVE_NO_MAGICLINKS
            RESOLVE_NO_SYMLINKS
            RESOLVE_NO_XDEV
            RESOLVE_CACHED

        Example
            >>> fd = await open('/path/file.ext') # read only
            >>> fd = await open('/path/file.ext', O_CREAT | O_WRONLY | O_APPEND)
            >>> fd = await open('/path/file.ext', O_RDWR, resolve=RESOLVE_CACHED)

        Note
            - `flags=0` is same as `O_RDONLY`
            - `mode` is only applied when using `flags` `O_CREAT` or `O_TMPFILE`
    '''
    cdef:
        _path = path.encode()
        SQE sqe = SQE()
        open_how how = open_how()

    if (flags & (O_CREAT | O_TMPFILE)):
        how.ptr.mode = mode
    how.ptr.flags = flags
    how.ptr.resolve = resolve

    io_uring_prep_openat2(sqe, _path, how, dir_fd)
    await sqe
    return sqe.result  # fd


async def read(int fd, __s32 length, __u64 offset=0)-> bytes:
    '''
        Example
            >>> await read(fd, length)
            b'hi...bye!'
    '''
    if not length: return b''
    cdef:
        SQE sqe = SQE()
        bytearray buffer = bytearray(length)
    io_uring_prep_read(sqe, fd, buffer, length, offset)
    await sqe
    return bytes(buffer if length == sqe.result else buffer[:sqe.result])


async def write(int fd, const unsigned char[:] buffer, __u64 offset=0)-> __s32:
    '''
        Type
            fd:     int
            buffer: bytes | bytearray | memoryview
            offset: int
            return: int

        Example
            >>> await write(fd, b'hi...bye!')
            9
    '''
    cdef unsigned int length = len(buffer)
    if not length: return 0
    cdef SQE sqe = SQE()
    io_uring_prep_write(sqe, fd, buffer, length, offset)
    await sqe
    return sqe.result
