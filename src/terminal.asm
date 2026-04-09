; terminal.asm - Terminal setup, restore, signal handling, and geometry
;
; Manages raw mode, alternate screen, signal handlers, and tracking
; the terminal dimensions for responsive layout.

option casemap:none
.x64

include include/config.inc
include include/game.inc

public SetupTerminal
public RestoreTerminal
public InstallProcessHooks
public UpdateTerminalGeometry

.code

; SetupTerminal - Enter raw mode and alternate screen
;   Returns 0 on success, 1 on failure.
SetupTerminal proc uses rbx
    ; Verify both stdin and stdout are real TTYs
    mov edi, STDIN_FD
    call isatty
    test eax, eax
    jz setup_fail
    mov edi, STDOUT_FD
    call isatty
    test eax, eax
    jz setup_fail

    ; Save the original terminal settings
    mov edi, STDIN_FD
    mov esi, TCGETS
    lea rdx, saved_termios
    call ioctl
    test eax, eax
    jne setup_fail

    ; Copy saved settings into the raw-mode buffer
    lea rsi, saved_termios
    lea rdi, raw_termios
    mov ecx, KTERM_SIZE
    rep movsb

    ; Disable canonical mode, echo, and extended input processing
    mov eax, DWORD PTR [raw_termios + KTERM_LFLAG]
    and eax, not (ICANON or ECHO_FLAG or IEXTEN)
    mov DWORD PTR [raw_termios + KTERM_LFLAG], eax

    ; Disable flow control and carriage-return translation
    mov eax, DWORD PTR [raw_termios + KTERM_IFLAG]
    and eax, not (IXON or ICRNL)
    mov DWORD PTR [raw_termios + KTERM_IFLAG], eax

    ; Disable output post-processing
    mov eax, DWORD PTR [raw_termios + KTERM_OFLAG]
    and eax, not OPOST
    mov DWORD PTR [raw_termios + KTERM_OFLAG], eax

    ; Non-blocking read: VMIN=0, VTIME=0
    mov BYTE PTR [raw_termios + KTERM_CC + VMIN_INDEX], 0
    mov BYTE PTR [raw_termios + KTERM_CC + VTIME_INDEX], 0

    ; Apply raw settings
    mov edi, STDIN_FD
    mov esi, TCSETS
    lea rdx, raw_termios
    call ioctl
    test eax, eax
    jne setup_fail

    ; Register cleanup so terminal is restored even on unexpected exit
    lea rdi, RestoreTerminal
    call atexit

    ; Switch to alternate screen, hide cursor, clear
    lea rdi, init_sequence
    call WriteString
    mov DWORD PTR [terminal_active], 1
    xor eax, eax
    ret

setup_fail:
    mov eax, 1
    ret
SetupTerminal endp

; RestoreTerminal - Restore original terminal state
;   Safe to call multiple times (idempotent).
RestoreTerminal proc
    cmp DWORD PTR [terminal_active], 0
    je restore_done
    lea rdi, restore_sequence
    call WriteString
    mov edi, STDIN_FD
    mov esi, TCSETS
    lea rdx, saved_termios
    call ioctl
    mov DWORD PTR [terminal_active], 0
restore_done:
    ret
RestoreTerminal endp

; InstallProcessHooks - Register signal handlers for clean shutdown
InstallProcessHooks proc
    mov edi, SIGINT_NUM
    lea rsi, SignalHandler
    call signal
    mov edi, SIGTERM_NUM
    lea rsi, SignalHandler
    call signal
    mov edi, SIGQUIT_NUM
    lea rsi, SignalHandler
    call signal
    mov edi, SIGHUP_NUM
    lea rsi, SignalHandler
    call signal
    mov edi, SIGWINCH_NUM
    lea rsi, SignalHandler
    call signal
    ret
InstallProcessHooks endp

; SignalHandler - Shared handler for all caught signals
;   SIGWINCH triggers a geometry refresh; everything else triggers exit.
SignalHandler proc
    cmp edi, SIGWINCH_NUM
    jne mark_exit
    mov DWORD PTR [resize_requested], 1
    ret
mark_exit:
    mov DWORD PTR [exit_requested], 1
    ret
SignalHandler endp

; UpdateTerminalGeometry - Query terminal size and recompute layout values
;   Called on startup and after every SIGWINCH.
UpdateTerminalGeometry proc uses rbx
    mov edi, STDOUT_FD
    mov esi, TIOCGWINSZ
    lea rdx, winsize_buffer
    call ioctl
    test eax, eax
    jne geometry_done

    ; Read columns, clamp to [1, MAX_COLS]
    movzx eax, WORD PTR [winsize_buffer + WINSIZE_COLS]
    cmp eax, 0
    jne cols_ok
    mov eax, 100
cols_ok:
    cmp eax, MAX_COLS
    jle cols_fit
    mov eax, MAX_COLS
cols_fit:
    mov DWORD PTR [term_cols], eax

    ; Read rows, clamp to [1, MAX_ROWS]
    movzx eax, WORD PTR [winsize_buffer + WINSIZE_ROWS]
    cmp eax, 0
    jne rows_ok
    mov eax, 30
rows_ok:
    cmp eax, MAX_ROWS
    jle rows_fit
    mov eax, MAX_ROWS
rows_fit:
    mov DWORD PTR [term_rows], eax
    call RecomputeLayout

geometry_done:
    ret
UpdateTerminalGeometry endp

end
