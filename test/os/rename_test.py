import pytest
import shakti


def test_rename(tmp_dir):
    shakti.run(
        rename_file(tmp_dir),
        rename_dir(tmp_dir),
        rename_error(tmp_dir),
        rename_exchange_flag(tmp_dir),
        rename_move(tmp_dir),
    )


async def rename_file(tmp_dir):
    old_file_path = tmp_dir / 'old_file.txt'
    old_file_path.write_text('old')
    old_file_path = str(old_file_path)

    new_file_path = str(tmp_dir / 'new_file.txt')

    assert await shakti.exists(old_file_path)
    assert not await shakti.exists(new_file_path)

    await shakti.rename(old_file_path, new_file_path)

    assert not await shakti.exists(old_file_path)          # old file should not exist
    assert await shakti.exists(new_file_path)              # renamed file should exist


async def rename_dir(tmp_dir):
    old_dir_path = str(tmp_dir / 'old_dir')
    new_dir_path = str(tmp_dir / 'new_dir')

    assert not await shakti.exists(old_dir_path)
    assert not await shakti.exists(new_dir_path)

    await shakti.mkdir(old_dir_path)
    assert await shakti.exists(old_dir_path)

    await shakti.rename(old_dir_path, new_dir_path)
    assert not await shakti.exists(old_dir_path)
    assert await shakti.exists(new_dir_path)


async def rename_error(tmp_dir):
    old_dir_path = str(tmp_dir / 'old_error')
    new_dir_path = str(tmp_dir / 'new_error')

    await shakti.mkdir(old_dir_path)
    await shakti.mkdir(new_dir_path)

    with pytest.raises(FileExistsError):
        await shakti.rename(old_dir_path, new_dir_path)


async def rename_exchange_flag(tmpdir):
    old_file_path = tmpdir / 'old_file_flag'
    old_file_path.write_text('old file')
    old_file_path = str(old_file_path)

    new_dir_path = str(tmpdir / 'new_dir_flag')
    await shakti.mkdir(new_dir_path)

    # rename exchange file and dir
    await shakti.rename(old_file_path, new_dir_path, shakti.RENAME_EXCHANGE)
    assert (await shakti.Statx(new_dir_path)).isfile  # should be file path now
    assert (await shakti.Statx(old_file_path)).isdir  # should be dir path now


async def rename_move(tmpdir):
    one = str(tmpdir / 'one')
    two = str(tmpdir / 'one' / 'two')
    mov = str(tmpdir / 'two')

    file_before = str(tmpdir / 'one' / 'two' / 'file.txt')
    file_after = str(tmpdir / 'two' / 'file.txt')

    await shakti.mkdir(one)
    await shakti.mkdir(two)

    with open(file_before, 'x+') as file:
        file.write('file before')

    # add a file into "./one/two" dir
    assert await shakti.exists(one)
    assert await shakti.exists(two)
    assert await shakti.exists(file_before)

    # using `rename` to move directory from './one/two' to './two'
    await shakti.rename(two, mov)
    assert await shakti.exists(one)
    assert not await shakti.exists(two)
    assert await shakti.exists(mov)
    assert await shakti.exists(file_after)
