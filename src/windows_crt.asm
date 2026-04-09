option casemap:none
.x64

include include/config.inc
include include/game.inc

public write
public read
public open
public close

.code

write proc
    sub rsp, 40
    mov ecx, edi
    mov r9d, edx
    mov rdx, rsi
    mov r8d, r9d
    call _write
    add rsp, 40
    ret
write endp

read proc
    sub rsp, 40
    mov ecx, edi
    mov r9d, edx
    mov rdx, rsi
    mov r8d, r9d
    call _read
    add rsp, 40
    ret
read endp

open proc
    sub rsp, 40
    mov r10d, esi
    xor r11d, r11d
    test r10d, O_WRONLY
    jz open_mode_ready
    or r11d, O_WRONLY
open_mode_ready:
    test r10d, O_CREAT
    jz open_no_create
    or r11d, MSVCRT_O_CREAT
open_no_create:
    test r10d, O_TRUNC
    jz open_no_trunc
    or r11d, MSVCRT_O_TRUNC
open_no_trunc:
    or r11d, MSVCRT_O_BINARY
    mov rcx, rdi
    mov edx, r11d
    mov r8d, edx
    mov r8d, MODE_0644
    call _open
    add rsp, 40
    ret
open endp

close proc
    sub rsp, 40
    mov ecx, edi
    call _close
    add rsp, 40
    ret
close endp

end