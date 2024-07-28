#

cpdef str join_string(str path, str other)
cpdef bytes join_bytes(bytes path, bytes other)
cpdef bint isabs(object path, bint error=?) except -1
cdef bint isabs_string(str path) noexcept
cdef bint isabs_bytes(bytes path) noexcept
