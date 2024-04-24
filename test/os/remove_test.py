import pytest
import shakti


def test_remove(tmp_dir):
    shakti.run(
        remove_file_dir(tmp_dir)
    )


async def remove_file_dir(tmp_dir):
    file_path = tmp_dir / 'file.txt'
    file_path.write_text('test')
    file_path = str(file_path)

    file_path_2 = tmp_dir / 'file2.txt'
    file_path_2.write_text('test')
    file_path_2 = str(file_path_2)

    dir_path = tmp_dir / 'directory'
    dir_path.mkdir()
    dir_path = str(dir_path)

    await shakti.remove(file_path)                  # remove file
    await shakti.remove(file_path, ignore=True)     # ignore if file does not exist
    with pytest.raises(FileNotFoundError):
        await shakti.remove(file_path)

    await shakti.remove(file_path_2, ignore=True)   # ignore if file does not exist
    await shakti.remove(dir_path, True)             # remove directory

    assert not await shakti.exists(file_path)       # file should not exist
    assert not await shakti.exists(file_path_2)     # file should not exist
    assert not await shakti.exists(dir_path)        # dir should not exist
