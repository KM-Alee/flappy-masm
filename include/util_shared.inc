; util_shared.inc - Procedures shared by both utility backends

; LoadBestScore - Read best score from disk file
LoadBestScore proc
    lea rdi, highscore_path
    mov esi, O_RDONLY
    xor edx, edx
    call open
    test eax, eax
    js load_default
    mov edi, eax
    mov ecx, eax                    ; save fd
    lea rsi, best_score
    mov edx, 4
    call read
    push rax
    mov edi, ecx
    call close
    pop rax
    cmp eax, 4
    je load_done
load_default:
    mov DWORD PTR [best_score], 0
load_done:
    ret
LoadBestScore endp

; SaveBestScore - Write best score to disk file
SaveBestScore proc
    lea rdi, highscore_path
    mov esi, O_WRONLY or O_CREAT or O_TRUNC
    mov edx, MODE_0644
    call open
    test eax, eax
    js save_done
    mov edi, eax
    mov ecx, eax                    ; save fd
    lea rsi, best_score
    mov edx, 4
    call write
    mov edi, ecx
    call close
save_done:
    ret
SaveBestScore endp

PlaySwooshSound proc
    lea rdi, swoosh_sound_command
    call PlaySoundCommand
    ret
PlaySwooshSound endp

PlayPointSound proc
    lea rdi, point_sound_command
    call PlaySoundCommand
    ret
PlayPointSound endp

PlayHitSound proc
    lea rdi, hit_sound_command
    call PlaySoundCommand
    ret
PlayHitSound endp

PlayDieSound proc
    lea rdi, die_sound_command
    call PlaySoundCommand
    ret
PlayDieSound endp

; WriteString - Write a null-terminated string to stdout
;   rdi = string pointer
WriteString proc uses rbx
    mov rbx, rdi
    call StringLength
    mov edx, eax
    mov edi, STDOUT_FD
    mov rsi, rbx
    call write
    ret
WriteString endp

; AppendString - Copy a null-terminated string into the output stream
;   rsi = source, rdi = destination (advanced past the copy)
AppendString proc
append_string_loop:
    mov al, BYTE PTR [rsi]
    inc rsi
    test al, al
    jz append_string_done
    stosb
    jmp append_string_loop
append_string_done:
    ret
AppendString endp

; AppendUnsignedToStream - Append decimal digits of eax to the stream at rdi
AppendUnsignedToStream proc uses rbx rcx rdx rsi
    lea rsi, number_reverse
    mov ecx, 0
    cmp eax, 0
    jne append_digits
    mov BYTE PTR [rsi], '0'
    mov ecx, 1
    jmp append_emit
append_digits:
    mov ebx, 10
append_div_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    mov BYTE PTR [rsi + rcx], dl
    inc ecx
    test eax, eax
    jne append_div_loop
append_emit:
    dec ecx
append_emit_loop:
    cmp ecx, -1
    je append_done
    mov al, BYTE PTR [rsi + rcx]
    stosb
    dec ecx
    jmp append_emit_loop
append_done:
    ret
AppendUnsignedToStream endp

; StringLength - Return the length of a null-terminated string
;   rdi = string pointer -> eax = length
StringLength proc
    xor eax, eax
string_length_loop:
    cmp BYTE PTR [rdi + rax], 0
    je string_length_done
    inc eax
    jmp string_length_loop
string_length_done:
    ret
StringLength endp

; UIntToString - Convert unsigned integer to null-terminated decimal string
;   eax = value, rdi = destination buffer -> eax = string length
UIntToString proc uses rbx rcx rdx rsi
    lea rsi, number_reverse
    mov ecx, 0
    cmp eax, 0
    jne utoa_digits
    mov BYTE PTR [rdi], '0'
    mov BYTE PTR [rdi + 1], 0
    mov eax, 1
    ret
utoa_digits:
    mov ebx, 10
utoa_div_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    mov BYTE PTR [rsi + rcx], dl
    inc ecx
    test eax, eax
    jne utoa_div_loop
    mov eax, ecx
    dec ecx
utoa_emit_loop:
    cmp ecx, -1
    je utoa_done
    mov dl, BYTE PTR [rsi + rcx]
    mov BYTE PTR [rdi], dl
    inc rdi
    dec ecx
    jmp utoa_emit_loop
utoa_done:
    mov BYTE PTR [rdi], 0
    ret
UIntToString endp

; CopyString - Copy null-terminated string (rsi -> rdi), rdi left at the NUL
CopyString proc
copy_string_loop:
    mov al, BYTE PTR [rsi]
    mov BYTE PTR [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz copy_string_loop
    dec rdi
    ret
CopyString endp

; CopyStringInline - Copy string without advancing past the NUL
CopyStringInline proc
copy_string_inline_loop:
    mov al, BYTE PTR [rsi]
    inc rsi
    test al, al
    jz copy_string_inline_done
    mov BYTE PTR [rdi], al
    inc rdi
    jmp copy_string_inline_loop
copy_string_inline_done:
    ret
CopyStringInline endp

; AppendNumberToBuffer - Format eax as decimal and append to rdi
AppendNumberToBuffer proc uses rsi
    push rdi
    lea rdi, number_buffer
    call UIntToString
    pop rdi
    lea rsi, number_buffer
append_number_copy:
    mov al, BYTE PTR [rsi]
    inc rsi
    test al, al
    jz append_number_done
    mov BYTE PTR [rdi], al
    inc rdi
    jmp append_number_copy
append_number_done:
    ret
AppendNumberToBuffer endp