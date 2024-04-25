import pytest
import shakti


def test_file(tmp_dir):
    shakti.run(
        open_close(tmp_dir),
        read(),
        write(tmp_dir),
    )


async def open_close(tmp_dir):
    file_path = str(tmp_dir)
    fd = await shakti.open(file_path, shakti.O_TMPFILE | shakti.O_RDWR)
    assert fd > 3
    assert await shakti.exists(file_path)
    await shakti.close(fd)

    file_path = str(tmp_dir / 'open.txt')
    fd = await shakti.open(file_path, shakti.O_CREAT)
    assert fd > 3
    await shakti.close(fd)

    async with shakti.Statx(file_path) as stat:
        assert stat.isfile

    with pytest.raises(OSError, match='Bad file descriptor'):
        await shakti.close(123)


async def read():
    fd = await shakti.open('/dev/random')
    assert len(await shakti.read(fd, 0)) == 0
    assert len(await shakti.read(fd, 10)) == 10
    await shakti.close(fd)


async def write(tmp_dir):
    file_path = str(tmp_dir / 'write.text')
    fd = await shakti.open(file_path,
                           shakti.O_CREAT | shakti.O_WRONLY | shakti.O_APPEND, mode=0o440)
    assert await shakti.write(fd, b'hi') == 2
    assert await shakti.write(fd, bytearray(b'...')) == 3
    assert await shakti.write(fd, memoryview(b'bye!')) == 4
    assert (await shakti.Statx(file_path)).stx_size == 9
    await shakti.close(fd)
