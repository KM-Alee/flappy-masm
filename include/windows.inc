option casemap:none

STDIN_FD                        equ 0
STDOUT_FD                       equ 1
STDERR_FD                       equ 2

STD_INPUT_HANDLE                equ -10
STD_OUTPUT_HANDLE               equ -11

ENABLE_PROCESSED_INPUT          equ 0001h
ENABLE_LINE_INPUT               equ 0002h
ENABLE_ECHO_INPUT               equ 0004h
ENABLE_WINDOW_INPUT             equ 0008h
ENABLE_VIRTUAL_TERMINAL_INPUT   equ 0200h

ENABLE_PROCESSED_OUTPUT         equ 0001h
ENABLE_WRAP_AT_EOL_OUTPUT       equ 0002h
ENABLE_VIRTUAL_TERMINAL_PROCESSING equ 0004h

CTRL_C_EVENT                    equ 0
CTRL_BREAK_EVENT                equ 1
CTRL_CLOSE_EVENT                equ 2
CTRL_LOGOFF_EVENT               equ 5
CTRL_SHUTDOWN_EVENT             equ 6

WINSIZE_SIZE                    equ 8
WINSIZE_ROWS                    equ 0
WINSIZE_COLS                    equ 2

TIMESPEC_SEC                    equ 0
TIMESPEC_NSEC                   equ 8
TIMESPEC_SIZE                   equ 16

POLLFD_SIZE                     equ 8
POLLFD_FD                       equ 0
POLLFD_EVENTS                   equ 4
POLLFD_REVENTS                  equ 6

INPUT_BUF_SIZE                  equ 32

O_RDONLY                        equ 0
O_WRONLY                        equ 1
O_CREAT                         equ 64
O_TRUNC                         equ 512
MODE_0644                       equ 420

MSVCRT_O_CREAT                  equ 0100h
MSVCRT_O_TRUNC                  equ 0200h
MSVCRT_O_BINARY                 equ 8000h

QPC_SCALE                       equ 1000000000

ANSI_ESC                        equ 27

CSBI_LEFT                       equ 10
CSBI_TOP                        equ 12
CSBI_RIGHT                      equ 14
CSBI_BOTTOM                     equ 16

externdef _write:proc
externdef _read:proc
externdef _open:proc
externdef _close:proc
externdef getenv:proc
externdef puts:proc
externdef system:proc
externdef atexit:proc
externdef _kbhit:proc
externdef _getch:proc
externdef GetStdHandle:proc
externdef GetConsoleMode:proc
externdef SetConsoleMode:proc
externdef GetConsoleScreenBufferInfo:proc
externdef SetConsoleCtrlHandler:proc
externdef Sleep:proc
externdef QueryPerformanceCounter:proc
externdef QueryPerformanceFrequency:proc

externdef write:proc
externdef read:proc
externdef open:proc
externdef close:proc
