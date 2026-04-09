; render.asm - All rendering: background, pipes, bird, HUD, overlays
;
; Draws into the cell buffer then encodes and presents the frame.
; Drawing order: background -> pipes -> ground -> bird -> HUD -> overlays.
;
; Visual design:
;   - Clean blue sky gradient (deep blue at top, lighter toward ground)
;   - Solid color-block ground (green grass strip + brown earth)
;   - Solid green pipe columns with lighter cap rows
;   - Handcrafted animated bird sprite built for terminal rendering
;   - Layered white clouds built from overlapping puffs

option casemap:none
.x64

include include/config.inc
include include/game.inc

public RenderFrame
public RenderBackground
public RenderGround
public RenderPipes
public RenderBird
public RenderHud
public RenderTitleOverlay
public RenderPauseOverlay
public RenderDeadOverlay
public RenderSizeWarning
public RenderDebugOverlay
public DrawPanel
public FillRect
public PutCell
public DrawTextAt
public DrawTextCentered
public GetSkyColorForRow
public EncodeAndPresent
public AppendColor256

.code

; FillSolidRect - Fill a rectangle with a solid ANSI color using space cells.
;   edi=x, esi=y, edx=width, ecx=height, r8d=color
FillSolidRect proc uses r9
    mov r9d, r8d
    mov r8d, 32
    mov eax, r9d
    shl eax, 8
    or r8d, eax
    mov eax, r9d
    shl eax, 16
    or r8d, eax
    call FillRect
    ret
FillSolidRect endp

DrawCloud proc uses rbx r12 r13 r14
    mov r12d, edi
    mov r13d, esi
    mov r14d, edx

    mov ebx, r14d
    sar ebx, 1

    mov edi, r12d
    add edi, 1
    mov esi, r13d
    mov edx, ebx
    mov ecx, 1
    mov r8d, 255
    call FillSolidRect

    mov edi, r12d
    add edi, ebx
    sub edi, 1
    mov esi, r13d
    dec esi
    mov edx, ebx
    add edx, 1
    mov ecx, 1
    mov r8d, 255
    call FillSolidRect

    mov edi, r12d
    add edi, r14d
    sub edi, ebx
    mov esi, r13d
    mov edx, ebx
    mov ecx, 1
    mov r8d, 255
    call FillSolidRect

    mov edi, r12d
    mov esi, r13d
    inc esi
    mov edx, r14d
    add edx, 2
    mov ecx, 1
    mov r8d, 254
    call FillSolidRect

    mov edi, r12d
    add edi, 2
    mov esi, r13d
    add esi, 2
    mov edx, r14d
    sub edx, 1
    mov ecx, 1
    mov r8d, 252
    call FillSolidRect

    ret
DrawCloud endp

; RenderFrame - Compose and present one complete frame
RenderFrame proc uses rbx r12 r13 r14 r15
    call RenderBackground
    cmp DWORD PTR [small_terminal], 0
    jne render_small
    call RenderPipes
    call RenderGround
    call RenderBird
    call RenderHud

    cmp DWORD PTR [game_state], STATE_TITLE
    jne rf_maybe_pause
    call RenderTitleOverlay
    jmp rf_finish

rf_maybe_pause:
    cmp DWORD PTR [game_state], STATE_PAUSED
    jne rf_maybe_dead
    call RenderPauseOverlay
    jmp rf_finish

rf_maybe_dead:
    cmp DWORD PTR [game_state], STATE_DEAD
    jne rf_finish
    call RenderDeadOverlay
    jmp rf_finish

render_small:
    call RenderSizeWarning

rf_finish:
    cmp DWORD PTR [debug_enabled], 0
    je rf_no_debug
    call RenderDebugOverlay
rf_no_debug:
    call EncodeAndPresent
    ret
RenderFrame endp

; RenderBackground - Fill cell grid with blue sky and drifting clouds
RenderBackground proc uses rbx rcx rdx r12
    ; Fill each row with its sky gradient color (solid blue blocks)
    xor r12d, r12d
rbg_row_loop:
    cmp r12d, DWORD PTR [term_rows]
    jge rbg_clouds
    mov esi, r12d
    call GetSkyColorForRow
    movzx r8d, al
    mov edi, 0
    mov esi, r12d
    mov edx, DWORD PTR [term_cols]
    mov ecx, 1
    call FillSolidRect
    inc r12d
    jmp rbg_row_loop

rbg_clouds:
    ; === Sun: static golden block centered horizontally, rows 4-6 ===
    mov eax, DWORD PTR [term_cols]
    sar eax, 1                      ; center column
    sub eax, 4                      ; left edge of 9-wide block
    mov edi, eax
    mov esi, 4                      ; top row
    mov edx, 9                      ; width
    mov ecx, 3                      ; height (rows 4,5,6)
    mov r8d, 220
    call FillSolidRect
    ; Sun bright core: 5 wide, 1 tall at center row
    mov eax, DWORD PTR [term_cols]
    sar eax, 1
    sub eax, 2                      ; left edge of 5-wide core
    mov edi, eax
    mov esi, 5                      ; center row
    mov edx, 5
    mov ecx, 1
    mov r8d, 226
    call FillSolidRect

    ; Layered clouds with different rows, widths, and drift speeds
    mov eax, DWORD PTR [frame_counter]
    sar eax, 2
    mov ebx, DWORD PTR [term_cols]
    add ebx, 28
    xor edx, edx
    div ebx
    mov edi, edx
    sub edi, 16
    mov esi, 3
    mov edx, 11
    call DrawCloud

    mov eax, DWORD PTR [frame_counter]
    sar eax, 3
    add eax, 17
    mov ebx, DWORD PTR [term_cols]
    add ebx, 34
    xor edx, edx
    div ebx
    mov edi, edx
    sub edi, 18
    mov esi, 8
    mov edx, 13
    call DrawCloud

    mov eax, DWORD PTR [frame_counter]
    sar eax, 2
    add eax, 40
    mov ebx, DWORD PTR [term_cols]
    add ebx, 26
    xor edx, edx
    div ebx
    mov edi, edx
    sub edi, 15
    mov esi, 2
    mov edx, 10
    call DrawCloud

    mov eax, DWORD PTR [frame_counter]
    sar eax, 4
    add eax, 7
    mov ebx, DWORD PTR [term_cols]
    add ebx, 32
    xor edx, edx
    div ebx
    mov edi, edx
    sub edi, 17
    mov esi, 11
    mov edx, 12
    call DrawCloud

    mov eax, DWORD PTR [frame_counter]
    sar eax, 3
    add eax, 51
    mov ebx, DWORD PTR [term_cols]
    add ebx, 30
    xor edx, edx
    div ebx
    mov edi, edx
    sub edi, 16
    mov esi, 5
    mov edx, 12
    call DrawCloud

    mov eax, DWORD PTR [frame_counter]
    sar eax, 5
    add eax, 23
    mov ebx, DWORD PTR [term_cols]
    add ebx, 36
    xor edx, edx
    div ebx
    mov edi, edx
    sub edi, 19
    mov esi, 13
    mov edx, 14
    call DrawCloud
    ret
RenderBackground endp

; RenderGround - Solid-color ground: green grass top row, brown earth below
RenderGround proc uses rbx r12
    mov r12d, DWORD PTR [ground_top_row]
rg_fill_loop:
    cmp r12d, DWORD PTR [term_rows]
    jge rg_done
    cmp r12d, DWORD PTR [ground_top_row]
    jne rg_earth

    ; Grass row: bright green (color 34)
    mov r8d, 34
    jmp rg_fill

rg_earth:
    ; Earth rows: brown (color 130)
    mov r8d, 130

rg_fill:
    mov edi, 0
    mov esi, r12d
    mov edx, DWORD PTR [term_cols]
    mov ecx, 1
    call FillSolidRect
    inc r12d
    jmp rg_fill_loop

rg_done:
    ret
RenderGround endp

; RenderPipes - Solid green pipe columns with lighter cap rows
RenderPipes proc uses rbx r12 r13 r14
    xor r12d, r12d
rp_pipe_loop:
    cmp r12d, PIPE_COUNT
    jge rp_done
    lea rbx, pipes_x
    mov eax, DWORD PTR [rbx + r12 * 4]
    sar eax, 8
    mov r13d, eax                   ; r13 = pipe screen X
    lea rbx, pipes_gap_y
    mov eax, DWORD PTR [rbx + r12 * 4]
    mov r14d, eax                   ; r14 = gap top row

    ; --- Upper pipe body: solid dark green (color 28) ---
    mov edi, r13d
    mov esi, 0
    mov edx, PIPE_WIDTH
    mov ecx, r14d
    dec ecx                         ; leave room for cap row
    mov r8d, 28
    call FillSolidRect

    ; --- Upper pipe cap: lighter green (color 34), 1 row wider ---
    mov edi, r13d
    dec edi                         ; cap 1 col wider on each side
    mov esi, r14d
    dec esi
    mov edx, PIPE_WIDTH
    add edx, 2
    mov ecx, 1
    mov r8d, 34
    call FillSolidRect

    ; --- Lower pipe cap: lighter green, 1 row at gap bottom ---
    mov edi, r13d
    dec edi
    mov esi, r14d
    add esi, DWORD PTR [pipe_gap_height]
    mov edx, PIPE_WIDTH
    add edx, 2
    mov ecx, 1
    mov r8d, 34
    call FillSolidRect

    ; --- Lower pipe body: solid dark green (color 28) ---
    mov edi, r13d
    mov esi, r14d
    add esi, DWORD PTR [pipe_gap_height]
    inc esi                         ; below the lower cap
    mov eax, DWORD PTR [ground_top_row]
    sub eax, esi
    cmp eax, 0
    jle rp_next
    mov ecx, eax
    mov edx, PIPE_WIDTH
    mov edi, r13d
    mov r8d, 28
    call FillSolidRect

rp_next:
    inc r12d
    jmp rp_pipe_loop

rp_done:
    ret
RenderPipes endp

; RenderBird - Draw a yellow ASCII bird with simple wing up/down animation.
RenderBird proc uses rbx r12 r13 r14 r15
    mov eax, DWORD PTR [bird_y]
    sar eax, 8
    mov r12d, eax
    mov r13d, DWORD PTR [bird_column]
    sub r13d, BIRD_SPRITE_OFFSET_X
    sub r12d, BIRD_SPRITE_OFFSET_Y

    mov ebx, 226                    ; bright yellow bird glyphs
    mov r14d, 226                   ; wings use the same yellow
    cmp DWORD PTR [game_state], STATE_DEAD
    jne rb_palette_ok
    mov ebx, 245
    mov r14d, 245
rb_palette_ok:

    mov r15d, 1                     ; default mid flap
    cmp DWORD PTR [game_state], STATE_DEAD
    je rb_pose_ready
    mov eax, DWORD PTR [frame_counter]
    and eax, 15
    cmp eax, 5
    jl rb_pose_up
    cmp eax, 10
    jl rb_pose_ready
    mov r15d, 2                     ; down flap
    jmp rb_pose_ready
rb_pose_up:
    xor r15d, r15d
rb_pose_ready:

    ; Row 0: body and optional upper wings
    mov esi, r12d
    call GetSkyColorForRow
    movzx r8d, al
    cmp r15d, 0
    jne rb_row0_body
    mov edi, r13d
    mov dl, '/'
    mov ecx, r14d
    call PutCell
    mov edi, r13d
    add edi, 5
    mov dl, 92
    mov ecx, r14d
    call PutCell
rb_row0_body:
    mov edi, r13d
    add edi, 1
    mov dl, '('
    mov ecx, ebx
    call PutCell
    mov edi, r13d
    add edi, 2
    mov dl, 'O'
    mov ecx, ebx
    call PutCell
    mov edi, r13d
    add edi, 3
    mov dl, '>'
    mov ecx, ebx
    call PutCell

    ; Row 1: body fill and optional mid wings
    mov esi, r12d
    inc esi
    call GetSkyColorForRow
    movzx r8d, al
    cmp r15d, 1
    jne rb_row1_fill
    mov edi, r13d
    mov dl, '/'
    mov ecx, r14d
    call PutCell
    mov edi, r13d
    add edi, 4
    mov dl, 92
    mov ecx, r14d
    call PutCell
rb_row1_fill:
    mov edi, r13d
    add edi, 1
    mov dl, '/'
    mov ecx, ebx
    call PutCell
    mov edi, r13d
    add edi, 2
    mov dl, '@'
    mov ecx, ebx
    call PutCell
    mov edi, r13d
    add edi, 3
    mov dl, '@'
    mov ecx, ebx
    call PutCell
    mov edi, r13d
    add edi, 4
    mov dl, 92
    mov ecx, ebx
    call PutCell

    ; Row 2: feet and optional lower wings
    mov esi, r12d
    add esi, 2
    call GetSkyColorForRow
    movzx r8d, al
    cmp r15d, 2
    jne rb_row2_feet
    mov edi, r13d
    mov dl, 92
    mov ecx, r14d
    call PutCell
    mov edi, r13d
    add edi, 4
    mov dl, '/'
    mov ecx, r14d
    call PutCell
rb_row2_feet:
    mov edi, r13d
    add edi, 2
    mov dl, '^'
    mov ecx, ebx
    call PutCell
    mov edi, r13d
    add edi, 3
    mov dl, '^'
    mov ecx, ebx
    call PutCell

rb_done:
    ret
RenderBird endp

; RenderHud - Show score prominently at top center, and best score smaller
RenderHud proc uses rbx r12
    ; Draw the current score on a white badge with black text.
    mov eax, DWORD PTR [score_value]
    lea rdi, number_buffer
    call UIntToString

    ; Use a contrasting background block behind the score for visibility
    ; Get string length to know how wide the background needs to be
    lea rdi, number_buffer
    call StringLength
    mov r12d, eax                   ; r12 = score string length

    ; Draw a clean white score badge.
    mov eax, DWORD PTR [term_cols]
    sub eax, r12d
    sub eax, 4                      ; 2 padding on each side
    sar eax, 1
    mov edi, eax
    mov esi, 0
    mov edx, r12d
    add edx, 4                      ; width with padding
    mov ecx, 3                      ; 3 rows tall
    mov r8d, 231
    call FillSolidRect

    ; Draw score text centered on row 1
    mov esi, 1
    lea rdx, number_buffer
    mov ecx, 16                     ; black
    mov r8d, 231                    ; white bg
    call DrawTextCentered

    ; Show best score on row 0, smaller, right-aligned
    cmp DWORD PTR [best_score], 0
    je hud_done
    lea rdi, debug_buffer
    lea rsi, debug_prefix_3         ; "best "
    call CopyString
    mov eax, DWORD PTR [best_score]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], 0

    ; Draw at top-right corner with white background badge
    lea rdi, debug_buffer
    call StringLength
    mov r12d, eax                   ; reuse r12 for best score string length
    ; White background box
    mov edi, DWORD PTR [term_cols]
    sub edi, r12d
    sub edi, 4                      ; 2 col padding each side
    mov esi, 0
    mov edx, r12d
    add edx, 4                      ; total width with padding
    mov ecx, 1                      ; 1 row
    mov r8d, 231
    call FillSolidRect
    ; Draw text
    mov edi, DWORD PTR [term_cols]
    sub edi, r12d
    sub edi, 2                      ; 2 col from right edge
    mov esi, 0
    lea rdx, debug_buffer
    mov ecx, 16                     ; black
    mov r8d, 231                    ; white bg
    call DrawTextAt

hud_done:
    ret
RenderHud endp

; RenderTitleOverlay - Start screen panel centered on screen
RenderTitleOverlay proc uses r12
    mov eax, DWORD PTR [term_cols]
    sub eax, 44
    sar eax, 1
    mov edi, eax
    mov eax, DWORD PTR [term_rows]
    sub eax, 11
    sar eax, 1
    mov esi, eax
    mov r12d, eax
    mov edx, 44
    mov ecx, 11
    mov r8d, 16
    mov r9d, 231                    ; white card
    call DrawPanel

    mov esi, r12d
    add esi, 2
    lea rdx, title_line_1
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered
    mov esi, r12d
    add esi, 4
    lea rdx, title_line_2
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered
    mov esi, r12d
    add esi, 5
    lea rdx, title_line_3
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered
    mov esi, r12d
    add esi, 8
    lea rdx, title_line_4
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered
    ret
RenderTitleOverlay endp

; RenderPauseOverlay - Pause panel
RenderPauseOverlay proc uses r12
    mov eax, DWORD PTR [term_cols]
    sub eax, 24
    sar eax, 1
    mov edi, eax
    mov eax, DWORD PTR [term_rows]
    sub eax, 5
    sar eax, 1
    mov esi, eax
    mov r12d, eax
    mov edx, 24
    mov ecx, 5
    mov r8d, 16
    mov r9d, 231
    call DrawPanel
    mov esi, r12d
    add esi, 2
    lea rdx, pause_line
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered
    ret
RenderPauseOverlay endp

; RenderDeadOverlay - Rectangular white game-over card with black text
RenderDeadOverlay proc uses r12
    mov eax, DWORD PTR [term_cols]
    sub eax, 44
    sar eax, 1
    mov edi, eax
    mov eax, DWORD PTR [term_rows]
    sub eax, 13
    sar eax, 1
    mov esi, eax
    mov r12d, eax                   ; r12 = panel top y
    mov edx, 44
    mov ecx, 13
    mov r8d, 16
    mov r9d, 231                    ; white card
    call DrawPanel

    mov esi, r12d
    add esi, 2
    lea rdx, game_over_line
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered

    ; Upper score band
    mov eax, DWORD PTR [term_cols]
    sub eax, 36
    sar eax, 1
    mov edi, eax
    mov esi, r12d
    add esi, 4
    mov edx, 36
    mov ecx, 1
    mov r8d, 255
    call FillSolidRect

    ; "SCORE: X" - build in debug_buffer
    lea rdi, debug_buffer
    lea rsi, score_label_s
    call CopyString
    mov eax, DWORD PTR [score_value]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], 0
    mov esi, r12d
    add esi, 5
    lea rdx, debug_buffer
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered

    ; "BEST:  X" - build in debug_buffer
    lea rdi, debug_buffer
    lea rsi, best_label_s
    call CopyString
    mov eax, DWORD PTR [best_score]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], 0
    mov esi, r12d
    add esi, 7
    lea rdx, debug_buffer
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered

    ; Lower restart band
    mov eax, DWORD PTR [term_cols]
    sub eax, 36
    sar eax, 1
    mov edi, eax
    mov esi, r12d
    add esi, 9
    mov edx, 36
    mov ecx, 1
    mov r8d, 255
    call FillSolidRect

    ; Restart hint
    mov esi, r12d
    add esi, 11
    lea rdx, restart_line
    mov ecx, 16
    mov r8d, 231
    call DrawTextCentered
    ret
RenderDeadOverlay endp

; RenderSizeWarning - "terminal too small" on dark blue background
RenderSizeWarning proc uses rbx
    mov edi, 0
    mov esi, 0
    mov edx, DWORD PTR [term_cols]
    mov ecx, DWORD PTR [term_rows]
    mov r8d, 25
    call FillSolidRect
    mov eax, DWORD PTR [term_rows]
    sar eax, 1
    sub eax, 1
    mov esi, eax
    lea rdx, warning_line_1
    mov ecx, 231
    mov r8d, 25
    call DrawTextCentered
    mov eax, DWORD PTR [term_rows]
    sar eax, 1
    add eax, 1
    mov esi, eax
    lea rdx, warning_line_2
    mov ecx, 255
    mov r8d, 25
    call DrawTextCentered
    ret
RenderSizeWarning endp

; RenderDebugOverlay - Debug info on the bottom row
RenderDebugOverlay proc
    lea rdi, debug_buffer
    lea rsi, debug_prefix_1
    call CopyString
    mov eax, DWORD PTR [term_cols]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], 'x'
    inc rdi
    mov eax, DWORD PTR [term_rows]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], ' '
    inc rdi
    lea rsi, debug_prefix_2
    call CopyStringInline
    mov eax, DWORD PTR [score_value]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], ' '
    inc rdi
    lea rsi, debug_prefix_3
    call CopyStringInline
    mov eax, DWORD PTR [best_score]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], ' '
    inc rdi
    lea rsi, debug_prefix_4
    call CopyStringInline
    mov eax, DWORD PTR [game_state]
    call AppendNumberToBuffer
    mov BYTE PTR [rdi], 0
    mov eax, DWORD PTR [term_rows]
    dec eax
    mov esi, eax
    mov edi, 1
    lea rdx, debug_buffer
    mov ecx, 16
    mov r8d, 229
    call DrawTextAt
    ret
RenderDebugOverlay endp

; ---------------------------------------------------------------------------
; Drawing primitives
; ---------------------------------------------------------------------------

; DrawPanel - Bordered rectangle for overlay dialogs
;   edi=x, esi=y, edx=width, ecx=height, r8d=fg, r9d=bg
DrawPanel proc uses rbx r12 r13 r14 r15
    mov r12d, edi
    mov r13d, esi
    mov r14d, edx
    mov r15d, ecx

    mov edi, r12d
    mov esi, r13d
    mov edx, r14d
    mov ecx, r15d
    call FillSolidRect

    ; Inner fill area
    cmp r14d, 2
    jle dp_done
    cmp r15d, 2
    jle dp_done
    mov edi, r12d
    inc edi
    mov esi, r13d
    inc esi
    mov edx, r14d
    sub edx, 2
    mov ecx, r15d
    sub ecx, 2
    mov r8d, r9d
    call FillSolidRect
dp_done:
    ret
DrawPanel endp

; FillRect - Fill a rectangular region of the cell buffer
;   edi=x, esi=y, edx=width, ecx=height, r8d=packed_cell
FillRect proc uses rbx r12 r13 r14
    test edx, edx
    jle fill_done
    test ecx, ecx
    jle fill_done

    mov r12d, edi
    mov r13d, esi
    mov r14d, edx
    mov ebx, ecx

    ; Clip to screen bounds
    cmp r12d, 0
    jge clip_x_ok
    add r14d, r12d
    xor r12d, r12d
clip_x_ok:
    cmp r13d, 0
    jge clip_y_ok
    add ebx, r13d
    xor r13d, r13d
clip_y_ok:
    cmp r14d, 0
    jle fill_done
    cmp ebx, 0
    jle fill_done

    mov eax, r12d
    add eax, r14d
    cmp eax, DWORD PTR [term_cols]
    jle clip_w_ok
    mov eax, DWORD PTR [term_cols]
    sub eax, r12d
    mov r14d, eax
clip_w_ok:
    mov eax, r13d
    add eax, ebx
    cmp eax, DWORD PTR [term_rows]
    jle clip_h_ok
    mov eax, DWORD PTR [term_rows]
    sub eax, r13d
    mov ebx, eax
clip_h_ok:
    cmp r14d, 0
    jle fill_done
    cmp ebx, 0
    jle fill_done

fill_row_loop:
    cmp ebx, 0
    jle fill_done
    mov eax, r13d
    imul eax, MAX_COLS
    add eax, r12d
    shl eax, 2
    lea rdi, [cell_buffer + rax]
    mov eax, r8d
    mov ecx, r14d
    rep stosd
    inc r13d
    dec ebx
    jmp fill_row_loop

fill_done:
    ret
FillRect endp

; DrawTextCentered - Draw a string horizontally centered on a row
;   esi=row, rdx=string_ptr, ecx=fg, r8d=bg
DrawTextCentered proc uses rbx
    mov rdi, rdx
    call StringLength
    mov ebx, eax
    mov eax, DWORD PTR [term_cols]
    sub eax, ebx
    sar eax, 1
    mov edi, eax
    call DrawTextAt
    ret
DrawTextCentered endp

; DrawTextAt - Draw a null-terminated string at a position
;   edi=x, esi=y, rdx=string_ptr, ecx=fg, r8d=bg
DrawTextAt proc uses rbx r12 r13
    mov r12d, edi
    mov r13d, esi
    mov rbx, rdx
text_loop:
    mov dl, BYTE PTR [rbx]
    test dl, dl
    jz text_done
    mov edi, r12d
    mov esi, r13d
    call PutCell
    inc r12d
    inc rbx
    jmp text_loop
text_done:
    ret
DrawTextAt endp

; PutCell - Write one cell into the cell buffer
;   edi=x, esi=y, dl=glyph, ecx=fg_color, r8d=bg_color
PutCell proc
    cmp edi, 0
    jl put_done
    cmp esi, 0
    jl put_done
    cmp edi, DWORD PTR [term_cols]
    jge put_done
    cmp esi, DWORD PTR [term_rows]
    jge put_done
    mov eax, esi
    imul eax, MAX_COLS
    add eax, edi
    shl eax, 2
    lea rax, [cell_buffer + rax]
    mov BYTE PTR [rax + CELL_GLYPH], dl
    mov BYTE PTR [rax + CELL_FG], cl
    mov BYTE PTR [rax + CELL_BG], r8b
put_done:
    ret
PutCell endp

; GetSkyColorForRow - Map a screen row to a sky palette color
;   esi=row -> returns ANSI color index in al
GetSkyColorForRow proc uses rbx
    mov eax, esi
    imul eax, SKY_COLOR_COUNT
    xor edx, edx
    mov ebx, DWORD PTR [term_rows]
    cmp ebx, 1
    jg sky_div_ok
    mov ebx, 1
sky_div_ok:
    div ebx
    cmp eax, SKY_COLOR_COUNT - 1
    jle sky_index_ok
    mov eax, SKY_COLOR_COUNT - 1
sky_index_ok:
    movzx eax, BYTE PTR [sky_palette + rax]
    ret
GetSkyColorForRow endp

; EncodeAndPresent - Convert cell buffer to ANSI stream and write to stdout
EncodeAndPresent proc uses rbx r12 r13 r14 r15
    lea rdi, out_buffer
    lea rsi, home_sequence
    call AppendString
    mov r14d, -1
    mov r15d, -1
    xor r12d, r12d

encode_row_loop:
    cmp r12d, DWORD PTR [term_rows]
    jge encode_finish
    xor r13d, r13d
encode_col_loop:
    cmp r13d, DWORD PTR [term_cols]
    jge encode_row_done
    mov eax, r12d
    imul eax, MAX_COLS
    add eax, r13d
    shl eax, 2
    lea rbx, [cell_buffer + rax]
    movzx ecx, BYTE PTR [rbx + CELL_FG]
    movzx edx, BYTE PTR [rbx + CELL_BG]

    cmp ecx, r14d
    jne color_change
    cmp edx, r15d
    je color_ready
color_change:
    mov r14d, ecx
    mov r15d, edx
    mov eax, ecx
    push rbx
    mov ebx, edx
    call AppendColor256
    pop rbx
color_ready:
    mov al, BYTE PTR [rbx + CELL_GLYPH]
    stosb
    inc r13d
    jmp encode_col_loop

encode_row_done:
    mov eax, DWORD PTR [term_rows]
    dec eax
    cmp r12d, eax
    je encode_next_row
    mov al, 13
    stosb
    mov al, 10
    stosb
encode_next_row:
    inc r12d
    jmp encode_row_loop

encode_finish:
    lea rsi, reset_style_sequence
    call AppendString
    mov rdx, rdi
    lea rsi, out_buffer
    sub rdx, rsi
    mov edi, STDOUT_FD
    call write
    ret
EncodeAndPresent endp

; AppendColor256 - Append ANSI 256-color escape to output stream
;   eax=fg, ebx=bg, rdi=output pointer (advanced)
AppendColor256 proc uses rbx
    mov r9d, eax                    ; save fg color; AppendString clobbers al
    lea rsi, fg_prefix
    call AppendString
    mov eax, r9d                    ; restore fg color
    call AppendUnsignedToStream
    lea rsi, bg_prefix
    call AppendString
    mov eax, ebx
    call AppendUnsignedToStream
    lea rsi, color_suffix
    call AppendString
    ret
AppendColor256 endp

end
