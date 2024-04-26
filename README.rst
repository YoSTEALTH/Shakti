|test-status|

Shakti (Work in progress ... )
==============================

Shakti will be providing developers with fast & powerful yet easy to use Python Async Interface, without the complexity of using `Liburing`_ and ``io_uring`` directly.

* Mostly all events are planned to go through ``io_uring`` backend, this is a design choice.

This is when ``io_uring`` starts becoming fun to use!


*****NOTE*****
--------------

Work in progress... This project is in early ``planning`` state, so... its ok to play around with it but not for any type of serious development, yet.


Bug
---

Currently there is a bug running around causing ``Segfault`` on higher volume e.g. `SQE(1024)`, not really sure what causes it. If you find it do let me know ;)


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

    from shakti import run, mkdir, rename, remove, Statx, exists


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

        # rename
        print('rename directory:', mkdir_path, '-to->', rename_path)
        await rename(mkdir_path, rename_path)

        # check exists
        print(f'{mkdir_path!r} exists:', await exists(mkdir_path))
        print(f'{rename_path!r} exists:', await exists(rename_path))

        await remove(rename_path, is_dir=True)
        print(f'removed {rename_path!r} exists:', await exists(rename_path))
        print('done.')


    if __name__ == '__main__':
        run(main())



.. _Liburing: https://github.com/YoSTEALTH/Liburing

.. |test-status| image:: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml/badge.svg?branch=master&event=push
    :target: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml
    :alt: Test status
