import pytest
import shakti


def test_socket():
    shakti.run(
        socket()
    )


async def socket():
    # file descriptor
    assert (sock_fd1 := await shakti.socket()) > 0  # shakti.AF_INET, shakti.SOCK_STREAM
    assert (sock_fd2 := await shakti.socket(shakti.AF_UNIX, shakti.SOCK_DGRAM)) > sock_fd1
    await shakti.close(sock_fd1)
    await shakti.close(sock_fd2)

    # direct descriptor without register
    with pytest.raises(OSError, match='Either file table is full or register file not enabled!'):
        assert await shakti.socket(direct=True)

    # TODO: direct descriptor with register
    # assert (sock_fd := await shakti.socket(direct=True)) == 0
    # await shakti.close(sock_fd, True)
