from shakti import File, run


async def main():
    # create, read & write.
    async with File('/tmp/test.txt', '!x+') as file:
        wrote = await file.write('hi... bye!')
        print('wrote:', wrote)

        content = await file.read(5, 0)  # seek is set to `0`
        print('read:', content)

        # Other
        print('fd:', file.fileno)
        print('path:', file.path)
        print('active:', bool(file))


if __name__ == '__main__':
    run(main())

# Refer to `help(File)` to see full features of `File` class.
# help(File)
