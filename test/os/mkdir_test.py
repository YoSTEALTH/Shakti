import os
import shakti


def test(tmp_dir):
    shakti.run(
        mkdir(tmp_dir)
    )


async def mkdir(tmp_dir):
    dir_path = str(tmp_dir / 'dir')
    await shakti.mkdir(dir_path)

    async with shakti.Statx(dir_path) as stat:
        assert stat.isdir
        assert not stat.isfile
        assert (stat.stx_mode & 0o777) == 0o777 - os.umask(0)  # 755
