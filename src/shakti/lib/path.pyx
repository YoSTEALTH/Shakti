#

def join(object path not None, *other):
    ''' Join Multiple Paths

        Type
            path:   str | bytes
            *other: tuple[str | bytes]
            return: str | bytes

        Example
            >>> join('/one', 'two', 'three')
            '/one/two/three'

            >>> join(b'/one', b'two', b'three')
            b'/one/two/three'

            >>> join('/one', 'two', '/three', 'four')
            '/three/four'
    '''
    # note: benchmark tested.
    cdef unsigned int i, length = len(other)

    if not length:
        return path

    cdef bint byte = type(path) is bytes

    for i in range(length):
        if byte:
            path = join_bytes(path, other[i])
        else:
            path = join_string(path, other[i])
    return path


cpdef inline str join_string(str path, str other):
    ''' Join Two String Paths

        Example
            >>> join_string('/one', 'two')
            '/one/two'

            >>> join_string('/one', '/two')
            '/two'
    '''
    cdef unsigned int length = len(other)

    if not length:
        return path

    if other[0] is '/':
        return other

    if other[length-1] is '/':
        return path + other

    return path + '/' + other


cpdef inline bytes join_bytes(bytes path, bytes other):
    ''' Join Two Bytes Paths

        Example
            >>> join_bytes(b'/one', b'two')
            b'/one/two'

            >>> join_bytes(b'/one', b'/two')
            b'/two'
    '''
    cdef unsigned int length = len(other)

    if not length:
        return path

    if other[0] is 47:  # b'/'
        return other

    if other[length-1] is 47:
        return path + other

    return path + b'/' + other


cpdef inline bint isabs(object path, bint error=True) except -1:
    ''' Absolute path

        Type
            path:   str | bytes
            return: bool

        Example
            >>> isabs('/dev/shm')
            >>> isabs(b'/dev/shm')
            True

            >>> isabs('dev/shm')
            >>> isabs(b'dev/shm')
            False
    '''
    cdef unicode msg
    if not path:
        if error:
            msg = '`isabs()` - received empty `path`'
            raise ValueError(msg)
        return False

    cdef type t = type(path)

    if t is str:
        return isabs_string(path)
    elif t is bytes:
        return isabs_bytes(path)
    elif error:
        msg = '`isabs()` - takes type `str` or `bytes`'
        raise TypeError(msg)
    else:
        return False


cdef inline bint isabs_string(str path) noexcept:
    # note: assumes `path` is always true since this is cdef
    return path[0] is '/'


cdef inline bint isabs_bytes(bytes path) noexcept:
    # note: assumes `path` is always true since this is cdef
    return path[0] is 47
