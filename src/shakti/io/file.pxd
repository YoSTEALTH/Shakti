from liburing.lib.type cimport __s32, __u32, __u64
from liburing.lib.file cimport *
from liburing.common cimport AT_FDCWD, io_uring_prep_close, io_uring_prep_close_direct
from liburing.statx cimport STATX_SIZE, statx, io_uring_prep_statx
from liburing.file cimport open_how, io_uring_prep_openat, io_uring_prep_openat2, \
                           io_uring_prep_read, io_uring_prep_write
from ..event.entry cimport SQE
from ..lib.error cimport UnsupportedOperation
from .common cimport IOBase


cdef class File(IOBase):
    cdef:
        str             _encoding
        int             _dir_fd, _seek
        bint            _bytes, _append, _creating, _direct
        __u64           _resolve, _flags, _mode
        readonly bytes  path


cpdef enum __file_define__:
    # note: copied from `liburing.file.pxd`
    RESOLVE_NO_XDEV = __RESOLVE_NO_XDEV
    RESOLVE_NO_MAGICLINKS = __RESOLVE_NO_MAGICLINKS
    RESOLVE_NO_SYMLINKS = __RESOLVE_NO_SYMLINKS
    RESOLVE_BENEATH = __RESOLVE_BENEATH
    RESOLVE_IN_ROOT = __RESOLVE_IN_ROOT
    RESOLVE_CACHED = __RESOLVE_CACHED

    SYNC_FILE_RANGE_WAIT_BEFORE = __SYNC_FILE_RANGE_WAIT_BEFORE
    SYNC_FILE_RANGE_WRITE = __SYNC_FILE_RANGE_WRITE
    SYNC_FILE_RANGE_WAIT_AFTER = __SYNC_FILE_RANGE_WAIT_AFTER

    O_ACCMODE = __O_ACCMODE
    O_RDONLY = __O_RDONLY
    O_WRONLY = __O_WRONLY
    O_RDWR = __O_RDWR

    O_APPEND = __O_APPEND
    O_ASYNC = __O_ASYNC
    O_CLOEXEC = __O_CLOEXEC
    O_CREAT = __O_CREAT

    O_DIRECT = __O_DIRECT
    O_DIRECTORY = __O_DIRECTORY
    O_DSYNC = __O_DSYNC
    O_EXCL = __O_EXCL
    O_LARGEFILE = __O_LARGEFILE
    O_NOATIME = __O_NOATIME
    O_NOCTTY = __O_NOCTTY
    O_NOFOLLOW = __O_NOFOLLOW
    O_NONBLOCK = __O_NONBLOCK
    O_PATH = __O_PATH

    O_SYNC = __O_SYNC
    O_TMPFILE = __O_TMPFILE
    O_TRUNC = __O_TRUNC
