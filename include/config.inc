option casemap:none

MAX_COLS            equ 160
MAX_ROWS            equ 60
CELL_SIZE           equ 4
MAX_CELLS           equ MAX_COLS * MAX_ROWS
OUTBUF_SIZE         equ 2097152
INPUT_BUF_SIZE      equ 32

MIN_COLS            equ 80
MIN_ROWS            equ 24

STATE_TITLE         equ 0
STATE_RUNNING       equ 1
STATE_PAUSED        equ 2
STATE_DEAD          equ 3

GROUND_ROWS         equ 3
PIPE_COUNT          equ 4
PIPE_WIDTH          equ 8

BIRD_SPRITE_OFFSET_X equ 2
BIRD_SPRITE_OFFSET_Y equ 1

FRAME_NS            equ 16666667
MAX_FRAME_NS        equ 250000000

; Physics tuning (8.8 fixed-point values)
; Lower gravity + gentler flap = smooth parabolic arcs like original Flappy Bird
GRAVITY_FP          equ 12
FLAP_VEL_FP         equ -137
MAX_FALL_FP         equ 140
PIPE_SPEED_FP       equ 48

SKY_COLOR_COUNT     equ 8

CELL_GLYPH          equ 0
CELL_FG             equ 1
CELL_BG             equ 2

KTERM_SIZE          equ 36
KTERM_IFLAG         equ 0
KTERM_OFLAG         equ 4
KTERM_CFLAG         equ 8
KTERM_LFLAG         equ 12
KTERM_LINE          equ 16
KTERM_CC            equ 17

WINSIZE_SIZE        equ 8
WINSIZE_ROWS        equ 0
WINSIZE_COLS        equ 2

POLLFD_SIZE         equ 8
POLLFD_FD           equ 0
POLLFD_EVENTS       equ 4
POLLFD_REVENTS      equ 6

TIMESPEC_SEC        equ 0
TIMESPEC_NSEC       equ 8
TIMESPEC_SIZE       equ 16

O_RDONLY            equ 0
O_WRONLY            equ 1
O_CREAT             equ 64
O_TRUNC             equ 512
MODE_0644           equ 420

ANSI_ESC            equ 27
