import pytest
import shakti


def test_socket():
    random_port = []
    shakti.run(
        socket(),
        bind(),
        listen(),
        echo_client(random_port),
        echo_server(random_port),
    )


@pytest.mark.skip_linux(6.7)
def test_sockname():
    shakti.run(set_get_sockname())


async def socket():
    # file descriptor
    assert (sock_fd1 := await shakti.socket()) > 0  # shakti.AF_INET, shakti.SOCK_STREAM
    assert (sock_fd2 := await shakti.socket(shakti.AF_UNIX, shakti.SOCK_DGRAM)) > sock_fd1
    await shakti.close(sock_fd1)
    await shakti.close(sock_fd2)

    # direct descriptor without register
    with pytest.raises(OSError, match='Either file table is full or register file not enabled!'):
        assert await shakti.socket(direct=True)

    # TODO: direct descriptor with register
    # assert (sock_fd := await shakti.socket(direct=True)) == 0
    # await shakti.close(sock_fd, True)


async def bind():
    # IPv4
    sockfd = await shakti.socket()
    addr = await shakti.bind(sockfd, '127.0.0.1', 0)
    ip, port = await shakti.getsockname(sockfd, addr)
    assert ip == '127.0.0.1'
    assert port > 1000
    await shakti.close(sockfd)

    # TODO:
    # IPv6
    # sockfd = await shakti.socket(shakti.AF_INET6)
    # addr = await shakti.bind(sockfd, '::1', 12345)
    # ip, port = await shakti.getsockname(sockfd, addr)
    # assert ip == '::1'
    # assert port > 1000
    # await shakti.close(sockfd)


async def listen():
    sockfd = await shakti.socket()
    await shakti.bind(sockfd, '127.0.0.1', 0)
    assert await shakti.listen(sockfd, 1) == 0
    await shakti.close(sockfd)


async def echo_server(random_port):
    assert (server_fd := await shakti.socket()) > 0
    try:
        addr = await shakti.bind(server_fd, '127.0.0.1', 0)  # random port
        assert await shakti.listen(server_fd, 1) == 0
        ip, port = await shakti.getsockname(server_fd, addr)
        assert ip == '127.0.0.1'
        assert port > 1000
        random_port.append(port)
        while client_fd := await shakti.accept(server_fd):
            # await task(client_handler(client_fd))
            await client_handler(client_fd)
            break
    finally:
        await shakti.close(server_fd)


async def client_handler(client_fd):
    assert await shakti.recv(client_fd, 1024) == b'hi from `echo_client`'
    assert await shakti.send(client_fd, b'hi from `echo_server`') == 21
    await shakti.shutdown(client_fd)
    await shakti.close(client_fd)


async def echo_client(random_port):
    await shakti.sleep(.001)  # wait for `echo_server` to start up.
    assert (client_fd := await shakti.socket())
    try:
        await shakti.connect(client_fd, '127.0.0.1', random_port[0])
        assert await shakti.send(client_fd, b'hi from `echo_client`') == 21
        assert await shakti.recv(client_fd, 1024) == b'hi from `echo_server`'
    finally:
        await shakti.close(client_fd)


async def set_get_sockname():
    assert (socket_fd := await shakti.socket()) > 0
    try:
        await shakti.setsockopt(socket_fd, shakti.SOL_SOCKET, shakti.SO_REUSEADDR, 1)
        assert await shakti.getsockopt(socket_fd, shakti.SOL_SOCKET, shakti.SO_REUSEADDR) == 1

        await shakti.setsockopt(socket_fd, shakti.SOL_SOCKET, shakti.SO_REUSEADDR, 0)
        assert await shakti.getsockopt(socket_fd, shakti.SOL_SOCKET, shakti.SO_REUSEADDR) == 0
    finally:
        await shakti.close(socket_fd)
