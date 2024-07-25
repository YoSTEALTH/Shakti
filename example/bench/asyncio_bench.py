import asyncio
from socket import AF_INET, SOCK_STREAM, SOL_SOCKET, SO_REUSEADDR, IPPROTO_TCP, TCP_NODELAY, \
                   socket

LISTEN = 1024
BUFFSIZE = 1024
RESPONSE = b'HTTP/1.1 200 OK\r\n'
RESPONSE += b'Content-Type: text/html\r\n'
RESPONSE += b'Content-Length: 131\r\n'
RESPONSE += b'Connection:close\r\n\r\n'
RESPONSE += b'<!DOCTYPE html><html><head><title>Hello</title></head>'
RESPONSE += b'<body style="background-color:#151515;color:#ccc;">'
RESPONSE += b'Hello world!</body></html>'


async def echo_server(loop, address):
    print('Asyncio Start')
    sock = socket(AF_INET, SOCK_STREAM)
    sock.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
    sock.bind(address)
    sock.listen(LISTEN)
    sock.setblocking(False)
    with sock:
        while True:
            client, addr = await loop.sock_accept(sock)
            loop.create_task(echo_client(loop, client))
    print('Asyncio Closed')


async def echo_client(loop, client):
    with client:
        while await loop.sock_recv(client, BUFFSIZE):
            await loop.sock_sendall(client, RESPONSE)


if __name__ == '__main__':
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.set_debug(False)
    loop.create_task(echo_server(loop, ('127.0.0.1', 12345)))
    loop.run_forever()
    # e.g: `siege -b -c100 -r100 --delay=1 http://127.0.0.1:12345/`
