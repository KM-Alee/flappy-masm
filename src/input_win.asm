; input_win.asm - Windows input via msvcrt _kbhit/_getch

option casemap:none
.x64

include include/config.inc
include include/game.inc

public PollInput

.code

PollInput proc uses rbx
poll_again:
    sub rsp, 40
    call _kbhit
    add rsp, 40
    test eax, eax
    jz input_done

    sub rsp, 40
    call _getch
    add rsp, 40
    mov ebx, eax

    cmp bl, 0
    je read_extended
    cmp bl, 224
    je read_extended
    jmp dispatch_key

read_extended:
    sub rsp, 40
    call _getch
    add rsp, 40
    mov ebx, eax
    cmp bl, 72                      ; Up arrow
    jne poll_again
    call HandleFlapKey
    jmp poll_again

dispatch_key:
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
    jmp poll_again

flap_key:
    call HandleFlapKey
    jmp poll_again

quit_key:
    mov DWORD PTR [exit_requested], 1
    jmp input_done

pause_key:
    call HandlePauseKey
    jmp poll_again

restart_key:
    call HandleRestartKey
    jmp poll_again

input_done:
    ret
PollInput endp

end