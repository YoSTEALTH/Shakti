import socket


LISTEN = 1024
BUFFSIZE = 1024
RESPONSE = b'HTTP/1.1 200 OK\r\n'
RESPONSE += b'Content-Type: text/html\r\n'
RESPONSE += b'Content-Length: 131\r\n'
RESPONSE += b'Connection:close\r\n\r\n'
RESPONSE += b'<!DOCTYPE html><html><head><title>Hello</title></head>'
RESPONSE += b'<body style="background-color:#151515;color:#ccc;">'
RESPONSE += b'Hello world!</body></html>'


def echo_server(host, port):
    print('Starting Python Server')
    sock = socket.socket()
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, True)
    sock.bind((host, port))
    sock.listen(LISTEN)
    while True:
        client, addr = sock.accept()
        client_handler(client)  # note: runs synchronously
    sock.close()
    print('Closed Python Server')


def client_handler(client):
    with client:
        while client.recv(BUFFSIZE):
            client.sendall(RESPONSE)


if __name__ == '__main__':
    echo_server('127.0.0.1', 12345)
    # e.g: `siege -b -c100 -r100 --delay=1 http://127.0.0.1:12345/`
