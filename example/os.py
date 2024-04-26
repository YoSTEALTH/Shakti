from shakti import run, mkdir, rename, remove, Statx, exists


async def main():
    mkdir_path = '/tmp/shakti-mkdir'
    rename_path = '/tmp/shakti-rename'

    # create directory
    print('create directory:', mkdir_path)
    await mkdir(mkdir_path)

    # check directory stats
    async with Statx(mkdir_path) as stat:
        print('is directory:', stat.isdir)
        print('modified time:', stat.stx_mtime)

    # rename
    print('rename directory:', mkdir_path, '-to->', rename_path)
    await rename(mkdir_path, rename_path)

    # check exists
    print(f'{mkdir_path!r} exists:', await exists(mkdir_path))
    print(f'{rename_path!r} exists:', await exists(rename_path))

    await remove(rename_path, is_dir=True)
    print(f'removed {rename_path!r} exists:', await exists(rename_path))
    print('done.')


if __name__ == '__main__':
    run(main())
