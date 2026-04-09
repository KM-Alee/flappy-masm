; terminal_win.asm - Windows console setup and geometry

option casemap:none
.x64

include include/config.inc
include include/game.inc

public SetupTerminal
public RestoreTerminal
public InstallProcessHooks
public UpdateTerminalGeometry

.code

SetupTerminal proc uses rbx r12
    sub rsp, 40
    mov ecx, STD_INPUT_HANDLE
    call GetStdHandle
    add rsp, 40
    mov rbx, rax
    cmp rax, -1
    je setup_fail

    sub rsp, 40
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    add rsp, 40
    mov r12, rax
    cmp rax, -1
    je setup_fail

    sub rsp, 40
    mov rcx, r12
    lea rdx, raw_termios
    call GetConsoleMode
    add rsp, 40
    test eax, eax
    jz setup_fail

    mov eax, DWORD PTR [raw_termios]
    mov DWORD PTR [saved_termios], eax
    or eax, ENABLE_VIRTUAL_TERMINAL_PROCESSING or ENABLE_PROCESSED_OUTPUT or ENABLE_WRAP_AT_EOL_OUTPUT
    mov DWORD PTR [raw_termios], eax

    sub rsp, 40
    mov rcx, r12
    mov edx, DWORD PTR [raw_termios]
    call SetConsoleMode
    add rsp, 40
    test eax, eax
    jz setup_fail

    lea rdi, init_sequence
    call WriteString
    mov DWORD PTR [terminal_active], 1
    xor eax, eax
    ret

setup_fail:
    mov eax, 1
    ret
SetupTerminal endp

RestoreTerminal proc uses rbx
    cmp DWORD PTR [terminal_active], 0
    je restore_done
    lea rdi, restore_sequence
    call WriteString
    sub rsp, 40
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    add rsp, 40
    mov rbx, rax
    cmp rax, -1
    je restore_mark_done
    sub rsp, 40
    mov rcx, rbx
    mov edx, DWORD PTR [saved_termios]
    call SetConsoleMode
    add rsp, 40
restore_mark_done:
    mov DWORD PTR [terminal_active], 0
restore_done:
    ret
RestoreTerminal endp

InstallProcessHooks proc
    sub rsp, 40
    lea rcx, ConsoleCtrlHandler
    mov edx, 1
    call SetConsoleCtrlHandler
    add rsp, 40
    ret
InstallProcessHooks endp

ConsoleCtrlHandler proc
    mov DWORD PTR [exit_requested], 1
    mov eax, 1
    ret
ConsoleCtrlHandler endp

UpdateTerminalGeometry proc uses rbx
    sub rsp, 40
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    add rsp, 40
    mov rbx, rax
    cmp rax, -1
    je geometry_done

    sub rsp, 40
    mov rcx, rbx
    lea rdx, console_info_buffer
    call GetConsoleScreenBufferInfo
    add rsp, 40
    test eax, eax
    jz geometry_done

    movsx eax, WORD PTR [console_info_buffer + CSBI_RIGHT]
    movsx edx, WORD PTR [console_info_buffer + CSBI_LEFT]
    sub eax, edx
    inc eax
    cmp eax, 1
    jge cols_ok
    mov eax, 100
cols_ok:
    cmp eax, MAX_COLS
    jle cols_fit
    mov eax, MAX_COLS
cols_fit:
    mov DWORD PTR [term_cols], eax

    movsx eax, WORD PTR [console_info_buffer + CSBI_BOTTOM]
    movsx edx, WORD PTR [console_info_buffer + CSBI_TOP]
    sub eax, edx
    inc eax
    cmp eax, 1
    jge rows_ok
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