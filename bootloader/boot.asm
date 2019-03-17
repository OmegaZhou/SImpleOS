

	org 0x7c00
	; Some const value
	BaseOfStack equ 0x7c00
	BaseOfLoader equ 0x9000
	OffsetOfLoader equ 0x0100

	
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
	
	call Display_Period
	
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
	
	
	%include 'bootloader_func.inc'
	
	; Some variable
	StartMessage db 'Start Booting'
	RootDirSizeForLoop dw RootDirSectorsNum
	SectorNo dw 0		
	LoaderFileName db 'LOADER  BIN'
	NoLoderMessage db 'Error:No Loader Found'
	
	
	times 510 - ($ - $$) db 0
	dw 0xaa55
	
