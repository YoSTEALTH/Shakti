import re
import pytest
import shakti


def test_sleep():
    with shakti.Timeit(False) as t:
        t.start
        shakti.run(
            sleep_test()
        )
    assert 1.25 < t.stop < 1.3


async def sleep_test():
    await shakti.sleep(1)   # int
    await shakti.sleep(.25)  # float

    msg = re.escape('`sleep(second)` can not be `< 0`')
    with pytest.raises(ValueError, match=msg):
        await shakti.sleep(-1)

    # TODO: need to test flags.
