import pytest
import shakti


def test_error(tmp_dir):
    shakti.run(error())


async def error():
    with pytest.raises(shakti.CancelledError):
        raise shakti.CancelledError()

    with pytest.raises(shakti.UnsupportedOperation):
        raise shakti.UnsupportedOperation()

    with pytest.raises(shakti.ConnectionNotEstablishedError):
        raise shakti.ConnectionNotEstablishedError()
