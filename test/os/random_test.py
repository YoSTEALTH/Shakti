import shakti


def test_random():
    shakti.run(main())


async def main():
    data = await shakti.random(12)
    assert len(data) == 12
