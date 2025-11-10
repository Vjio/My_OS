; loaded in memory here
org 0x7C00
bits 16

; just a shortcut for \n. thank you internet
%define ENDL 0x0D, 0x0A

;
; FAT12 header. taken directly for the FAT documentation
;
jmp short start
nop
	
bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number, value doesn't matter
ebr_volume_label:           db 'NANOBYTE OS'        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes

;
; code starts here
;
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
	; loads [si] into al. increments si
	lodsb
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
	mov sp, 0x7C00     ; move stack pointer so we don't overwrite

    ; read something from floppy disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                   ; LBA=1, second sector from disk
    mov cl, 1                   ; 1 sector to read
    mov bx, 0x7E00              ; data should be after the bootloader
    call disk_read

	; print message
	mov si, msg_hello
	call puts

	cli							; disable interrupts, this way CPU can't get out of "halt" state
	hlt

;
; Error handlers
;
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                     ; wait for keypress
    jmp 0FFFFh:0                ; jump to beginning of BIOS, should reboot

.halt:
	cli							; disable interrupts, this way CPU can't get out of "halt" state
	hlt

;
; Disk routines
;

;
; Converts an LBA address to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head
;

lba_to_chs:
	push ax
	push dx

	xor dx, dx
	div word [bdb_sectors_per_track]	; ax = LBA / SectorsPerTrack
										; dx = LBA % SectorsPerTrack

	inc dx								; dx = sector number = Lba % SectorsPerTrack + 1
	mov cx, dx							;

	xor dx, dx
	div word [bdb_heads]				; ax = (LBA / SectorsPerTrack) / heads = cylinder
										; dx = (LBA / SectorsPerTrack) % heads = head
	mov dh, dl							; dh = head

; CX =	     ---CH--- ---CL---
; cylinder = 76543210 98------
; sector =   -------- --543210

	mov ch, al							; ch = cylinder (lower 8 bits)
	shl ah, 6							;
	or cl, ah							; cl = higher 2 bits

	pop ax
	mov dl, al							; restore
	pop ax
	ret

;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
; We will cal int 13, with these parameters:
; 	- ah: 02
; 	- al: number of sectors to read
; 	- ch: cylinder number
; 	- cl: sector number
; 	- dh: head number
; 	- dl: drive number
; 	- es:bx: pointer to buffer
; which has these returns:
	; - ah: status
	; - al: number of sectors read
	; - cf: 0 (succes) or 1 (fail)
; read int 13 documentation if confused
disk_read:
    push ax                             ; save registers we will modify
    push bx
    push cx
    push dx
    push di

	push cx
	call lba_to_chs
	pop ax

	mov al, 2
	mov di, 3							; retry count

.retry:
	pusha								; just to be safe. dunno what registers the int will overwrite
	stc									; set carry flag
	int 13h								; carry flag cleared = succes
	jnc .done							; jump if carry not set

; read failed
	popa
	call disk_reset

	dec di
	test di, di
	jnz .retry

.fail:
; all attemps are exhausted
	jmp floppy_error

.done:
	popa

	pop di
    pop dx
    pop cx
    pop bx
    pop ax                             ; restore registers modified
    ret

;
;
;;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_hello:              db 'Hello world!', ENDL, 0
msg_read_failed:        db 'Read from disk failed!', ENDL, 0

; the bios will expect the last 2 bits of the first section (512 bits) of memory to be 5
; it just looks for this signature so that it knows it is bootable
times 510-($-$$) db 0
dw 0AA55h