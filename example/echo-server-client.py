from shakti import SOL_SOCKET, SO_REUSEADDR, run, socket, bind, listen, accept, \
               connect, recv, send, shutdown, close, sleep, setsockopt, task


async def echo_server(host, port):
    print('Starting Server')
    server_fd = await socket()
    try:
        await setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, True)
        await bind(server_fd, host, port)
        await listen(server_fd, 1)
        while client_fd := await accept(server_fd):
            await task(client_handler(client_fd))
            break  # only handles 1 client and exit
    finally:
        await close(server_fd)
        print('Closed Server')


async def client_handler(client_fd):
    try:
        print('server recv:', await recv(client_fd, 1024))
        print('server sent:', await send(client_fd, b'hi from server'))
        await shutdown(client_fd)
    finally:
        await close(client_fd)


async def echo_client(host, port):
    await sleep(.001)  # wait for `echo_server` to start up.
    client_fd = await socket()
    await connect(client_fd, host, port)
    print('client sent:', await send(client_fd, b'hi from client'))
    print('client recv:', await recv(client_fd, 1024))
    await close(client_fd)


if __name__ == '__main__':
    host = '127.0.0.1'
    port = 12345
    run(echo_server(host, port), echo_client(host, port))
