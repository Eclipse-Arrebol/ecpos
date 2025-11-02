[bits 16]

LOADER_SEG      equ 0x0800      ; Stage 2加载到0x8000
LOADER_OFFSET   equ 0x0000
LOADER_SECTOR   equ 1           ; Stage 2起始扇区（紧跟MBR）
LOADER_COUNT    equ 4           ; Stage 2占用4个扇区


mov ax,3
int 0x10

mov ax,0
mov dx,ax
mov es,ax
mov ss,ax
mov sp,0x7c00

mov si,booting
call print

mov ah, 0x02                ; BIOS读取扇区功能
mov al, LOADER_COUNT        ; 读取扇区数
mov ch, 0                   ; 柱面0
mov cl, LOADER_SECTOR       ; 扇区号（从1开始，所以+1）
mov dh, 0                   ; 磁头0
mov dl, [BOOT_DRIVE]        ; 驱动器号
mov bx, LOADER_SEG          ; ES:BX = 目标地址
mov es, bx
xor bx, bx

int 0x13                    ; 调用BIOS

jc disk_error               ; CF=1表示错误

; 检查实际读取的扇区数
cmp al, LOADER_COUNT
jne disk_error

; 成功
mov si, msg_ok
call print

; 设置DL为驱动器号（Stage 2可能需要）
mov dl, [BOOT_DRIVE]

; 跳转！
jmp LOADER_SEG:LOADER_OFFSET

jmp $


disk_error:
    mov si, msg_fail
    call print
    jmp $

print:
    mov ah,0x0e
.next:
    mov al,[si]
    cmp al,0
    jz .done
    int 0x10
    inc si
    jmp .next

.done:
    ret

booting db "===Booting ecpos...====",10,13,0
BOOT_DRIVE db 0x00
msg_ok    db "LBA 1 Loaded. Jumping...", 0x0a, 0x0d, 0
msg_fail  db "DISK READ FAILED!", 0x0a, 0x0d, 0


times 510-($-$$) db 0
db 0x55,0xaa
