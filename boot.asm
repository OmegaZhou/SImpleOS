

	org 0x7c00
	; Some const value
	BaseOfStack equ 0x7c00
	BaseOfLoader equ 0x1000
	OffsetOfLoader equ 0x00

	
	jmp short Boot_Start
	nop
	
	%include "FAT.inc"
	
	Boot_Start:
	; Init stack
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BaseOfStack
	
	; Clear screen
	mov ax, 0600h
	mov bx, 0700h
	mov cx, 0000h
	mov dx, 184fh
	int 10h
	
	; Display string
	mov dx, 0000h
	mov bx, 000fh
	mov cx, 13
	mov bp, StartMessage
	call Display_Str
	
	; Reset disk
	xor ah, ah
	xor dl, dl
	int 13h
	
	; Search loader.bin
	mov word [SectorNo], RootDirStartSectors
	
	Begin_Search:
	cmp word [RootDirSizeForLoop], 0
	jz No_Loader_Bin
	dec word [RootDirSizeForLoop]
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader
	mov ax, [SectorNo]
	mov cl, 1
	call Read_Sector
	mov si, LoaderFileName	; It make ds:si point to LoaderFileName
	mov di, OffsetOfLoader
	cld
	mov dx, 10h				; One sector has 0x10 directory entry
	
	Search_For_Loader_Bin:
	cmp dx, 0
	jz Search_Next_Sector
	dec dx
	mov cx, 11
	
	Cmp_File_Name:			; Judge whether find loader.bin
	cmp cx, 0
	jz Find_File
	dec cx
	lodsb					; ds:si->al, and then si point to next byte
							; the moving direction set by CLD instruction 
	cmp al, byte [es:di]
	jz Go_On
	jmp File_Different
	
	Go_On:					; Continue comparing file name
	inc di
	jmp Cmp_File_Name
	
	File_Different:			; Find loader.bin in next directory entry
	and di, 0ffe0h			; Reset the di to the origin address
	add di, 20h				; One directory entry is 32 byte 
							; It make es:di point next directory entry
	mov si, LoaderFileName	; Reset the si point the start of file name
	jmp Search_For_Loader_Bin 
	
	Search_Next_Sector:
	add word [SectorNo], 1
	jmp Begin_Search
	
	No_Loader_Bin:			; Fail finding loader.bin, display error
	mov bx, 008ch
	mov dx, 0100h
	mov cx, 21
	mov bp, NoLoderMessage
	call Display_Str
	jmp $
	
	Find_File:
	
	mov ax, RootDirSectorsNum
	and di, 0ffe0h			; Reset the di to the origin address
	add di, 1ah				; es:[di+1ah] is DIR_FstClus, point to 
							; the first cluster in the data area
	mov cx, word [es:di]	
	push cx					; Push cluster NO into stack 
	add cx, ax				; Calculate the sector NO of the data
	add cx, SectorsBanlance	; Use formula: Data_sector_start_NO = 
							; SectorsBanlance(RootDirStartSectors-2) +
							; RootDirSectorsNum
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader
	mov ax, cx
	
	Loading_File:
	
	push ax
	push bx
	mov	ah,	0eh
	mov	al,	'.'
	mov	bl,	0fh
	int	10h
	pop	bx
	pop	ax
	
	mov cl, 1
	call Read_Sector		; Read sector from data area
	pop ax
	call Get_Fat_Entry
	
	cmp ax, 0fffh
	jz File_Loaded
	push ax
	mov dx, RootDirSectorsNum
	add ax, dx
	add ax, SectorsBanlance
	add bx, [BPB_BytesPerSec]
	jmp Loading_File
	
	File_Loaded:
	jmp BaseOfLoader:OffsetOfLoader
	
	Get_Fat_Entry:
	push es
	push bx
	
	push ax
	mov ax, BaseOfLoader	
	sub ax, 0100h			; Allocate 4kb to save FAT
	mov es, ax
	pop ax					; Now ax save the cluster NO in data area
	
	mov byte [Odd], 0
	mov bx, 3				; 
	mul bx					; These code is used to judge
	mov bx, 2				; ax*1.5 is even number or not
	div bx					; ax*1.5 is the byte number of the FAT12
	cmp dx, 0				;
	jz Is_Even
	mov byte [Odd], 1
	
	Is_Even:
	xor dx, dx
	mov bx, [BPB_BytesPerSec]
	div bx					; After division, ax is the sector NO in the FAT area
							; dx is the byte NO to the sector
	push dx
	mov bx, 0
	add ax, FAT1StartSectors; Now ax is the number of sectors that 
							; the FAT entry starting byte is in the sector 
	mov cl, 2
	call Read_Sector		; Read two sector to avoid the FAT entry over two sectors
	
	pop dx
	mov bx, dx
	mov ax, [es:bx]			
	cmp byte [Odd], 1
	jnz Even_2
	shr ax, 4				; If the byte number is odd, 
							; ax need to be ax>>4 to get the right vale
	
	Even_2:
	and ax, 0fffh			; Set the first 4bit of ax by 0 
	
	Get_Fat_Entry_Ready:
	pop bx
	pop es
	ret
	
	%include 'bootloader_func.inc'
	
	; Some variable
	StartMessage db 'Start Booting'
	RootDirSizeForLoop	dw	RootDirSectorsNum
	SectorNo		dw	0		
	Odd			db	0
	LoaderFileName db 'LOADER  BIN'
	NoLoderMessage db 'Error:No Loader Found'
	
	
	times 510 - ($ - $$) db 0
	dw 0xaa55
	
