option casemap:none

STDIN_FD            equ 0
STDOUT_FD           equ 1
STDERR_FD           equ 2

CLOCK_MONOTONIC     equ 1

TCGETS              equ 05401h
TCSETS              equ 05402h
TIOCGWINSZ          equ 05413h

POLLIN              equ 0001h

ICANON              equ 00000002h
ECHO_FLAG           equ 00000008h
IEXTEN              equ 00008000h
IXON                equ 00000400h
ICRNL               equ 00000100h
OPOST               equ 00000001h

VTIME_INDEX         equ 5
VMIN_INDEX          equ 6

SIGINT_NUM          equ 2
SIGQUIT_NUM         equ 3
SIGHUP_NUM          equ 1
SIGTERM_NUM         equ 15
SIGWINCH_NUM        equ 28

externdef write:proc
externdef read:proc
externdef poll:proc
externdef ioctl:proc
externdef nanosleep:proc
externdef clock_gettime:proc
externdef signal:proc
externdef atexit:proc
externdef open:proc
externdef close:proc
externdef getenv:proc
externdef isatty:proc
externdef puts:proc
externdef system:proc
