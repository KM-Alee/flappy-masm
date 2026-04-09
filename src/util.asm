; util.asm - Utility functions: timing, RNG, file I/O, string helpers
;
; Provides clock access, sleep, debug detection, high-score persistence,
; and all string/number formatting routines used across the codebase.

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

; DetectDebugMode - Check if FLAPPY_DEBUG env var is set
DetectDebugMode proc
    lea rdi, debug_env_name
    call getenv
    test rax, rax
    jz debug_done
    mov DWORD PTR [debug_enabled], 1
debug_done:
    ret
DetectDebugMode endp

; SeedRng - Initialize the RNG state from the monotonic clock
SeedRng proc
    call ClockNowNs
    or rax, 1                       ; ensure odd seed
    mov QWORD PTR [rng_state], rax
    ret
SeedRng endp

; ClockNowNs - Read CLOCK_MONOTONIC and return nanoseconds in rax
ClockNowNs proc
    lea rsi, clock_buffer
    mov edi, CLOCK_MONOTONIC
    call clock_gettime
    mov rax, QWORD PTR [clock_buffer + TIMESPEC_SEC]
    mov rcx, 1000000000
    imul rax, rcx
    add rax, QWORD PTR [clock_buffer + TIMESPEC_NSEC]
    ret
ClockNowNs endp

; SleepUntilNextTick - Sleep for the remaining frame budget
;   Sleeps if the accumulator has not yet reached one full tick.
SleepUntilNextTick proc uses rbx
    mov rax, QWORD PTR [accumulator_ns]
    cmp rax, FRAME_NS
    jge sleep_done
    mov rbx, FRAME_NS
    sub rbx, rax
    cmp rbx, 1000000                ; skip if less than 1ms remains
    jl sleep_done

    mov rax, rbx
    xor edx, edx
    mov ecx, 1000000000
    div rcx
    mov QWORD PTR [sleep_buffer + TIMESPEC_SEC], rax
    mov QWORD PTR [sleep_buffer + TIMESPEC_NSEC], rdx
    lea rdi, sleep_buffer
    xor esi, esi
    call nanosleep

sleep_done:
    ret
SleepUntilNextTick endp

; PlaySoundCommand - Fire-and-forget shell command for a sound effect
;   rdi = command string
PlaySoundCommand proc
    call system
    ret
PlaySoundCommand endp

include include/util_shared.inc

end
