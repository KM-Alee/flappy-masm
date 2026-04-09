; physics.asm - Game state machine, bird physics, pipe logic, collision
;
; Contains the fixed-timestep update, bird movement, pipe scrolling,
; scoring, collision detection, and run lifecycle management.

option casemap:none
.x64

include include/config.inc
include include/game.inc

public UpdateGame
public ResetRun
public StartRun

.code

; UpdateGame - One fixed-timestep tick of game logic
;   Only runs meaningful work in RUNNING or DEAD states.
UpdateGame proc uses rbx rcx rdx r12 r13 r14 r15
    cmp DWORD PTR [small_terminal], 0
    jne update_done

    mov eax, DWORD PTR [game_state]
    cmp eax, STATE_RUNNING
    je update_running
    cmp eax, STATE_DEAD
    je update_dead
    jmp update_done

update_running:
    ; Apply gravity to bird velocity, clamped to MAX_FALL_FP
    mov eax, DWORD PTR [bird_velocity]
    add eax, GRAVITY_FP
    cmp eax, MAX_FALL_FP
    jle bird_vel_ok
    mov eax, MAX_FALL_FP
bird_vel_ok:
    mov DWORD PTR [bird_velocity], eax
    add DWORD PTR [bird_y], eax

    ; Move pipes leftward, check scoring, recycle off-screen pipes
    xor r12d, r12d
pipe_update_loop:
    cmp r12d, PIPE_COUNT
    jge collision_phase
    lea rbx, pipes_x
    sub DWORD PTR [rbx + r12 * 4], PIPE_SPEED_FP

    ; Convert pipe X to screen pixels for scoring check
    mov eax, DWORD PTR [rbx + r12 * 4]
    sar eax, 8
    add eax, PIPE_WIDTH
    lea rcx, pipes_scored
    cmp DWORD PTR [rcx + r12 * 4], 0
    jne scored_check_done
    cmp eax, DWORD PTR [bird_column]
    jg scored_check_done
    mov DWORD PTR [rcx + r12 * 4], 1
    inc DWORD PTR [score_value]
    call PlayPointSound
scored_check_done:

    ; Recycle pipe if its right edge has scrolled off-screen
    cmp eax, 0
    jge next_pipe_update
    call FindRightmostPipePx
    mov r15d, eax
    call RandomPipeSpacing
    add eax, r15d
    shl eax, 8
    lea rbx, pipes_x
    mov DWORD PTR [rbx + r12 * 4], eax
    lea rcx, pipes_scored
    mov DWORD PTR [rcx + r12 * 4], 0
    push r12
    call RandomGapRow
    pop r12
    lea rdx, pipes_gap_y
    mov DWORD PTR [rdx + r12 * 4], eax

next_pipe_update:
    inc r12d
    jmp pipe_update_loop

collision_phase:
    ; Convert bird Y to screen row
    mov eax, DWORD PTR [bird_y]
    sar eax, 8
    mov r13d, eax

    ; Check floor and ceiling
    cmp r13d, 1
    jl bird_hit
    cmp r13d, DWORD PTR [ground_top_row]
    jge bird_hit

    ; Check collision with each pipe
    xor r12d, r12d
collision_loop:
    cmp r12d, PIPE_COUNT
    jge update_done
    lea rbx, pipes_x
    mov eax, DWORD PTR [rbx + r12 * 4]
    sar eax, 8
    mov r14d, eax                   ; r14 = pipe left X
    mov ebx, DWORD PTR [bird_column]
    cmp ebx, r14d
    jl next_collision               ; bird is left of pipe
    lea ecx, [r14d + PIPE_WIDTH]
    cmp ebx, ecx
    jge next_collision              ; bird is right of pipe

    ; Bird overlaps pipe horizontally - check vertical gap
    lea rbx, pipes_gap_y
    mov eax, DWORD PTR [rbx + r12 * 4]
    cmp r13d, eax
    jl bird_hit                     ; above the gap
    add eax, DWORD PTR [pipe_gap_height]
    cmp r13d, eax
    jge bird_hit                    ; below the gap

next_collision:
    inc r12d
    jmp collision_loop

bird_hit:
    call PlayHitSound
    call KillRun
    call PlayDieSound
    jmp update_done

update_dead:
    ; Bird keeps falling after death until it hits the ground
    mov eax, DWORD PTR [bird_velocity]
    add eax, GRAVITY_FP
    cmp eax, MAX_FALL_FP
    jle dead_vel_ok
    mov eax, MAX_FALL_FP
dead_vel_ok:
    mov DWORD PTR [bird_velocity], eax
    add DWORD PTR [bird_y], eax
    mov eax, DWORD PTR [bird_y]
    sar eax, 8
    mov ecx, DWORD PTR [ground_top_row]
    dec ecx
    cmp eax, ecx
    jle update_done
    shl ecx, 8
    mov DWORD PTR [bird_y], ecx

update_done:
    ret
UpdateGame endp

; ResetRun - Initialize all game state for a new run
ResetRun proc uses rbx rcx rdx
    mov DWORD PTR [game_state], STATE_TITLE
    mov DWORD PTR [score_value], 0
    mov DWORD PTR [bird_velocity], 0

    ; Center the bird vertically in the playfield
    mov eax, DWORD PTR [term_rows]
    sub eax, GROUND_ROWS
    shr eax, 1
    shl eax, 8                      ; convert to fixed-point
    mov DWORD PTR [bird_y], eax

    ; Space pipes with randomized intervals starting just off the right edge.
    mov ebx, DWORD PTR [term_cols]
    add ebx, 10
    xor ecx, ecx
reset_pipe_loop:
    cmp ecx, PIPE_COUNT
    jge reset_done
    mov eax, ebx
    shl eax, 8                      ; fixed-point X
    lea rdx, pipes_x
    mov DWORD PTR [rdx + rcx * 4], eax
    lea rdx, pipes_scored
    mov DWORD PTR [rdx + rcx * 4], 0
    push rcx
    call RandomGapRow
    pop rcx
    lea rdx, pipes_gap_y
    mov DWORD PTR [rdx + rcx * 4], eax
    push rcx
    call RandomPipeSpacing
    pop rcx
    add ebx, eax
    inc ecx
    jmp reset_pipe_loop
reset_done:
    ret
ResetRun endp

; StartRun - Transition from title/dead to running state
StartRun proc
    cmp DWORD PTR [small_terminal], 0
    jne start_done
    mov DWORD PTR [game_state], STATE_RUNNING
    mov DWORD PTR [bird_velocity], FLAP_VEL_FP
start_done:
    ret
StartRun endp

; KillRun - End the current run, update best score
KillRun proc
    cmp DWORD PTR [game_state], STATE_DEAD
    je kill_done
    mov DWORD PTR [game_state], STATE_DEAD
    mov eax, DWORD PTR [score_value]
    cmp eax, DWORD PTR [best_score]
    jle kill_done
    mov DWORD PTR [best_score], eax
    call SaveBestScore
kill_done:
    ret
KillRun endp

; RandomGapRow - Pick a random Y position for a pipe gap
;   Returns the gap top row in eax.
RandomGapRow proc uses rbx
    mov ebx, DWORD PTR [ground_top_row]
    sub ebx, DWORD PTR [pipe_gap_height]
    sub ebx, 4
    cmp ebx, 6
    jg gap_range_ok
    mov eax, 5
    ret
gap_range_ok:
    mov edi, ebx
    call RandomMod
    add eax, 2
    ret
RandomGapRow endp

; RandomPipeSpacing - Return the next pipe spacing around the current baseline.
RandomPipeSpacing proc uses rbx
    mov ebx, DWORD PTR [pipe_spacing]
    mov edi, 13
    call RandomMod
    sub eax, 6
    add eax, ebx
    cmp eax, 18
    jge random_spacing_min_ok
    mov eax, 18
random_spacing_min_ok:
    cmp eax, 38
    jle random_spacing_done
    mov eax, 38
random_spacing_done:
    ret
RandomPipeSpacing endp

; RandomMod - Return a pseudo-random number in [0, edi)
;   Uses a linear congruential generator.
RandomMod proc uses rbx
    cmp edi, 1
    jg random_go
    xor eax, eax
    ret
random_go:
    mov rax, QWORD PTR [rng_state]
    mov rbx, 6364136223846793005
    imul rax, rbx
    mov rcx, 1442695040888963407
    add rax, rcx
    mov QWORD PTR [rng_state], rax
    xor edx, edx
    div rdi
    mov eax, edx
    ret
RandomMod endp

; FindRightmostPipePx - Find the rightmost pipe's screen X
;   Returns screen-pixel X in eax.
FindRightmostPipePx proc uses rbx rcx
    mov eax, DWORD PTR [pipes_x]
    sar eax, 8
    mov ecx, 1
find_right_loop:
    cmp ecx, PIPE_COUNT
    jge find_right_done
    lea rbx, pipes_x
    mov edx, DWORD PTR [rbx + rcx * 4]
    sar edx, 8
    cmp edx, eax
    jle next_right
    mov eax, edx
next_right:
    inc ecx
    jmp find_right_loop
find_right_done:
    ret
FindRightmostPipePx endp

end
