
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
	jmp $
	
	Read_Sector:			
	push bp
	mov bp, sp
	sub esp, 2				; esp allocate 2byte to save the number of 
							; sectors which will be read
	mov byte [bp-2], cl	
	push bx
	mov bl, [BPB_SecPerTrk]
	div bl					; When divisor is 8bit, dividend is ax, and then quotient
							; is saved in al, remainder is saved in ah
	inc ah
	mov cl, ah
	mov dh, al
	and dh, 1
	shr al, 1
	mov ch, al
	
	pop bx
	mov dl, [BS_DrvNum]
	Go_On_Read:				; Then use INT 13h to read sectors and if read failed,
							; and then try again
	mov ah, 2
	mov al, byte [bp-2]
	int 13h
	jc Go_On_Read
	add esp, 2
	pop bp
	ret
	
	Display_Str:
	mov ax, 1301h
	push ax
	mov ax, ds
	mov es, ax
	pop ax
	int 10h
	ret