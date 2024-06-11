async def socket(int family=__AF_INET, int type=__SOCK_STREAM, int protocol=0, unsigned int flags=0,
                 *, bint direct=False)-> int:
    ''' Create Socket

        Example
            >>> sock_fd = await socket(AF_INET, SOCK_STREAM)

        Note
            - Setting `direct=True` will return direct descriptor index.
    '''
    cdef SQE sqe = SQE(error=False)
    if direct:
        io_uring_prep_socket_direct_alloc(sqe, family, type, protocol, flags)
    else:
        io_uring_prep_socket(sqe, family, type, protocol, flags)
    await sqe
    if sqe.result > -1:
        return sqe.result  # `fd` or `index`
    else:
        if direct and sqe.result == -ENFILE:
            raise_error(sqe.result, 'Either file table is full or register file not enabled!')
        raise_error(sqe.result)

