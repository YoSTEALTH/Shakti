from pytest import raises
from shakti import isabs, join


def test_isabs():
    # copied from cpython `Lib/test/test_posixpath.py`
    with raises(ValueError):
        assert isabs(None) is False
    with raises(ValueError):
        assert isabs('') is False
    assert isabs('/') is True
    assert isabs('/foo') is True
    assert isabs('/foo/bar') is True
    assert isabs('foo/bar') is False

    with raises(ValueError):
        assert isabs(b'') is False
    assert isabs(b'/') is True
    assert isabs(b'/foo') is True
    assert isabs(b'/foo/bar') is True
    assert isabs(b'foo/bar') is False

    with raises(TypeError):
        assert isabs(['bad type']) is False


def test_join():
    assert join('/foo', '', '') == '/foo'
    assert join(b'/foo', b'', b'') == b'/foo'

    # copied from cpython `Lib/test/test_posixpath.py`
    assert join('/foo', 'bar', '/bar', 'baz') == '/bar/baz'
    assert join('/foo', 'bar', 'baz') == '/foo/bar/baz'
    assert join('/foo/', 'bar/', 'baz/') == '/foo/bar/baz/'
    
    assert join(b'/foo', b'bar', b'/bar', b'baz') == b'/bar/baz'
    assert join(b'/foo', b'bar', b'baz') == b'/foo/bar/baz'
    assert join(b'/foo/', b'bar/', b'baz/') == b'/foo/bar/baz/'
    
