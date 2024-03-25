|test-status|

Shakti
======
Work in progress...

Shakti will be providing developers with fast & powerful at easy to use Python Async Interface, without the complexity of using `liburing` and `io_uring` directly.

* Mostly all events are planned to go through `io_uring` backend, this is a design choice.

This is when `io_uring` starts becoming fun to use!


Requires
--------

    - Linux 6.7+
    - Python 3.8+


Install directly from GitHub:

.. code-block:: python

    # `liburing` must be installed first
    python3 -m pip install --upgrade git+https://github.com/YoSTEALTH/Liburing

    python3 -m pip install --upgrade git+https://github.com/YoSTEALTH/Shakti


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

.. |test-status| image:: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml/badge.svg?branch=master&event=push
    :target: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml
    :alt: Test status
