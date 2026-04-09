; input.asm - Input polling and key dispatch
;
; Reads from stdin without blocking and dispatches keys to the
; appropriate game actions (flap, pause, restart, quit).

option casemap:none
.x64

include include/config.inc
include include/game.inc

public PollInput

.code

; PollInput - Read all pending input bytes and dispatch each one
;   Uses poll() with zero timeout for non-blocking behavior.
PollInput proc uses rbx r12 r13 r14
    mov DWORD PTR [pollfd_buffer + POLLFD_FD], STDIN_FD
    mov WORD PTR [pollfd_buffer + POLLFD_EVENTS], POLLIN
    mov WORD PTR [pollfd_buffer + POLLFD_REVENTS], 0

poll_again:
    lea rdi, pollfd_buffer
    mov esi, 1
    xor edx, edx                    ; timeout = 0 (non-blocking)
    call poll
    cmp eax, 1
    jl input_done

    mov edi, STDIN_FD
    lea rsi, input_buffer
    mov edx, INPUT_BUF_SIZE
    call read
    cmp eax, 1
    jl input_done

    mov r12d, eax                   ; r12 = bytes read
    xor r13d, r13d                  ; r13 = current index

parse_loop:
    cmp r13d, r12d
    jge poll_again
    movzx ebx, BYTE PTR [input_buffer + r13]

    ; Check for escape sequence (arrow keys)
    cmp bl, 27
    jne not_escape
    mov r14d, r13d
    add r14d, 2
    cmp r14d, r12d
    jge handle_escape_quit
    cmp BYTE PTR [input_buffer + r13 + 1], '['
    jne handle_escape_quit
    cmp BYTE PTR [input_buffer + r13 + 2], 'A'  ; Up arrow
    jne handle_escape_quit
    add r13d, 2                     ; consume the CSI sequence
    call HandleFlapKey
    jmp next_input

handle_escape_quit:
    mov DWORD PTR [exit_requested], 1
    jmp input_done

not_escape:
    cmp bl, ' '
    je flap_key
    cmp bl, 'w'
    je flap_key
    cmp bl, 'W'
    je flap_key
    cmp bl, 'q'
    je quit_key
    cmp bl, 'Q'
    je quit_key
    cmp bl, 'p'
    je pause_key
    cmp bl, 'P'
    je pause_key
    cmp bl, 'r'
    je restart_key
    cmp bl, 'R'
    je restart_key
    jmp next_input

flap_key:
    call HandleFlapKey
    jmp next_input

quit_key:
    mov DWORD PTR [exit_requested], 1
    jmp input_done

pause_key:
    call HandlePauseKey
    jmp next_input

restart_key:
    call HandleRestartKey

next_input:
    inc r13d
    jmp parse_loop

input_done:
    ret
PollInput endp

end
