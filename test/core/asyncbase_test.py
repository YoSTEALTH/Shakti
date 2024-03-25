import pytest
from shakti import run, AsyncBase


def test_async():
    run(
        await_class(),
        with_class()
    )


class AsyncTest(AsyncBase):
    async def __ainit__(self):
        self.hello = 'hello world'

    async def call(self):
        return 'you called?'


async def await_class():
    a = await AsyncTest()
    assert a.hello == 'hello world'
    
    with pytest.raises(AttributeError):
        a.something

    b = AsyncTest()
    with pytest.raises(AttributeError):
        assert b.hello  # note: since `await` isn't used `__ainit__` isn't initialized.
    assert await b.call() == 'you called?'

    async with AsyncTest() as test:
        assert test.hello == 'hello world'
        assert await test.call() == 'you called?'


async def with_class():
    with pytest.raises(SyntaxError):
        with AsyncTest():
            pass
