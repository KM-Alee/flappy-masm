; main.asm - Entry point, main loop, and all shared data definitions
;
; This file owns every global variable. Other modules reference them
; through externdef declarations in include/game.inc.

option casemap:none
.x64

include include/config.inc
include include/game.inc

public main

; ---------------------------------------------------------------------------
; All shared data lives here so there is exactly one owner
; ---------------------------------------------------------------------------
.data

; ANSI escape sequences for terminal control
init_sequence       db ANSI_ESC, "[?1049h"      ; alternate screen on
                    db ANSI_ESC, "[?25l"         ; hide cursor
                    db ANSI_ESC, "[2J"           ; clear screen
                    db ANSI_ESC, "[H", 0         ; home cursor

restore_sequence    db ANSI_ESC, "[0m"           ; reset style
                    db ANSI_ESC, "[?25h"         ; show cursor
                    db ANSI_ESC, "[?1049l", 0    ; alternate screen off

reset_style_sequence db ANSI_ESC, "[0m", 0
home_sequence       db ANSI_ESC, "[H", 0
fg_prefix           db ANSI_ESC, "[38;5;", 0
bg_prefix           db ";48;5;", 0
color_suffix        db "m", 0

; UI string literals
tty_error_message   db "flappy-term needs a real ANSI terminal on stdin/stdout.", 0
highscore_path      db ".flappy_highscore.bin", 0
debug_env_name      db "FLAPPY_DEBUG", 0
ifdef TARGET_WINDOWS
swoosh_sound_command db "start /min powershell -NoLogo -NoProfile -WindowStyle Hidden -Command [void](New-Object System.Media.SoundPlayer('assets\\swoosh.wav')).PlaySync() >NUL 2>&1", 0
point_sound_command db "start /min powershell -NoLogo -NoProfile -WindowStyle Hidden -Command [void](New-Object System.Media.SoundPlayer('assets\\point.wav')).PlaySync() >NUL 2>&1", 0
hit_sound_command   db "start /min powershell -NoLogo -NoProfile -WindowStyle Hidden -Command [void](New-Object System.Media.SoundPlayer('assets\\hit.wav')).PlaySync() >NUL 2>&1", 0
die_sound_command   db "start /min powershell -NoLogo -NoProfile -WindowStyle Hidden -Command [void](New-Object System.Media.SoundPlayer('assets\\die.wav')).PlaySync() >NUL 2>&1", 0
else
swoosh_sound_command db "(for f in assets/swoosh.wav ../assets/swoosh.wav; do [ -f $f ] || continue; if command -v pw-play >/dev/null 2>&1; then pw-play $f; break; elif command -v paplay >/dev/null 2>&1; then paplay $f; break; elif command -v aplay >/dev/null 2>&1; then aplay -q $f; break; elif command -v ffplay >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet $f; break; fi; done) >/dev/null 2>&1 &", 0
point_sound_command db "(for f in assets/point.wav ../assets/point.wav; do [ -f $f ] || continue; if command -v pw-play >/dev/null 2>&1; then pw-play $f; break; elif command -v paplay >/dev/null 2>&1; then paplay $f; break; elif command -v aplay >/dev/null 2>&1; then aplay -q $f; break; elif command -v ffplay >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet $f; break; fi; done) >/dev/null 2>&1 &", 0
hit_sound_command   db "(for f in assets/hit.wav ../assets/hit.wav; do [ -f $f ] || continue; if command -v pw-play >/dev/null 2>&1; then pw-play $f; break; elif command -v paplay >/dev/null 2>&1; then paplay $f; break; elif command -v aplay >/dev/null 2>&1; then aplay -q $f; break; elif command -v ffplay >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet $f; break; fi; done) >/dev/null 2>&1 &", 0
die_sound_command   db "(for f in assets/die.wav ../assets/die.wav; do [ -f $f ] || continue; if command -v pw-play >/dev/null 2>&1; then pw-play $f; break; elif command -v paplay >/dev/null 2>&1; then paplay $f; break; elif command -v aplay >/dev/null 2>&1; then aplay -q $f; break; elif command -v ffplay >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet $f; break; fi; done) >/dev/null 2>&1 &", 0
endif

title_line_1        db "FLAPPY TERM", 0
title_line_2        db "space / w / up  flap", 0
title_line_3        db "p pause   r restart   q quit", 0
title_line_4        db "press space to launch", 0

pause_line          db "paused", 0
game_over_line      db "GAME OVER", 0
restart_line        db "space or r to try again", 0
score_label_s       db "SCORE: ", 0
best_label_s        db "BEST:  ", 0
warning_line_1      db "terminal too small", 0
warning_line_2      db "resize to at least 80 x 24", 0
debug_prefix_1      db "size ", 0
debug_prefix_2      db "score ", 0
debug_prefix_3      db "best ", 0
debug_prefix_4      db "state ", 0

; Sky palette (ANSI 256-color indices) - flat light blue throughout
sky_palette         db 75, 75, 75, 75, 75, 75, 75, 75

; OS / terminal buffers
saved_termios       db KTERM_SIZE dup (0)
raw_termios         db KTERM_SIZE dup (0)
winsize_buffer      db WINSIZE_SIZE dup (0)
pollfd_buffer       db POLLFD_SIZE dup (0)
clock_buffer        db TIMESPEC_SIZE dup (0)
sleep_buffer        db TIMESPEC_SIZE dup (0)
input_buffer        db INPUT_BUF_SIZE dup (0)
console_info_buffer db 32 dup (0)

; Number formatting scratch buffers
number_reverse      db 16 dup (0)
number_buffer       db 16 dup (0)
debug_buffer        db 96 dup (0)

; Rendering buffers
cell_buffer         db MAX_CELLS * CELL_SIZE dup (0)
out_buffer          db OUTBUF_SIZE dup (0)

; Scalar game state
terminal_active     dd 0
debug_enabled       dd 0
small_terminal      dd 0
exit_requested      dd 0
resize_requested    dd 0
game_state          dd STATE_TITLE

term_cols           dd 100
term_rows           dd 30

bird_y              dd 0
bird_velocity       dd 0
score_value         dd 0
best_score          dd 0
frame_counter       dd 0

pipe_gap_height     dd 8
pipe_spacing        dd 29
bird_column         dd 24
ground_top_row      dd 0

; Pipe arrays (one entry per pipe)
pipes_x             dd PIPE_COUNT dup (0)
pipes_gap_y         dd PIPE_COUNT dup (0)
pipes_scored        dd PIPE_COUNT dup (0)

; 64-bit state
rng_state           dq 1
last_frame_ns       dq 0
accumulator_ns      dq 0
qpc_frequency       dq 0

; ---------------------------------------------------------------------------
; Code
; ---------------------------------------------------------------------------
.code

; main - program entry point
;   Sets up the terminal, runs the game loop, then cleans up.
main proc
    push rbp
    mov rbp, rsp

    call DetectDebugMode
    call SeedRng
    call LoadBestScore
    call SetupTerminal
    test eax, eax
    jz terminal_ready

    ; Terminal setup failed - print error and exit
    lea rdi, tty_error_message
    call puts
    mov eax, 1
    leave
    ret

terminal_ready:
    call InstallProcessHooks
    call UpdateTerminalGeometry
    call ResetRun
    call ClockNowNs
    mov QWORD PTR [last_frame_ns], rax

main_loop:
ifdef TARGET_WINDOWS
    call UpdateTerminalGeometry
else
    ; Handle terminal resize if flagged
    cmp DWORD PTR [resize_requested], 0
    je skip_resize
    call UpdateTerminalGeometry
skip_resize:
endif

    call PollInput
    cmp DWORD PTR [exit_requested], 0
    jne main_exit

    ; Compute elapsed time since last frame
    call ClockNowNs
    mov rdx, rax
    mov rax, QWORD PTR [last_frame_ns]
    xchg rax, rdx
    sub rdx, rax
    js clamp_delta                  ; negative delta (clock jump) -> clamp
    cmp rdx, MAX_FRAME_NS
    jle delta_ok
clamp_delta:
    mov rdx, FRAME_NS              ; fall back to one ideal tick
delta_ok:
    mov QWORD PTR [last_frame_ns], rax
    add QWORD PTR [accumulator_ns], rdx

    ; Run up to 5 fixed-timestep updates per frame
    xor ecx, ecx
update_loop:
    mov rax, QWORD PTR [accumulator_ns]
    cmp rax, FRAME_NS
    jl updates_done
    cmp ecx, 5
    jge updates_done
    sub rax, FRAME_NS
    mov QWORD PTR [accumulator_ns], rax
    call UpdateGame
    inc ecx
    jmp update_loop

updates_done:
    call RenderFrame
    cmp DWORD PTR [exit_requested], 0
    jne main_exit
    call SleepUntilNextTick
    inc DWORD PTR [frame_counter]
    jmp main_loop

main_exit:
    call RestoreTerminal
    xor eax, eax
    leave
    ret
main endp

end
