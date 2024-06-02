import errno
import liburing
import pytest
import shakti


def test_SQE():
    shakti.run(
        single_sqe(),
        multiple_sqes(1000),
        with_statement()
    )


async def single_sqe():
    sqe = shakti.SQE()
    liburing.io_uring_prep_openat(sqe, b'/dev/zero')
    await sqe
    await shakti.close(fd := sqe.result)  # fd
    assert fd > 0

    with pytest.raises(ValueError):
        shakti.SQE(1025)


async def multiple_sqes(loop):
    sqes = shakti.SQE(loop, True)
    for i in range(loop):
        liburing.io_uring_prep_openat(sqes[i], b'/dev/zero')
    await sqes
    for i in range(loop):
        await shakti.close(fd := sqes[i].result)
        assert fd > 0


async def with_statement():
    # single
    async with shakti.SQE(error=False) as sqe:
        liburing.io_uring_prep_openat(sqe, b'/dev/zero')
    await shakti.close(fd := sqe.result)  # fd
    assert fd > 0

    #  multiple
    async with shakti.SQE(2, error=False) as sqe:
        liburing.io_uring_prep_openat(sqe, b'/bad-link')
        liburing.io_uring_prep_openat(sqe[1], b'/dev/zero')
    assert sqe.result == -errno.ENOENT
    await shakti.close(fd := sqe[1].result)  # fd
    assert fd > 0
