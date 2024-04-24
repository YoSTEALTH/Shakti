import pytest
import socket
import shakti


def test_statx(tmp_dir):
    shakti.run(
        statx_class(tmp_dir),
        bad_file(),
        type_check(),
        exists_check(tmp_dir)
    )


async def statx_class(tmp_dir):
    async with shakti.Statx('/dev/zero') as statx:
        assert statx.stx_size == 0
        assert statx.isfile is False

    statx = await shakti.Statx('/dev/zero')
    assert statx.stx_size == 0
    assert statx.isfile is False

    # create socket file.
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(sock_path := str(tmp_dir / 'test.sock'))

    async with shakti.Statx(sock_path) as statx:
        assert statx.stx_size == 0
        assert statx.isfile is False
        assert statx.issock is True


async def bad_file():
    with pytest.raises(FileNotFoundError):
        await shakti.Statx('bad_file.txt')


async def type_check():
    with pytest.raises(TypeError):
        await shakti.Statx(None)


async def exists_check(tmp_dir):
    file_path = tmp_dir / 'file.txt'
    file_path.write_text('hi')
    file_path = str(file_path)

    dir_path = tmp_dir / 'directory'
    dir_path.mkdir()
    dir_path = str(dir_path)

    assert not await shakti.exists('no_file.txt')
    assert await shakti.exists(file_path)
    assert await shakti.exists(dir_path)
    with pytest.raises(TypeError):
        await shakti.exists(None)
