bits 16

section _ENTRY class=TEXT

global _x86_Video_WriteCharTeletype
global _x86_div64_32
;
; int 10h ah=0Eh
; args: character, page
;
_x86_Video_WriteCharTeletype:
    ; make new stack frame
    push bp
    mov bp, sp

    push bx                         ; save bx

    ; [bp + 0] - return address (small memory model => 2 bytes)
    ; [bp + 2] - old call frame
    ; [bp + 4] - first argument (character)
    ; [bp + 6] - second argument (page)
    ; check https://www.ctyme.com/intr/rb-0106.htm if confused
    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]

    int 10h

    pop bx

    mov sp, bp
    pop bp
    ret

; void _cdecl x86_div64_32(uint64_t divident, uint32_t divisor, uint32_t* quotientOut, uint32_t* remainderOut);
; divides a 64 bit number by a 32 bit one
; args: 
;   [bp + 0] - ret address
;   [bp + 2] - old call frame
;   [bp + 4] - divident lower 32
;   [bp + 8] - divindent upper 32
;   [bp + 12] - divisor
;   [bp + 16] - quotient
;   [bp + 18] - remainder
;   pointers in small mem model are 2 bytes
;
_x86_div64_32:
    ; make new stack frame
    push bp
    mov bp, sp

    push bx                     ; save registers

    ; divide upper 32 bits
    mov eax, [bp + 8]           ; upper 32 bits of divident
    mov ecx, [bp + 12]          ; ecx <- divisor
    xor edx, edx
    div ecx                     ; eax - quotient, edx - remainder

    ; store upper 32 bits of quotient
    mov bx, [bp + 16]           ; get pointer to quotient
    mov [bx + 4], eax           ; store in the upper half

    ; divide upper 32 bits
    mov eax, [bp + 4]           ; lower 32 bits of divident
    mov ecx, [bp + 12]          ; ecx <- divisor
                                ; edx <- old remainder
    div ecx

    ; store results
    mov [bx], eax
    mov bx, [bp + 18]           ; get pointer to remainder
    mov [bx], edx

    pop bx

    mov sp, bp
    pop bp
    ret
