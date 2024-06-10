import pytest
import shakti


def test_common(tmp_dir):
    shakti.run(close_error())


async def close_error():
    with pytest.raises(OSError, match='Bad file descriptor'):
        await shakti.close(12345)

    with pytest.raises(OSError, match='No such device or address'):
        await shakti.close(12345, True)
