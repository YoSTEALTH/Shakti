|test-status|

Shakti
======

Shakti will be providing developers with fast & powerful yet easy to use Python Async Interface, without the complexity of using `Liburing`_ and ``io_uring`` directly.

* Mostly all events are planned to go through ``io_uring`` backend, this is a design choice.

This is when ``io_uring`` starts becoming fun to use!


*** NOTE ***
------------
Work in progress... This project is in early ``planning`` state, so... its ok to play around with it but not for any type of serious development, yet.


Requires
--------

    - Linux 6.7+
    - Python 3.8+


Install directly from GitHub:
-----------------------------

.. code-block:: python
    
    # Use multi-thread for faster install. Change ``-j4`` to higher/lower value. Includes ``liburing``.
    python3 -m pip install --upgrade --config-setting="--build-option=build_ext -j4" git+https://github.com/YoSTEALTH/Shakti


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


.. _Liburing: https://github.com/YoSTEALTH/Liburing

.. |test-status| image:: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml/badge.svg?branch=master&event=push
    :target: https://github.com/YoSTEALTH/Shakti/actions/workflows/test.yml
    :alt: Test status
