FILE_ACCEESS = {'x', 'a', 'r', 'w', 'b', '+', '!', 'T'}


cdef class File(IOBase):

    def __init__(self,
                 str path not None,
                 str access not None='r',
                 __u64 mode=0o660,
                 *,
                 __u64 resolve=0,
                 dir_fd=AT_FDCWD,
                 **kwargs):
        ''' Asynchronous "io_uring" File I/O - easy to use, highly optimized.

            Type
                path:    str
                access:  str
                mode:    int
                resolve: int
                dir_fd:  int
                kwargs:  Dict[str, Union[str, int]]     # extended features
                return:  None

            Kwargs
                flags:      int  # `O_*` flags
                encoding:   str

            Resolve
                RESOLVE_NO_XDEV
                RESOLVE_NO_MAGICLINKS
                RESOLVE_NO_SYMLINKS
                RESOLVE_BENEATH
                RESOLVE_IN_ROOT
                RESOLVE_CACHED

            Example
                # exclusive creation of file
                >>> await (await File('file.txt', 'x')).close()

                # ignore already created file if exists
                >>> await (await File('file.txt', '!x')).close()

                # set permissions
                >>> await (await File('file.txt', 'x', 0o777)).close()

                # writing - also truncates
                >>> async with File('file.txt', 'w') as file:
                ...     await file.write('hello ')

                # append
                >>> async with File('file.txt', 'a') as file:
                ...     await file.write('world!')

                # reading (default)
                >>> async with File('file.txt') as file:
                ...     await file.read()
                'hello world!'

                # temporary file - deleted after use
                >>> async with File('.', 'T') as file:
                ...     await file.write(b'hi')

                # Other
                >>> async with File('path/file.exe') as file:
                ...     file.fileno
                123
                ...     bool(file)
                True
                ...     file.path
                b'path/file.exe'

            Note
                - Allows reading and writing in str & bytes like types.
                - `access` parameter supports:
                    "r"  Open the file for reading; the file must already exist. (default)
                    "r+" Open the file for both reading and writing; the file must already exist.
                    "w"  Open the file for writing only. Truncates file.
                    "w+" Open the file for reading and writing only. Truncates file.
                    "x"  Open for exclusive creation of new file and failing if file already exists
                    "!x" Open for exclusive creation of new file and ignored if file already exists
                    "a"  Open for writing, appending to the end of the file
                    'b'  Open in bytes mode, default is text mode
                    "T"  Temporary regular file. Will be deleted on close. If not present "w" will
                         be auto set as temporary file can not be opened without it. Should use
                         `linkat` to save as proper file
                    "!T" Prevents a temporary file from being linked into the filesystem
                - Mode can be combined e.g. `access='rw'` for reading and writing.
                - Internally maintains offset + read/write last seek position.
                - `AT_FDCWD` uses current working directory, if `path` is relative path.
        '''
        cdef set[str] found
        if found := set(access) - FILE_ACCEESS:
            self.msg = f'`{self.__class__.__name__}(access)` - '
            self.msg += f'{"".join(found)!r} is not supported, only {FILE_ACCEESS!r}'
            raise ValueError(self.msg)

        self._encoding = kwargs.get('encoding', 'utf8')
        self._resolve = resolve
        self._dir_fd = dir_fd
        self.fileno = -1
        self._flags = kwargs.get('flags', 0)
        self._mode = mode
        self._seek = 0
        self.path = path.encode()

        # True/False
        self._bytes = 'b' in access
        self._append = 'a' in access
        self._creating = 'x' in access
        if '+' in access:
            self._writing = self._reading = True
        else:
            self._reading = 'r' in access  # or 'b' in access
            self._writing = 'w' in access

        if self._append and self._writing:
            self.msg = f'`{self.__class__.__name__}()` - must have exactly one of write/append mode'
            raise ValueError(self.msg)

        # exclusive create & write
        if 'x' in access:
            if '!' not in access:
                self._flags |= O_EXCL
            self._flags |= O_CREAT

        # temp file
        if 'T' in access:
            if self._creating:
                self.msg = f'`{self.__class__.__name__}()` - '
                self.msg += 'can not mix create new file and create temporary file!'
                raise ValueError(self.msg)
            if '!' not in access:
                self._flags |= O_EXCL
            if not self._writing:
                self._writing = True
            self._creating = True
            self._flags |= O_TMPFILE

        # truncate to zero
        if 'w' in access:
            self._flags |= O_TRUNC

        # read & write
        if self._reading and self._writing:
            self._flags |= O_RDWR
        elif self._writing:
            self._flags |= O_WRONLY
        elif not self._creating:
            self._flags |= O_RDONLY

        # append
        if self._append:
            if self._writing:
                self.msg = f'`{self.__class__.__name__}()` - can not mix write and append!'
                raise ValueError(self.msg)
            self._writing = True
            self._flags |= O_APPEND

        if not (O_CREAT | O_TMPFILE) & self._flags:
            self._mode = 0

        if self._flags & O_NONBLOCK:
            self.msg = f'`{self.__class__.__name__}()` - '
            self.msg += 'does not support `*_NONBLOCK` as its already asynchronous!'
            raise ValueError(self.msg)

    # midsync
    def __ainit__(self):
        return self.open()

    # midsync
    def __aenter__(self):
        return super().__aenter__()

    # midsync
    def __aexit__(self, *errors):
        '''
            Type
                errors: Tuple[any]
                return: coroutine
        '''
        if any(errors):
            self.fileno = -1
            return super().__aexit__(*errors)
            # note: if errors happens async is blocked! thus needs to use normal close.
        else:
            return self.close()

    def __bool__(self):
        return self.fileno > -1

    async def open(self):
        '''
            Example
                # automatically open & close file
                >>> async with File(...):
                ...     ...

                # or manually open & close file
                >>> file = File(...)
                >>> await file.open()
                >>> await file.close()

                # or automatically open file but have to close manually
                >>> file = await File(...)
                >>> await file.close()

            Note
                - `File.open` combines features of `openat` & `openat2` as its own.
        '''
        cdef:
            SQE         sqe = SQE()
            open_how    how

        if self.fileno > -1:
            self.msg = f'`{self.__class__.__name__}` is already open!'
            raise UnsupportedOperation(self.msg)

        if self._resolve:
            how = open_how(self._flags, self._mode, self._resolve)
            try:
                io_uring_prep_openat2(sqe, self.path, how, self._dir_fd)
                await sqe
            except BlockingIOError:
                if how.resolve & RESOLVE_CACHED:
                    how.resolve &= ~RESOLVE_CACHED
                    # note: must retry without `RESOLVE_CACHED` since file path
                    #       was not in kernel's lookup cache.
                io_uring_prep_openat2(sqe, self.path, how, self._dir_fd)
                await sqe
        else:
            io_uring_prep_openat(sqe, self.path, self._flags, self._mode, self._dir_fd)
            # note: `EWOULDBLOCK` would be raised if `O_NONBLOCK` `flags` was set.
            #       Since this class does not allow `O_NONBLOCK` flag to be set
            #       there is no point accounting for that error.
            await sqe
        self.fileno = sqe.result

    async def close(self):
        self.closed()

        cdef SQE sqe = SQE()

        if self._direct:
            io_uring_prep_close_direct(sqe, self.fileno)
        else:
            io_uring_prep_close(sqe, self.fileno)
        await sqe
        self.fileno = -1

    async def read(self, object length=None, object offset=None)-> str | bytes:
        '''
            Type
                length: Optional[int]
                offset: Optional[int]
                return: str | bytes

            Example
                # file content: b'hello world'

                >>> await file.read(5)
                b'hello'

                >>> await file.read(6)
                b' world'

                >>> await file.read(5, 3)
                b'lo wo'

                >>> await file.read()
                b'rld'

                >>> await file.read(offset=0)
                b'hello world'

                >>> async with File('path/file') as file:
                >>>     await file.read()
                b'hello world'

            Note
                - if `offset` is not set last read/write seek position is used
        '''
        self.closed()
        self.reading()

        cdef:
            SQE     sqe = SQE()
            statx   stat
            __u64   _length, _offset = self._seek if offset is None else offset

        if length is None:
            stat = statx()
            io_uring_prep_statx(sqe, stat, self.path, 0, STATX_SIZE, self._dir_fd)
            await sqe
            _length = stat.stx_size
        else:
            _length = length

        cdef bytearray buffer = bytearray(_length)

        io_uring_prep_read(sqe, self.fileno, buffer, _length, _offset)
        await sqe
        cdef unsigned int result = sqe.result

        self._seek = _offset + result
        if self._bytes:
            return bytes(buffer if _length == result else buffer[:result])
        else:
            return (buffer if _length == result else buffer[:result]).decode(self._encoding)

    async def write(self, object data, object offset=None)-> __u32:
        '''
            Type
                data:   Union[str, bytes, bytearray, memoryview]
                offset: int
                return: int

            Example
                >>> async with File('path/file', 'w') as file:
                ...     await file.write('hi... bye!')
                10

                >>> async with File('path/file', 'wb') as file:
                ...     await file.write(b'hi... bye!')
                10

            Note
                - if `offset` is not set last read/write seek position is used
        '''
        self.closed()
        self.writing()

        if self._append and offset is not None:
            self.msg = f'`{self.__class__.__name__}.write()` '
            self.msg += '- `offset` can not be used while file is opened for append!'
            raise UnsupportedOperation(self.msg)

        if not data:
            return 0

        cdef:
            SQE     sqe = SQE()
            __u64   _offset = self._seek if offset is None else offset

        if not self._bytes:
            data = data.encode(self._encoding)

        io_uring_prep_write(sqe, self.fileno, data, len(data), _offset)
        await sqe

        cdef __u32 result = sqe.result
        self._seek = _offset + result
        return result


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


async def write(int fd, const unsigned char[:] buffer, __u64 offset=0)-> __u32:
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
    cdef __u32 length = len(buffer)

    if length == 0:
        return length

    cdef SQE sqe = SQE()
    io_uring_prep_write(sqe, fd, buffer, length, offset)
    await sqe

    return (length := sqe.result)
