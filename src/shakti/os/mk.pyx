#

from libc.errno cimport EEXIST
from liburing.lib.type cimport __AT_FDCWD, mode_t
from liburing.os cimport io_uring_prep_mkdirat
from ..lib.error cimport DirExistsError
from ..lib.path cimport join_bytes, join_string
from ..event.entry cimport SQE
from random import choice
from math import perm


# TODO: makedirs


TEMPDIR = '/tmp'
# note: The "/tmp" directory must be made available for programs that require temporary files.
#       https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s18.html
ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'


async def mkdir(str path not None, mode_t mode=0o777, *, int dir_fd=__AT_FDCWD):
    '''
        Example
            >>> await mkdir('create-directory')
    '''
    cdef:
        SQE sqe = SQE()
        bytes _path = path.encode()
    io_uring_prep_mkdirat(sqe, _path, mode, dir_fd)
    await sqe


async def mktdir(str prefix not None='',
                 str suffix not None='',
                 unsigned int length=16,
                 str tempdir not None=TEMPDIR,
                 mode_t mode=0o777,
                 int dir_fd=__AT_FDCWD)-> str:
    ''' Make Temporary Directory

        Example
            >>> await mktdir()
            /tmp/gPBRwtGLhnoY5wSd

            # custom
            >>> await mktdir('start-','-end', 4)
            '/tmp/start-3mf8-end'

        Note
            - A random named directory is created in `/tmp/abc123...`
            - Directory will need to be moved or deleted manually.
    '''
    if not length:
        return ''

    cdef:
        SQE             sqe = SQE()  # reuse same `sqe` memory
        str             name
        bytes           path
        unicode         msg
        unsigned int    retry = len(ALPHABET)

    for _ in range(perm(retry, length)):
        name = prefix + ''.join(choice(ALPHABET) for _ in range(length)) + suffix
        path = join_string(tempdir, name).encode()
        io_uring_prep_mkdirat(sqe, path, mode, dir_fd)
        try:
            await sqe
        except FileExistsError:
            continue
        else:
            return path.decode()
    msg = 'mktdir() - No usable temporary directory name found'
    raise DirExistsError(EEXIST, msg)
