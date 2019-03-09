
	org 0x10000

	jmp Loader_Begin
	
	%include "FAT.inc"
	
	BaseOfKernel equ 0x00
	OffsetOfKernel equ 0x100000
	
	TempBaseOfKernel equ 0x00
	TempOffsetOfKernel equ 0x7e00
	
	[SECTION gdt]

	LABEL_GDT dd 0,0
	LABEL_DESC_CODE32 dd 0x0000FFFF,0x00CF9A00
	LABEL_DESC_DATA32 dd 0x0000FFFF,0x00CF9200

	GdtLen equ $ - LABEL_GDT
	GdtPtr dw GdtLen - 1
	dd LABEL_GDT

	SelectorCode32 equ LABEL_DESC_CODE32 - LABEL_GDT
	SelectorData32 equ LABEL_DESC_DATA32 - LABEL_GDT

	
	; Some value
	FindLoaderMessage db 'Booting successfully'
	KernelFileName db 'Kernel  bin'
	LoadMessage db 'Loading Kernel'
	NoKernelMessage db 'ERROR: NO KERNEL'
	SectorNo dw 0
	RootDirSizeForLoop	dw	RootDirSectorsNum
	
	[SECTION .s16]
	[BITS 16]
	
	Loader_Begin:
	; Init
	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ax,	0x00
	mov	ss,	ax
	mov	sp,	0x7c00
	
	; Display string
	mov dx, 0100h
	mov cx, 20
	mov bx, 000fh
	mov bp, FindLoaderMessage
	call Display_Str
	
	
	; Open A20 function
	push ax
	in al, 92h					; Load 0x92 port of I/O
	or al, 02h					; Start A20 through set 0x92 port (Fast Gate A20)
	out 92h, al
	
	cli
	
	db 0x66
	lgdt [GdtPtr]
	
	mov eax, cr0				;
	or eax, 1					; Start Protected Mode
	mov cr0, eax				;
	
	mov ax, SelectorData32		; Make 4GB addressing ability
	mov fs, ax					;
	
	mov eax, cr0				; 
	and al, 0feh				; Quit Protected Mode
	mov cr0, eax				;
	
	sti
	
	; Search kernel.bin
	mov word [SectorNo], RootDirStartSectors
	
	Begin_Search:
	cmp word [RootDirSizeForLoop], 0
	jz No_Kernel_Bin
	dec word [RootDirSizeForLoop]
	mov ax, TempBaseOfKernel
	mov es, ax
	mov bx, TempOffsetOfKernel
	mov ax, [SectorNo]
	mov cl, 1
	call Read_Sector
	mov si, KernelFileName	; It make ds:si point to KernelFileName
	mov di, TempOffsetOfKernel
	cld
	mov dx, 10h				; One sector has 0x10 directory entry
	
	Search_For_Kernal_Bin:
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
	mov si, KernelFileName	; Reset the si point the start of file name
	jmp Search_For_Kernal_Bin
	
	Search_Next_Sector:
	add word [SectorNo], 1
	jmp Begin_Search
	
	No_Kernel_Bin:			; Fail finding loader.bin, display error
	mov bx, 008ch
	mov dx, 0200h
	mov cx, 16
	mov bp, NoKernelMessage
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
	mov ax, BaseOfKernel
	mov es, ax
	mov bx, OffsetOfKernel
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
	jmp BaseOfKernel:OffsetOfKernel
	
	%include 'bootloader_func.inc'