from shakti import run, socket, connect, recv, send, close


async def client(host, port, path, header):
    print('client:', f'{host}:{port}{path}')
    received = bytearray()
    client_fd = await socket()
    await connect(client_fd, host, port)
    print('client sent:', await send(client_fd, header))
    while data := await recv(client_fd, 1024):
        received.extend(data)
    print('client recv:', len(received), received)
    await close(client_fd)
    print('closed')


if __name__ == '__main__':
    host = 'example.com'
    port = 80
    path = '/'
    header = f'GET {path} HTTP/1.0\r\nHost: {host}\r\nUser-Agent: Testing\r\n\r\n'.encode()
    # header = f'GET {path} HTTP/1.1\r\nHost: {host}\r\nUser-Agent: Testing\r\nConnection:close\r\n\r\n'.encode()
    run(client(host, port, path, header))
