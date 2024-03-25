import re
import pytest
import shakti


def test_sleep():
    with shakti.Timeit(False) as t:
        t.start
        shakti.run(
            sleep_test()
        )
    assert 1.5 < t.stop < 1.55


async def sleep_test():
    await shakti.sleep(1)   # int
    await shakti.sleep(.5)  # float

    msg = re.escape('`sleep(second)` can not be `< 0`')
    with pytest.raises(ValueError, match=msg):
        await shakti.sleep(-1)

    # TODO: need to test flags.
