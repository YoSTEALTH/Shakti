import liburing
import pytest
import shakti


def test_SQE():
    shakti.run(
        nop_sqe(),
        nop_sqes(2),
        # nop_sqes(1024),  # TODO: segfault, look into it.
    )


async def nop_sqe():
    sqe = shakti.SQE()
    liburing.io_uring_prep_nop(sqe)
    await sqe
    assert sqe.result == 0

    with pytest.raises(ValueError):
        shakti.SQE(1025)


async def nop_sqes(loop):
    sqes = shakti.SQE(loop)
    for i in range(loop):
        liburing.io_uring_prep_nop(sqes[i])
    await sqes
    for _ in range(loop):
        assert sqes[i].result == 0
