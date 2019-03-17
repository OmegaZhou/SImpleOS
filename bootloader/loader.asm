
	org 0x10000

	jmp Loader_Begin
	
	%include "FAT.inc"
	
	BaseOfKernel equ 0x00
	OffsetOfKernel equ 0x100000
	
	TempBaseOfKernel equ 0x00
	TempOffsetOfKernel equ 0x7e00
	MemStructBuf equ 0x7e00
	
	[SECTION gdt]

	LABEL_GDT dd 0,0
	LABEL_DESC_CODE32 dd 0x0000FFFF,0x00CF9A00
	LABEL_DESC_DATA32 dd 0x0000FFFF,0x00CF9200

	GdtLen equ $ - LABEL_GDT
	GdtPtr dw GdtLen - 1
	dd LABEL_GDT

	SelectorCode32 equ LABEL_DESC_CODE32 - LABEL_GDT
	SelectorData32 equ LABEL_DESC_DATA32 - LABEL_GDT

	[SECTION gdt64]

	LABEL_GDT64 dq 0x0000000000000000
	LABEL_DESC_CODE64 dq 0x0020980000000000
	LABEL_DESC_DATA64 dq 0x0000920000000000

	GdtLen64 equ $ - LABEL_GDT64
	GdtPtr64 dw GdtLen64 - 1
	dd LABEL_GDT64

	SelectorCode64 equ LABEL_DESC_CODE64 - LABEL_GDT64
	SelectorData64 equ LABEL_DESC_DATA64 - LABEL_GDT64

	
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
	mov cx, 21
	mov bx, 000fh
	mov bp, FindLoaderMessage
	call Display_Str
	
	mov dx, 0300h
	mov cx, 14
	mov bx, 000fh
	mov bp, LoadMessage
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
	
	Search_For_Kernel_Bin:
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
	jmp Search_For_Kernel_Bin
	
	Search_Next_Sector:
	add word [SectorNo], 1
	jmp Begin_Search
	
	No_Kernel_Bin:			; Fail finding loader.bin, display error
	mov bx, 008ch
	mov dx, 0400h
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
	mov eax, TempBaseOfKernel
	mov es, eax
	mov bx, TempOffsetOfKernel
	mov ax, cx
	
	Loading_File:
	
	call Display_Period
	
	mov cl, 1
	call Read_Sector		; Read sector from data area
	pop ax
	
	push cx 
	push eax
	push fs
	push edi
	push ds
	push esi
	
	mov cx, 0200h			; Use cx to control loop
							; Move 512 byte from temp memory to 
							; the memory where the kernel running
	mov ax, BaseOfKernel
	mov fs, ax
	; The NewOffsetOfKernel is means the OffsetOfKernel after
	; moving some sections of kernel
	mov edi, dword [NewOffsetOfKernel]
	
	mov ax, TempBaseOfKernel
	mov ds, ax
	mov esi, TempOffsetOfKernel
	
	Move_Kernel:
	mov al, byte [ds:esi]
	mov byte [fs:edi], al
	inc esi
	inc edi
	loop Move_Kernel
	
	mov eax, 0x1000
	mov ds, eax
	; Update the NewOffsetOfKernel
	mov dword [NewOffsetOfKernel], edi
	pop esi
	pop ds
	pop edi
	pop fs
	pop eax
	pop cx
	
	
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
	mov dx, 0500h
	mov cx, 25
	mov bx, 000fh
	mov bp, SuccessLoadMessage
	call Display_Str
	
	Close_Motor:
	push dx
	mov dx, 03f2h
	mov al, 0
	out dx, al
	pop dx
	
	; Save the memory information to the MemStructBuf
	Start_Get_Mem_Struct:
	mov dx, 0700h
	mov cx, 24
	mov bx, 000fh
	mov bp, GetMemMessage
	call Display_Str
	
	mov ebx, 0
	mov ax, 0x00
	mov es, ax
	mov di, MemStructBuf
	
	Get_Mem_Struct:
	mov eax, 0x0e820
	mov ecx, 20
	mov edx, 0x534d4150
	int 15h
	jc Get_Mem_Struct_Fail
	add di, 20
	cmp ebx, 0
	jne Get_Mem_Struct
	jmp Get_Mem_OK
	
	Get_Mem_Struct_Fail:
	mov dx, 0800h
	mov cx, 25
	mov bx, 008ch
	mov bp, GetMemFailMessage
	call Display_Str
	jmp $
	
	Get_Mem_OK:
	mov dx, 0800h
	mov cx, 31
	mov bx, 000fh
	mov bp, GetMemSuccessMessage
	call Display_Str
	
	jmp Init_IDT_GDT
	
	; These codes section is used to set resolution ratio
	; And now these codes is jumped
	Set_SVGA_Mode:
	mov ax, 4f02h
	mov bx, 4180h
	int 10h
	
	Init_IDT_GDT:
	; Enter protect mode
	cli 					; Close interrupt
	
	db 0x66
	lgdt [GdtPtr]
	
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	
	jmp dword SelectorCode32:Go_To_Tmp_Protect
	
	[SECTION .s32]
	[BITS 32]
	
	Go_To_Tmp_Protect:
	
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov esp, 7e00h
	
	call Support_Long_Mode
	test eax, eax
	
	jz No_Support
	
	; Init temp page table
	mov dword [0x90000], 0x91007
	mov	dword [0x90800], 0x91007		

	mov	dword [0x91000], 0x92007

	mov	dword [0x92000], 0x000083

	mov	dword [0x92008], 0x200083

	mov	dword [0x92010], 0x400083

	mov	dword [0x92018], 0x600083

	mov	dword [0x92020], 0x800083

	mov	dword [0x92028], 0xa00083
	
	; Load GDTR
	db 0x66
	lgdt [GdtPtr64]
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	
	mov esp, 7e00h
	
	; Open PAE
	mov eax, cr4
	bts eax, 5
	mov cr4, eax
	
	mov eax, 0x90000
	mov cr3, eax
	
	mov ecx, 0C0000080h
	rdmsr
	
	bts eax, 8
	wrmsr
	
	mov eax, cr0
	bts eax, 0
	bts eax, 31
	mov cr0, eax
	
	jmp SelectorCode64:OffsetOfKernel
	
	
	Support_Long_Mode:			; Judge whether support IA-32e mode
	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000001
	setnb al
	jb Support_Long_Mode_Done
	mov eax, 0x80000001
	cpuid
	bt edx, 29
	setc al
	
	Support_Long_Mode_Done:
	movzx eax, al
	ret
	
	No_Support:
	
	jmp $
	
	
	[SECTION .s16lib]
	[BITS 16]
	
	; Display the value of AL to the screen
	Display_AL:
	push ecx
	push edx
	push edi
	
	mov edi, [DisplayPosition]
	mov ah, 0fh				; Set the color
	mov dl, al				; Save the low 4bits of the al
	shr al, 4				; Set high 4bits to the al
	mov ecx, 2				; al saved two number, so loop 2 times
	
	.begin:
	and al, 0fh
	cmp al, 9
	ja .1
	add al, '0'
	jmp .2
	
	; If value > 9
	.1:
	sub al, 0ah
	add al, 'A'
	
	; Display value
	.2:
	mov [gs:edi], ax
	add edi, 2
	mov al, dl				; Set high 4bits to the al
	loop .begin
	
	mov [DisplayPosition], edi
	
	pop edi
	pop edx
	pop ecx
	
	ret
	
	
	jmp $
	
	%include 'bootloader_func.inc'
	
	; Some value
	NewOffsetOfKernel dd OffsetOfKernel
	FindLoaderMessage db 'Booting successfully!'
	KernelFileName db 'KERNEL  BIN'
	
	LoadMessage db 'Loading Kernel'
	SuccessLoadMessage db 'Load Kernel Successfully!'
	NoKernelMessage db 'ERROR: NO KERNEL'
	
	GetMemMessage db 'Start Get Memory Struct.'
	GetMemSuccessMessage db 'Get Memory Struct Successfully!'
	GetMemFailMessage db 'Get Memory Struct Failed!'
	
	SetSVGAModeFailMessage db 'Set SVGA Mode Failed!'
	
	SectorNo dw 0
	RootDirSizeForLoop	dw	RootDirSectorsNum
	DisplayPosition dd 0