; util_win.asm - Windows utility functions

option casemap:none
.x64

include include/config.inc
include include/game.inc

public DetectDebugMode
public SeedRng
public ClockNowNs
public SleepUntilNextTick
public LoadBestScore
public SaveBestScore
public PlaySwooshSound
public PlayPointSound
public PlayHitSound
public PlayDieSound
public WriteString
public AppendString
public AppendUnsignedToStream
public StringLength
public UIntToString
public CopyString
public CopyStringInline
public AppendNumberToBuffer

.code

DetectDebugMode proc
    sub rsp, 40
    lea rcx, debug_env_name
    call getenv
    add rsp, 40
    test rax, rax
    jz debug_done
    mov DWORD PTR [debug_enabled], 1
debug_done:
    ret
DetectDebugMode endp

SeedRng proc
    sub rsp, 40
    lea rcx, qpc_frequency
    call QueryPerformanceFrequency
    add rsp, 40
    call ClockNowNs
    or rax, 1
    mov QWORD PTR [rng_state], rax
    ret
SeedRng endp

ClockNowNs proc uses rbx
    sub rsp, 40
    lea rcx, clock_buffer
    call QueryPerformanceCounter
    add rsp, 40
    mov rax, QWORD PTR [clock_buffer]
    mov rbx, QPC_SCALE
    imul rax, rbx
    xor edx, edx
    div QWORD PTR [qpc_frequency]
    ret
ClockNowNs endp

SleepUntilNextTick proc uses rbx
    mov rax, QWORD PTR [accumulator_ns]
    cmp rax, FRAME_NS
    jge sleep_done
    mov rbx, FRAME_NS
    sub rbx, rax
    cmp rbx, 1000000
    jl sleep_done
    add rbx, 999999
    mov rax, rbx
    xor edx, edx
    mov ecx, 1000000
    div rcx
    sub rsp, 40
    mov ecx, eax
    call Sleep
    add rsp, 40
sleep_done:
    ret
SleepUntilNextTick endp

PlaySoundCommand proc
    sub rsp, 40
    mov rcx, rdi
    call system
    add rsp, 40
    ret
PlaySoundCommand endp

include include/util_shared.inc

end