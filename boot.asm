

	org 0x7c00
	; Some const value
	BaseOfStack equ 0x7c00
	BaseOfLoader equ 0x1000
	OffSetOfLoader equ 0x00
	RootDirSectors equ 14
	RootDirStartSectors equ 19
	FAT1StartSectors equ 1
	SectorsBanlance equ 17
	
	jmp short Boot_Start
	nop
	
	; The information of disk
	BS_OEMName db 'ZYDboot'
	BPB_BytesPerSec dw 512
	BPB_SecPerClus db 1
	BPB_RsvdSecCnt dw 1
	BPB_NumFATs db 2
	BPB_RootEntCnt dw 224
	BPB_TotSec16 dw 2880
	BPB_Media db 0xF0
	BPB_FATSz16	dw 9		
	BPB_SecPerTrk dw 18		
	BPB_NumHeads dw 2		
	BPB_HiddSec	dd 0	
	BPB_TotSec32 dd 0		
	BS_DrvNum db 0		
	BS_Reserved1 db 0		
	BS_BootSig db 29h		
	BS_VolID dd 0		
	BS_VolLab db 'Boot Loader'
	BS_FileSysType db 'FAT12   '
	
	; Some variable
	StartMessage db 'Start Booting'
	RootDirSizeForLoop	dw	RootDirSectors
	SectorNo		dw	0		
	Odd			db	0
	LoaderFileName db 'Loader.bin'
	NoLoderMessage db 'Error:No Loader Found'
	
	
	Boot_Start:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BaseOfStack
	
	mov ax, 0600h
	mov bx, 0700h
	mov cx, 0
	mov dx, 0184fh
	int 10h
	
	mov ax, 1301h
	mov bx, 000fh
	mov dx, 0000h
	mov cx, 13
	push ax
	mov ax, ds
	mov es, ax
	pop ax
	mov bp, StartMessage
	int 10h
	
	xor ah, ah
	xor dl, dl
	int 13h
	
	; Search loader.bin
	mov word [SectorNo], RootDirStartSectors
	
	Begin_Search:
	cmp word [RootDirSizeForLoop], 0
	jz No_Loader_Bin
	dec word [RootDirSizeForLoop]
	mov ax, 00h
	mov es, ax
	mov bx, 8000h
	mov ax, [SectorNo]
	mov cl, 1
	call Read_Sector
	mov si, LoaderFileName
	mov di, 8000h
	cld
	mov dx, 10h
	
	Search_For_Loader_Bin:
	cmp dx, 0
	jz Search_Next_Sector
	dec dx
	mov cx, 11
	
	Cmp_File_Name:			; Judge whether find loader.bin
	cmp cx, 0
	jz Find_File
	dec cx
	lodsb
	cmp al, byte [es:di]
	jz Go_On
	jmp File_Different
	
	Go_On:					; Continue comparing file name
	inc di
	jmp Cmp_File_Name
	
	File_Different:			; Find loader.bin in next sector
	and di, 0ffe0h
	add di, 20h
	mov si, LoaderFileName
	jmp Search_For_Loader_Bin 
	
	Search_Next_Sector:
	add word [SectorNo], 1
	jmp Begin_Search
	
	No_Loader_Bin:			; Fail finding loader.bin, throw error
	mov ax, 1301h
	mov bx, 008ch
	mov dx, 0100h
	mov cx, 21
	push ax
	mov ax, ds
	mov es, ax
	pop ax
	mov bp, NoLoderMessage
	int 10h
	jmp $
	
	Find_File:
	jmp $
	
	Read_Sector:			;The function is used to read sector
	push bp
	mov bp, sp
	sub esp, 2
	mov byte [bp-2], cl
	push bx
	mov bl, [BPB_SecPerTrk]
	div bl
	inc ah
	mov cl, ah
	mov dh, al
	shr al, 1
	mov ch, al
	and dh, 1
	pop bx
	mov dl, [BS_DrvNum]
	Go_On_Read:				; Then use INT to read sectors
	mov ah, 2
	mov al, byte [bp-2]
	jc Go_On_Read
	add esp, 2
	pop bp
	ret
	
	times 510 - ($ - $$) db 0
	dw 0xaa55
	
