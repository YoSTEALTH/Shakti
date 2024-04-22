from shakti import Timeit, run, sleep


async def main():
    print('hi', end='')
    for i in range(4):
        if i:
            print('.', end='')
        await sleep(1)
    print('bye!')


if __name__ == '__main__':
    with Timeit():
        run(main())
