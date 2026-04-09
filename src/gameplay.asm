; gameplay.asm - Shared state transitions and layout recomputation
;
; This module keeps small pieces of gameplay control flow in one place so
; platform-specific files only gather input and terminal information.

option casemap:none
.x64

include include/config.inc
include include/game.inc

public HandleFlapKey
public HandlePauseKey
public HandleRestartKey
public RecomputeLayout

.code

; HandleFlapKey - Process a flap/action keypress.
;   TITLE   -> start the run
;   DEAD    -> reset and restart
;   RUNNING -> apply flap velocity
HandleFlapKey proc
    cmp DWORD PTR [small_terminal], 0
    jne flap_done
    cmp DWORD PTR [game_state], STATE_TITLE
    je flap_start
    cmp DWORD PTR [game_state], STATE_DEAD
    je flap_restart
    cmp DWORD PTR [game_state], STATE_PAUSED
    je flap_done
    mov DWORD PTR [bird_velocity], FLAP_VEL_FP
    call PlaySwooshSound
    jmp flap_done

flap_start:
    call StartRun
    call PlaySwooshSound
    jmp flap_done

flap_restart:
    call ResetRun
    call StartRun
    call PlaySwooshSound

flap_done:
    ret
HandleFlapKey endp

; HandlePauseKey - Toggle between RUNNING and PAUSED.
HandlePauseKey proc
    cmp DWORD PTR [game_state], STATE_RUNNING
    jne pause_maybe_resume
    mov DWORD PTR [game_state], STATE_PAUSED
    ret

pause_maybe_resume:
    cmp DWORD PTR [game_state], STATE_PAUSED
    jne pause_done
    mov DWORD PTR [game_state], STATE_RUNNING

pause_done:
    ret
HandlePauseKey endp

; HandleRestartKey - Restart only after a crash.
HandleRestartKey proc
    cmp DWORD PTR [game_state], STATE_DEAD
    jne restart_done
    call ResetRun
    call StartRun

restart_done:
    ret
HandleRestartKey endp

; RecomputeLayout - Derive gameplay layout from the current terminal size.
;   Terminal backends only set term_cols/term_rows, then call this helper.
RecomputeLayout proc
    mov DWORD PTR [resize_requested], 0
    mov DWORD PTR [small_terminal], 0

    cmp DWORD PTR [term_cols], MIN_COLS
    jl mark_small
    cmp DWORD PTR [term_rows], MIN_ROWS
    jl mark_small
    jmp layout_compute

mark_small:
    mov DWORD PTR [small_terminal], 1

layout_compute:
    ; Bird column = cols / 5, clamped into a readable range.
    mov eax, DWORD PTR [term_cols]
    xor edx, edx
    mov ecx, 5
    div ecx
    cmp eax, 12
    jge bird_col_min_ok
    mov eax, 12
bird_col_min_ok:
    cmp eax, 30
    jle bird_col_ok
    mov eax, 30
bird_col_ok:
    mov DWORD PTR [bird_column], eax

    ; Ground always consumes the last fixed rows.
    mov eax, DWORD PTR [term_rows]
    sub eax, GROUND_ROWS
    mov DWORD PTR [ground_top_row], eax

    ; Pipe gap height scales with available vertical space.
    mov eax, DWORD PTR [term_rows]
    cmp eax, 40
    jge gap_large
    cmp eax, 30
    jge gap_medium
    mov eax, 6
    jmp gap_ok
gap_large:
    mov eax, 8
    jmp gap_ok
gap_medium:
    mov eax, 7
gap_ok:
    mov DWORD PTR [pipe_gap_height], eax

    ; Pipe spacing scales with width but stays inside a tested range.
    mov eax, DWORD PTR [term_cols]
    shr eax, 2
    cmp eax, 18
    jge spacing_min_ok
    mov eax, 18
spacing_min_ok:
    cmp eax, 35
    jle spacing_ok
    mov eax, 35
spacing_ok:
    mov DWORD PTR [pipe_spacing], eax
    ret
RecomputeLayout endp

end