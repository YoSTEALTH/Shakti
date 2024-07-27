import os.path
import pytest
import shakti


def test_file(tmp_dir):
    shakti.run(
        open_close(tmp_dir),
        read(),
        write(tmp_dir),

        # # File START >>>
        file_open_close(tmp_dir),
        temp_file(tmp_dir),
        resolve(tmp_dir),
        write_read(tmp_dir),
        # File END <<<
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


# File START >>>
async def file_open_close(tmp_dir):
    # normal file
    async with shakti.File(__file__) as file:
        assert file.fileno > 1
        assert file.path == __file__.encode()
        assert bool(file) is True
    assert bool(file) is False

    # temp file
    file = await shakti.File('.', 'T')
    assert file.fileno > 1
    assert file.path == b'.'
    assert bool(file) is True
    await file.close()
    assert bool(file) is False

    # create new file
    path = os.path.join(tmp_dir, 'exists.txt')
    await (await shakti.File(path, 'x')).close()
    with pytest.raises(FileExistsError):
        await (await shakti.File(path, 'x')).close()
    # ignore if file already exists
    await (await shakti.File(path, '!x')).close()


async def temp_file(tmp_dir):
    # openat
    async with shakti.File('.', 'Trw', encoding='latin-1') as file:
        assert await file.write('hello world') == 11
        assert await file.read(11, 0) == 'hello world'

    # openat2
    async with shakti.File('.', 'Trw', resolve=shakti.RESOLVE_CACHED) as file:
        assert await file.write('hello world') == 11
        assert await file.read(11, 0) == 'hello world'

    async with shakti.File('/tmp', 'T') as file:
        assert await file.write('hello world') == 11

    # create dummy blocker file
    path = os.path.join(tmp_dir, 'block.txt')
    await (await shakti.File(path, 'x')).close()

    with pytest.raises(NotADirectoryError):
        async with shakti.File(path, 'T') as file:
            assert await file.write('hello world') == 11


async def resolve(tmp_dir):
    file_path = os.path.join(tmp_dir, 'resolve_test.txt')
    # This will catch BlockingIOError that removes `RESOLVE_CACHED` from `how`
    # note: not really a way to test this other then to manual add `print` statement to see output.
    async with shakti.File(file_path, 'x', resolve=shakti.RESOLVE_CACHED):
        pass
    async with shakti.File(file_path, 'rwb', resolve=shakti.RESOLVE_CACHED) as file:
        assert await file.write(b'hello world') == 11
        assert await file.read(None, 0) == b'hello world'


async def write_read(tmp_dir):
    path = os.path.join(tmp_dir, 'test-write-open.txt')
    async with shakti.File(path, 'xb+') as file:
        # write
        assert await file.write(bytearray(b'hello')) == 5
        assert await file.write(b' ') == 1
        assert await file.write(memoryview(b'world')) == 5
        # read
        assert await file.read(5, 0) == b'hello'
        assert await file.read(6) == b' world'
        assert await file.read(5, 3) == b'lo wo'
        assert await file.read() == b'rld'
        assert await file.read(None, 0) == b'hello world'
        assert await file.read() == b''
        # type check
        assert isinstance(await file.read(11, 0), bytes)

    async with shakti.File(path) as file:
        assert await file.read() == 'hello world'

    # stats eheck
    assert (await shakti.Statx(path)).stx_size == 11
# File END <<<
