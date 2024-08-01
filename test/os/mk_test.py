import os
import pytest
import shakti


def test(tmp_dir):
    shakti.run(
        mkdir(tmp_dir),

        # mktdir START >>>
        make_temp_dir(tmp_dir),
        make_remove_tmp(),
        make_error(tmp_dir)
        # mktdir END <<<
    )


async def mkdir(tmp_dir):
    dir_path = str(tmp_dir / 'dir')
    await shakti.mkdir(dir_path)

    async with shakti.Statx(dir_path) as stat:
        assert stat.isdir
        assert not stat.isfile
        assert (stat.stx_mode & 0o777) == 0o777 - os.umask(0)  # 755


# mktdir START >>>
async def make_temp_dir(tmp_dir):
    tmpdir = str(tmp_dir)
    one = await shakti.mktdir(mode=0o440, tempdir=tmpdir)
    async with shakti.Statx(one) as stat:
        assert stat.isdir
        assert not stat.isfile
        assert (stat.stx_mode & 0o777) == 0o440

    # prep
    prefix = 'start-'
    suffix = '-end'
    tmp_len = len(tmpdir)+1

    one = await shakti.mktdir(prefix, suffix, length=19, tempdir=tmpdir)
    assert await shakti.exists(one)
    assert len(one) == tmp_len + len(prefix) + len(suffix) + 19
    assert one[tmp_len:].startswith(prefix)
    assert one.endswith(suffix)


async def make_remove_tmp():
    # make and remove from "/tmp"
    tmp_path = await shakti.mktdir()
    assert len(tmp_path) == len('/tmp/') + 16  # default
    assert tmp_path.startswith('/tmp/')
    await shakti.remove(tmp_path, True)


async def make_error(tmp_dir):
    tmpdir = str(tmp_dir)
    # with pytest.raises(ValueError):
    assert await shakti.mktdir('', '', length=0, tempdir=tmpdir) == ''

    # None check
    with pytest.raises(TypeError):
        await shakti.mktdir(None, '', length=0, tempdir=tmpdir)
    with pytest.raises(TypeError):
        await shakti.mktdir('', None, length=0, tempdir=tmpdir)
    with pytest.raises(TypeError):
        await shakti.mktdir('', '', length=0, tempdir=None)

    # runs out of combination to create 
    i = 0
    tmp_path = await shakti.mktdir(tempdir=tmpdir)
    created = []
    with pytest.raises(shakti.DirExistsError):
        while True:
            i += 1
            created.append(await shakti.mktdir(length=1, tempdir=tmp_path))

    # remove files, doubles as created check.
    for i in created:
        await shakti.remove(shakti.join_string(tmp_path, i), True)
    await shakti.remove(tmp_path, True)
# mktdir END <<<
