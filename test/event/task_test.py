import pytest
import shakti


def test_task():
    shakti.run(task_error(), task_check(), task_multi())


async def task_error():
    with pytest.raises(TypeError):
        await shakti.task(bad)

    with pytest.raises(ValueError):
        await shakti.task()


async def task_check():
    r = []
    await shakti.task(echo(r, 1))
    await shakti.sleep(.001)
    assert r == [0]
    await shakti.sleep(.003)
    assert r == [0, 1]


async def task_multi():
    r = []
    await shakti.task(echo(r, 1), echo(r, 2), echo(r, 3))
    await shakti.sleep(.05)
    assert len(r) == 2 + 4 + 6


# resource start >>>
def bad():
    pass


async def echo(r, value):
    for i in range(value):
        r.append(i)
        await shakti.sleep(.002)
        r.append(i+1)
# resource end <<<
