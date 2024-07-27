from shakti import O_CREAT, O_RDWR, O_APPEND, run, open, read, write, close


async def main():
    fd = await open('/tmp/shakti-test.txt', O_CREAT | O_RDWR | O_APPEND)
    print('fd:', fd)

    wrote = await write(fd, b'hi...bye!')
    print('wrote:', wrote)

    content = await read(fd, 1024)
    print('read:', content)

    await close(fd)
    print('closed.')


if __name__ == '__main__':
    run(main())
