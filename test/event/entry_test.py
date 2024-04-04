import re
import liburing
import pytest
import shakti


def test_entry():
    shakti.run(nop_entry())


async def nop_entry():
    sqe = liburing.io_uring_sqe()
    liburing.io_uring_prep_nop(sqe)
    assert (await shakti.entry(sqe)) == 0

    sqe = liburing.io_uring_sqe(2)
    msg = re.escape('`entry(sqe)` received `> 1` entries, try using `entries()` or `help(entry)`')
    with pytest.raises(ValueError, match=msg):
        liburing.io_uring_prep_nop(sqe)
        assert (await shakti.entry(sqe)) == 0

    sqe = liburing.io_uring_sqe()
    msg = re.escape('`entry()` - Currently `flags` only support `0` or `IOSQE_ASYNC`.')
    with pytest.raises(ValueError, match=msg):
        liburing.io_uring_prep_nop(sqe)
        assert (await shakti.entry(sqe, flags=123)) == 0
