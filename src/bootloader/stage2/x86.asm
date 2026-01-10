bits 16

section _ENTRY class=TEXT

global _x86_Video_WriteCharTeletype

;
; int 10h ah=0Eh
; args: character, page
;
_x86_Video_WriteCharTeletype:
    ; make new stack frame
    push bp
    mov bp, sp

    push bx                         ; save bx

    ; [bp + 0] - old call frame
    ; [bp + 2] - return address (small memory model => 2 bytes)
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
