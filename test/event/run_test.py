import re
import pytest
import shakti


def test_run():
    assert shakti.run() == []
    assert shakti.run(echo(1), echo(2), echo(3)) == [1, 2, 3]
    shakti.run(*[coro() for i in range(1000)])

    msg = '`run()` - `entries` is set too low! entries: 1'
    with pytest.raises(ValueError, match=re.escape(msg)):
        shakti.run(echo(1), echo(2), entries=1)

    msg = '`run()` - `entries` is set too high! max entries: 32768'
    with pytest.raises(ValueError, match=re.escape(msg)):
        shakti.run(*[echo(1) for i in range(32770)], entries=100_000)

    msg = '`run()` only accepts `CoroutineType`, like `async` function.'
    with pytest.raises(TypeError, match=re.escape(msg)):
        shakti.run(not_coro())


async def echo(arg):
    return arg


async def coro():
    return 'lost of coro'


def not_coro():
    return 'boo'
