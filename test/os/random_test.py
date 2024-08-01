import shakti


def test_random():
    shakti.run(main())


async def main():
    data = await shakti.random_bytes(0)
    assert len(data) == 0
    assert data == b''

    data = await shakti.random_bytes(12)
    assert len(data) == 12
    assert data != b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
