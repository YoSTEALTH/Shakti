import errno
import liburing
import pytest
import shakti


def test_SQE():
    print()
    shakti.run(
        zero_sqe(),
        zero_sqes(2),
        # zero_sqes(1024),  # TODO: segfault, look into it.
        with_statement(),
    )


async def zero_sqe():
    sqe = shakti.SQE()
    liburing.io_uring_prep_openat(sqe, b'/dev/zero')
    await sqe
    assert sqe.result > 0

    with pytest.raises(ValueError):
        shakti.SQE(1025)


async def zero_sqes(loop):
    sqes = shakti.SQE(loop)
    for i in range(loop):
        liburing.io_uring_prep_openat(sqes[i], b'/dev/zero')
    await sqes
    for i in range(loop):
        assert sqes[i].result > 0


async def with_statement():
    # single
    async with shakti.SQE(error=False) as sqe:
        liburing.io_uring_prep_openat(sqe, b'/dev/zero')
    assert sqe.result > 0

    #  multiple
    async with shakti.SQE(2, error=False) as sqe:
        liburing.io_uring_prep_openat(sqe, b'/bad-link')
        liburing.io_uring_prep_openat(sqe[1], b'/dev/zero')
    assert sqe.result == -errno.ENOENT
    assert sqe[1].result > 0
