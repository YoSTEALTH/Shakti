|test-status|

Shakti (Work in progress ... )
==============================

Shakti will be providing developers with fast & powerful yet easy to use Python Async Interface, without the complexity of using `Liburing`_ and ``io_uring`` directly.

* Mostly all events are planned to go through ``io_uring`` backend, this is a design choice.


*****NOTE*****
--------------

Work in progress... This project is in early ``planning`` state, so... its ok to play around with it but not for any type of serious development, yet!


Requires
--------

    - Linux 6.7+
    - Python 3.8+


Install directly from GitHub
----------------------------

.. code-block:: python
    
    # To install | upgrade. Includes ``liburing``.
    python3 -m pip install --upgrade git+https://github.com/YoSTEALTH/Shakti

    # To uninstall
    python3 -m pip uninstall shakti


Docs
----

To find out all the class, functions and definitions:

.. code-block:: python
    
    import shakti

    print(dir(shakti))  # to see all the importable names (this will not load all the modules)
    help(shakti)        # to see all the help docs (this will load all the modules.)
    help(shakti.Statx)  # to see specific function/class docs.


Example
-------

.. code-block:: python

    from shakti import Timeit, run, sleep


    async def main():
        print('hi', end='')
        for i in range(4):
            if i:
                print('.', end='')
            await sleep(1)
        print('bye!')


    if __name__ == '__main__':
        with Timeit():
            run(main())

File
____

.. code-block:: python

    from shakti import O_CREAT, O_RDWR, O_APPEND, run, open, read, write, close


    async def main():
        fd = await open('/tmp/shakti-test.txt', O_CREAT | O_RDWR | O_APPEND)
        print('fd:', fd)

        wrote = await write(fd, b'hi...bye!')
        print('wrote:', wrote)

        content = await read(fd, 1024)
        print('read:', content)

        await close(fd)
        print('closed.')


    if __name__ == '__main__':
        run(main())

OS
__

.. code-block:: python

    from shakti import Statx, run, mkdir, rename, remove, exists


    async def main():
        mkdir_path = '/tmp/shakti-mkdir'
        rename_path = '/tmp/shakti-rename'

        # create directory
        print('create directory:', mkdir_path)
        await mkdir(mkdir_path)

        # check directory stats
        async with Statx(mkdir_path) as stat:
            print('is directory:', stat.isdir)
            print('modified time:', stat.stx_mtime)

        # rename / move
        print('rename directory:', mkdir_path, '-to->', rename_path)
        await rename(mkdir_path, rename_path)

        # check exists
        print(f'{mkdir_path!r} exists:', await exists(mkdir_path))
        print(f'{rename_path!r} exists:', await exists(rename_path))

        # remove
        await remove(rename_path, is_dir=True)
        print(f'removed {rename_path!r} exists:', await exists(rename_path))
        print('done.')


    if __name__ == '__main__':
        run(main())

Socket
______

.. code-block:: python

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


.. code-block:: python

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


.. _Liburing: https://github.com/YoSTEALTH/Liburing

.. |test-status| image:: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml/badge.svg?branch=master&event=push
    :target: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml
    :alt: Test status
