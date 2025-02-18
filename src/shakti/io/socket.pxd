from libc.errno cimport ENFILE
from cpython.array cimport array
from liburing.lib.socket cimport *
from liburing.lib.type cimport bool as bool_t
from liburing.socket cimport sockaddr, io_uring_prep_socket, io_uring_prep_socket_direct_alloc, \
                             io_uring_prep_shutdown, io_uring_prep_send, io_uring_prep_recv, \
                             io_uring_prep_accept, io_uring_prep_connect, \
                             io_uring_prep_setsockopt, io_uring_prep_getsockopt
from liburing.socket_extra cimport io_uring_prep_bind, io_uring_prep_listen, getsockname as _getsockname, \
                                   getpeername as _getpeername, getaddrinfo as _getaddrinfo, isIP
from liburing.time cimport timespec, io_uring_prep_link_timeout
from liburing.error cimport raise_error
from ..event.entry cimport SQE


# defines
cpdef enum SocketFamily:
    AF_UNIX = __AF_UNIX
    AF_INET = __AF_INET
    AF_INET6 = __AF_INET6

cpdef enum SocketType:
    SOCK_STREAM = __SOCK_STREAM
    SOCK_DGRAM = __SOCK_DGRAM
    SOCK_RAW = __SOCK_RAW
    SOCK_RDM = __SOCK_RDM
    SOCK_SEQPACKET = __SOCK_SEQPACKET
    SOCK_DCCP = __SOCK_DCCP
    SOCK_PACKET = __SOCK_PACKET
    SOCK_CLOEXEC = __SOCK_CLOEXEC
    SOCK_NONBLOCK = __SOCK_NONBLOCK

cpdef enum ShutdownHow:
    SHUT_RD = __SHUT_RD
    SHUT_WR = __SHUT_WR
    SHUT_RDWR = __SHUT_RDWR

cpdef enum SocketProto:
    IPPROTO_IP = __IPPROTO_IP
    IPPROTO_ICMP = __IPPROTO_ICMP
    IPPROTO_IGMP = __IPPROTO_IGMP
    IPPROTO_IPIP = __IPPROTO_IPIP
    IPPROTO_TCP = __IPPROTO_TCP
    IPPROTO_EGP = __IPPROTO_EGP
    IPPROTO_PUP = __IPPROTO_PUP
    IPPROTO_UDP = __IPPROTO_UDP
    IPPROTO_IDP = __IPPROTO_IDP
    IPPROTO_TP = __IPPROTO_TP
    IPPROTO_DCCP = __IPPROTO_DCCP
    IPPROTO_IPV6 = __IPPROTO_IPV6
    IPPROTO_RSVP = __IPPROTO_RSVP
    IPPROTO_GRE = __IPPROTO_GRE
    IPPROTO_ESP = __IPPROTO_ESP
    IPPROTO_AH = __IPPROTO_AH
    IPPROTO_MTP = __IPPROTO_MTP
    IPPROTO_BEETPH = __IPPROTO_BEETPH
    IPPROTO_ENCAP = __IPPROTO_ENCAP
    IPPROTO_PIM = __IPPROTO_PIM
    IPPROTO_COMP = __IPPROTO_COMP
    # note: not supported
    # IPPROTO_L2TP = __IPPROTO_L2TP
    IPPROTO_SCTP = __IPPROTO_SCTP
    IPPROTO_UDPLITE = __IPPROTO_UDPLITE
    IPPROTO_MPLS = __IPPROTO_MPLS
    IPPROTO_ETHERNET = __IPPROTO_ETHERNET
    IPPROTO_RAW = __IPPROTO_RAW
    IPPROTO_MPTCP = __IPPROTO_MPTCP

# setsockopt & getsockopt start >>>
cpdef enum __socket_define__:
    SOL_SOCKET = __SOL_SOCKET
    SO_DEBUG = __SO_DEBUG
    SO_REUSEADDR = __SO_REUSEADDR
    SO_TYPE = __SO_TYPE
    SO_ERROR = __SO_ERROR
    SO_DONTROUTE = __SO_DONTROUTE
    SO_BROADCAST = __SO_BROADCAST
    SO_SNDBUF = __SO_SNDBUF
    SO_RCVBUF = __SO_RCVBUF
    SO_SNDBUFFORCE = __SO_SNDBUFFORCE
    SO_RCVBUFFORCE = __SO_RCVBUFFORCE
    SO_KEEPALIVE = __SO_KEEPALIVE
    SO_OOBINLINE = __SO_OOBINLINE
    SO_NO_CHECK = __SO_NO_CHECK
    SO_PRIORITY = __SO_PRIORITY
    SO_LINGER = __SO_LINGER
    SO_BSDCOMPAT = __SO_BSDCOMPAT
    SO_REUSEPORT = __SO_REUSEPORT
    SO_PASSCRED = __SO_PASSCRED
    SO_PEERCRED = __SO_PEERCRED
    SO_RCVLOWAT = __SO_RCVLOWAT
    SO_SNDLOWAT = __SO_SNDLOWAT
    SO_BINDTODEVICE = __SO_BINDTODEVICE

    # Socket filtering
    SO_ATTACH_FILTER = __SO_ATTACH_FILTER
    SO_DETACH_FILTER = __SO_DETACH_FILTER
    SO_GET_FILTER = __SO_GET_FILTER
    SO_PEERNAME = __SO_PEERNAME
    SO_ACCEPTCONN = __SO_ACCEPTCONN
    SO_PEERSEC = __SO_PEERSEC
    SO_PASSSEC = __SO_PASSSEC
    SO_MARK = __SO_MARK
    SO_PROTOCOL = __SO_PROTOCOL
    SO_DOMAIN = __SO_DOMAIN
    SO_RXQ_OVFL = __SO_RXQ_OVFL
    SO_WIFI_STATUS = __SO_WIFI_STATUS
    SCM_WIFI_STATUS = __SCM_WIFI_STATUS
    SO_PEEK_OFF = __SO_PEEK_OFF

    # not tested
    SO_TIMESTAMP = __SO_TIMESTAMP
    SO_TIMESTAMPNS = __SO_TIMESTAMPNS
    SO_TIMESTAMPING = __SO_TIMESTAMPING
    SO_RCVTIMEO = __SO_RCVTIMEO
    SO_SNDTIMEO = __SO_SNDTIMEO
    # setsockopt & getsockopt end <<<
