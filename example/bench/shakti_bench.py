import sys
sys.path.insert(0, '../../src')
# import socket as _socket
from shakti import SOL_SOCKET, SO_REUSEADDR, \
                   run, task, socket, setsockopt, bind, listen, accept, close, recv, sendall


LISTEN = 1024
BUFFSIZE = 1024
RESPONSE = b'HTTP/1.1 200 OK\r\n'
RESPONSE += b'Content-Type: text/html\r\n'
RESPONSE += b'Content-Length: 131\r\n'
RESPONSE += b'Connection:close\r\n\r\n'
RESPONSE += b'<!DOCTYPE html><html><head><title>Hello</title></head>'
RESPONSE += b'<body style="background-color:#151515;color:#ccc;">'
RESPONSE += b'Hello world!</body></html>'


async def echo_server(host, port):
    print('Starting Shakti Server')
    server_fd = await socket()
    try:
        await setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, True)
        await bind(server_fd, host, port)
        await listen(server_fd, LISTEN)
        while client_fd := await accept(server_fd):
            await task(client_handler(client_fd))
    finally:
        await close(server_fd)
        print('Closed Shakti Server')


async def client_handler(client_fd):
    # print("client_fd:", client_fd)
    while await recv(client_fd, BUFFSIZE):
        await sendall(client_fd, RESPONSE)
    await close(client_fd)


if __name__ == '__main__':
    run(echo_server('127.0.0.1', 12345))
    # e.g: `siege -b -c100 -r100 --delay=1 http://127.0.0.1:12345/`
