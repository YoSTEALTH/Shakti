import os
from _socket import socket, \
                    AF_INET, SOCK_STREAM, SOCK_CLOEXEC, SOL_SOCKET, SO_ERROR, SOCK_NONBLOCK, MSG_DONTWAIT, \
                    SHUT_RDWR, IPPROTO_TCP, SO_KEEPALIVE, TCP_KEEPIDLE, TCP_KEEPINTVL, TCP_KEEPCNT
from select import POLLIN, POLLOUT, POLLERR, POLLHUP
from liburing import SPLICE_F_NONBLOCK, SPLICE_F_MORE, SPLICE_F_MOVE, IOSQE_IO_HARDLINK, IOSQE_ASYNC, \
                     ffi, sockaddr_in, sockaddr, io_uring_prep_poll_add, io_uring_prep_connect, \
                     io_uring_prep_accept, io_uring_prep_recv, io_uring_prep_send, io_uring_prep_splice, \
                     io_uring_prep_close, NULL
from shakti import AsyncBase, ConnectionNotEstablishedError, entry, entries, closed, trap_uint_error, fprint
from_buffer = ffi.from_buffer


__all__ = 'Socket'


class Socket:

    def __init__(self, family=None, type=None, proto=None, fileno=None, secure=None):
        self._family = AF_INET if family is None else family
        self._type = SOCK_STREAM | SOCK_CLOEXEC if type is None else type
        self._proto = 0 if proto is None else proto
        self._secure = secure
        # create socket
        self._socket = socket(self._family, self._type, self._proto, fileno)
        self._fd = self._socket.fileno()
        # non-blocking
        self.setblocking(False)
        # TODO:
        # self._socket.getsockopt(_socket.IPPROTO_TCP, _socket.TCP_CORK, 1)

    def __bool__(self):
        return bool(self._fd)
        #

    def __enter__(self):
        name = self.__class__.__name__
        raise SyntaxError(f'`with {name}() ...:` should be `async with {name}() ...:`')

    async def __aenter__(self):
        return self
        #

    async def __aexit__(self, *errors):
        if self._fd:
            # await self.shutdown()
            await self.close()

        if any(errors):
            # fprint(f'`{self.__class__.__name__}.__aexit__` fd: {self._fd} errors: {errors!r}')
            return False

    @property
    def fd(self):
        ''' File Descriptor

            Type
                return: int

            Example
                >>> fd = Socket.fd
        '''
        return self._fd

    @property
    def secure(self):
        ''' Secure Socket Transport Layer (TLS/SSL)

            Type
                return: bool

            Example
                >>> Socket.secure
        '''
        return self._secure

    def setblocking(self, value):
        self._non_blocking = not value
        self._socket.setblocking(value)

    @closed
    async def getpeername(self):
        return self._socket.getpeername()
        # TODO: temp fix till better solution can be found.

    @closed
    async def getsockname(self):
        return self._socket.getsockname()
        # TODO: temp fix till better solution can be found.

    @closed
    async def setsockopt(self, *args, **kwargs):
        '''
            Example
                >>> async with Socket() as server:
                ...     await server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
        '''
        # TODO: temp fix
        return self._socket.setsockopt(*args, **kwargs)
        # TODO: `liburing` equalant

    @closed
    async def listen(self, backlog):
        '''
            Type
                backlog: int
                return:  None

            Example
                >>> async with Socket() as server:
                ...     await server.listen(123)
        '''
        # TODO: temp fix
        return self._socket.listen(backlog)
        # TODO: `liburing` equalant

    @closed
    async def bind(self, host, port):
        '''
            Type:
                host:   str
                port:   int
                return: None

            Example
                >>> async with Socket() as server:
                ...     await server.bind('0.0.0.0', 3000)
        '''
        # TODO: temp fix
        self._socket.bind((host, port))
        # TODO: `liburing` equalant

    @closed
    async def connect(self, host, port, retry=12):
        '''
            Type
                host:   str
                port:   int
                retry:  int
                chain:  Optional[bool]
                return: None

            Example
                >>> async with Socket() as client:
                ...     await client.connect('0.0.0.0', 3000)
        '''
        for _ in range(retry):
            try:
                sock_addr, sock_len = sockaddr_in(host, port)  # don't move
                return await entry(io_uring_prep_connect, (self._fd, sock_addr, sock_len))
            except BlockingIOError:
                # fprint('connect BlockingIOError')
                await entry(io_uring_prep_poll_add, (self._fd, POLLOUT | POLLHUP | POLLERR))
                if (success := self._socket.getsockopt(SOL_SOCKET, SO_ERROR)) == 0:
                    # fprint('connection success:', success)
                    return success
            except OSError:
                pass  # retry
        raise ConnectionNotEstablishedError(f'can not connecto to host:{host!r} port:{port!r}')
        # TODO:
        # if self._secure:
        #     # do ssl stuff

    @closed
    async def accept(self, flags=0):
        '''
            Type
                flags:  int
                chain:  Optional[bool]
                return: Tuple[Socket, str, int]

            Example
                >>> async with Socket() as server:
                ...     client = await server.accept()
                ...     ip, port = await cleint.getpeername()
        '''
        # # fprint('accept')
        if self._non_blocking:
            flags |= SOCK_NONBLOCK

        while True:
            try:
                sock_addr, sock_len = sockaddr()
                client_fd = await entry(io_uring_prep_accept, (self._fd, sock_addr, sock_len, flags))
            except BlockingIOError:
                # fprint('accept BlockingIOError', self._fd)
                await entry(io_uring_prep_poll_add, (self._fd, POLLIN | POLLERR | POLLHUP))
            else:
                client = self.__class__(self._family, self._type, self._proto, client_fd, self._secure)
                return client, client._socket.getpeername()  # e.g. <client>, ip, port
                # TODO:
                #   - should use "IOSQE_IO_LINK" accept with ``io_uring_prep_getpeername()`` together
