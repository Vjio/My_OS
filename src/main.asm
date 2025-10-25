org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start:
    jmp main

; Prints a string to the screen
; Params:
;   ds:si points to string
puts:
    ; push registers that i will modify
    push si
    push ax
    push bx
    
.loop:
    lodsb      ; loads next char in al
    or al, al   ; verify if next char is NULL
    jz .done

    ; BIOS INT 10h, interuption for writting
    mov ah, 0x0e
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret

main:

    ; setup data segmentes
    mov ax, 0
    ; can't write to ds, es dirrectly
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax          ; move stack segment
    mov sp, 0x7C00     ; move stack pointer

    ; print message
    mov si, msg_hello
    call puts

    hlt

.halt:
    jmp .halt



msg_hello: db "Hello world!", ENDL, 0

; the os will expect the last 2 bits of the first section (512 bits) of memory to be 5
times 510-($-$$) db 0
dw 0AA55h