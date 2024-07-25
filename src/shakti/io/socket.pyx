async def socket(int family=__AF_INET, int type=__SOCK_STREAM, int protocol=0, unsigned int flags=0,
                 *, bint direct=False)-> int:
    ''' Create Socket

        Example
            >>> sock_fd = await socket()  # default: AF_INET, SOCK_STREAM
            ... ...

        Note
            - Setting `direct=True` will return direct descriptor index.
    '''
    cdef SQE sqe = SQE(error=False)
    if direct:
        io_uring_prep_socket_direct_alloc(sqe, family, type, protocol, flags)
    else:
        io_uring_prep_socket(sqe, family, type, protocol, flags)
    await sqe
    if sqe.result > -1:
        return sqe.result  # `fd` or `index`
    else:
        if direct and sqe.result == -ENFILE:
            raise_error(sqe.result, 'Either file table is full or register file not enabled!')
        raise_error(sqe.result)


async def connect(int sockfd, str host, in_port_t port=80):
    '''
        Example
            >>> sockfd = await socket()
            >>> await connect(sockfd, 'domain.ext')
            # or
            >>> await connect(sockfd, '0.0.0.0', 12345)
            # or
            >>> await connect(sockfd, '/path')
            ...
            >>> await close(sockfd)
    '''
    cdef:  # get family
        SQE         sqe = SQE()
        bytes       _host = host.encode()
        sockaddr    addr
        socklen_t   size = sizeof(__sockaddr_storage)
        __sockaddr  sa

    __getsockname(sockfd, &sa, &size)

    if sa.sa_family == __AF_UNIX:
        addr = sockaddr(sa.sa_family, _host, port)
        io_uring_prep_connect(sqe, sockfd, addr)
        await sqe
    elif sa.sa_family in (__AF_INET, __AF_INET6):
        if isIP(sa.sa_family, _host):
            addr = sockaddr(sa.sa_family, _host, port)
            io_uring_prep_connect(sqe, sockfd, addr)
            await sqe
        else:
            for af_, sock_, proto, canon, addr in _getaddrinfo(_host, str(port).encode()):
                try:
                    io_uring_prep_connect(sqe, sockfd, addr)
                    await sqe
                except OSError:
                    continue
                else:
                    break
    else:
        raise NotImplementedError


async def accept(int sockfd, int flags=0)-> int:
    '''
        Example
            >>> client_fd = await accept(socket_fd)
    '''
    cdef SQE sqe = SQE()
    io_uring_prep_accept(sqe, sockfd, None, flags)
    await sqe
    return sqe.result


async def recv(int sockfd, unsigned int bufsize, int flags=0):
    '''
        Example
            >>> await recv(client_fd, 13)
            b'received data'
    '''
    cdef:
        SQE         sqe = SQE()
        memoryview  buf = memoryview(bytearray(bufsize))
    io_uring_prep_recv(sqe, sockfd, buf, bufsize, flags)
    await sqe
    cdef unsigned int result = sqe.result
    return bytes(buf[:result] if result != bufsize else buf)


async def send(int sockfd, const unsigned char[:] buf, int flags=0):
    '''
        Example
            >>> await send(client_fd, b'send data')
            10
    '''
    cdef:
        SQE sqe = SQE()
        size_t length = len(buf)
    io_uring_prep_send(sqe, sockfd, buf, length, flags)
    await sqe
    return sqe.result


async def sendall(int sockfd, const unsigned char[:] buf, int flags=0):
    '''
        Example
            >>> await sendall(client_fd, b'send data')
            10
    '''
    cdef:
        SQE             sqe     = SQE()
        size_t          length  = len(buf)
        unsigned int    total   = 0

    while True:
        io_uring_prep_send(sqe, sockfd, buf[total:], length-total, flags)
        await sqe
        if (total := total + sqe.result) == length:
            break


async def shutdown(int sockfd, int how=__SHUT_RDWR):
    '''
        How
            SHUT_RD
            SHUT_WR
            SHUT_RDWR   # (default)
    '''
    cdef SQE sqe = SQE()
    io_uring_prep_shutdown(sqe, sockfd, how)
    await sqe


async def bind(int sockfd, str host, in_port_t port)-> object:
    '''
        Example
            >>> sockfd = await socket()
            
            >>> addr = await bind(sock_fd, '0.0.0.0', 12345)
            >>> await getsockname(sockfd, addr)
            '0.0.0.0', 12345

            # or

            >>> addr = await bind(sock_fd, '0.0.0.0', 0)  # random port
            >>> await getsockname(sockfd, addr)
            '0.0.0.0', 6744  # random port

            >>> await close(sockfd)
    '''
    cdef:  # get family
        __sockaddr  sa
        socklen_t   size = sizeof(__sockaddr_storage)

    __getsockname(sockfd, &sa, &size)

    cdef sockaddr addr = sockaddr(sa.sa_family, host.encode(), port)
    _bind(sockfd, addr)
    return addr


async def listen(int sockfd, int backlog)-> int:
    return _listen(sockfd, backlog)


async def getsockname(int sockfd, sockaddr addr)-> tuple[str, int]:
    cdef:
        bytes   ip
        int     port
    ip, port = _getsockname(sockfd, addr)
    return ip.decode(), port


async def setsockopt(int sockfd, int level, int optname, object optval):
    '''
        Example
            >>> await setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, 1)

        Warning
            - This function is still flawed, needs more testing.
    '''
    cdef:
        array val
        str t = type(optval).__name__
        # note: have to use `str` to check as `bool` type does not work well!

    if t in ('int', 'bool'):
        val = array('i', [optval])
    elif t == 'str':
        val = array('B', [optval.encode()])
    elif t == 'bytes':
        val = array('B', [optval])
    else:
        raise TypeError(f'`setsockopt` received `optval` type {t!r}, not supported')
    cdef SQE sqe = SQE()
    io_uring_prep_setsockopt(sqe, sockfd, level, optname, val)
    await sqe


async def getsockopt(int sockfd, int level, int optname)-> int:
    '''
        Example
            >>> await getsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR)
            1

        Warning
            - This function is still flawed, needs more testing.
    '''
    cdef:
        SQE sqe = SQE()
        array optval = array('i', [0])
    io_uring_prep_getsockopt(sqe, sockfd, level, optname, optval)
    await sqe
    return optval[0]
