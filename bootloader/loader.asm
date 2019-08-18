
	org 0x0100

	jmp Loader_Begin
	
	%include "FAT.inc"
	%include "pm.inc"
	

	; GDT
	;                            段基址     段界限, 属性
	LABEL_GDT: 			Descriptor 0,            0,  0              ; 空描述符
	LABEL_DESC_FLAT_C: 	Descriptor 0,		0fffffh, DA_CR|DA_32|DA_LIMIT_4K ;0-4G
	LABEL_DESC_FLAT_RW: Descriptor 0,      	0fffffh, DA_DRW|DA_32|DA_LIMIT_4K;0-4G
	LABEL_DESC_VIDEO:   Descriptor 0B8000h, 0ffffh,  DA_DRW|DA_DPL3 ; 显存首地址

	GdtLen		equ	$ - LABEL_GDT
	GdtPtr		dw	GdtLen - 1				; 段界限
				dd	BaseOfLoaderPhyAddr + LABEL_GDT		; 基地址

	; GDT 选择子
	SelectorFlatC	equ	LABEL_DESC_FLAT_C	- LABEL_GDT
	SelectorFlatRW	equ	LABEL_DESC_FLAT_RW	- LABEL_GDT
	SelectorVideo	equ	LABEL_DESC_VIDEO	- LABEL_GDT + SA_RPL3
	
	BaseOfLoader equ 0x9000
	BaseOfStack equ 0x0100
	BaseOfKernel equ 0x8000
	OffsetOfKernel equ 0x00
	BaseOfLoaderPhyAddr equ	BaseOfLoader*10h 
	PageDirBase	equ	100000h	
	PageTblBase	equ	101000h	
	KernelEntryPointPhyAddr	equ	030400h
	BaseOfKernelFilePhyAddr	equ	BaseOfKernel * 10h
	
	
	Loader_Begin:
	; Init
	mov	ax,	cs
	mov	ds,	ax
	mov	es,	ax
	mov	ss,	ax
	mov	sp,	BaseOfStack
	
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
	
	; Get memory size
	mov	ebx, 0				; ebx = continuation value, need equal 0 firstly
	mov	di, _MemChkBuf		; es:di point to ARDS(Address Range Descriptor Structure)
	.MemChkLoop:
	mov	eax, 0E820h			; If using int 15 to get memory size, eax need equal 0e820h
	mov	ecx, 20				; Filling byte number
	mov	edx, 0534D4150h		; Flag for int 15
	int	15h			; int 15h
	jc	.MemChkFail
	add	di, 20
	inc	dword [_dwMCRNumber]	; dwMCRNumber = ARDS number
	cmp	ebx, 0
	jne	.MemChkLoop
	jmp	.MemChkOK
	
	.MemChkFail:
	mov	dword [_dwMCRNumber], 0	;Get memory size failed
	
	.MemChkOK:

	
	; Search kernel.bin
	mov word [SectorNo], RootDirStartSectors
	xor ah, ah
	xor dl, dl
	int 13h
	
	Begin_Search:
	cmp word [RootDirSizeForLoop], 0
	jz No_Kernel_Bin
	dec word [RootDirSizeForLoop]
	mov ax, BaseOfKernel
	mov es, ax
	mov bx, OffsetOfKernel
	mov ax, [SectorNo]
	mov cl, 1
	call Read_Sector
	mov si, KernelFileName	; It make ds:si point to KernelFileName
	mov di, OffsetOfKernel
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
	
	lgdt [GdtPtr]
	
	cli 
	in al, 92h
	or al, 00000010b
	out 92h, al
	
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	
	jmp dword SelectorFlatC:(BaseOfLoaderPhyAddr+PM_START)	;Jump to Protect Mode
	
	%include "bootloader_func.inc"
	
	[SECTION .s32]
	ALIGN 32
	[BITS 32]
	
	PM_START:
	mov ax, SelectorVideo
	mov gs, ax
	
	mov ax, SelectorFlatRW
	mov ds, ax
	mov	es, ax
	mov	fs, ax
	mov	ss, ax
	mov	esp, TopOfStack
	
	push	szMemChkTitle
	call	Display_Str_In_PM
	add	esp, 4
	
	call Display_Mem_Info
	call Setup_Paging
	call InitKernel
	
	jmp SelectorFlatC:KernelEntryPointPhyAddr
	
	
	
	Display_Mem_Info:
	push esi
	push edi
	push ecx
	
	mov esi, MemChkBuf
	mov ecx, [dwMCRNumber]			; for(int i=0;i<dwMCRNumber;++i){
									;
	.loop:							;	for(int j=0;j<5;++j){	
	mov edx, 5						;		Display_Int(MemChkBuf[j*4];
	mov edi, ARDStruct				;		ARDStruct[j*4]=MemChkBuf[j*4];
									;	
	.1:								;	}
	push dword [esi]				;	
	call Display_Int				;
	pop eax							;
	stosd							;
	add esi,4						;
	dec edx							;
	cmp edx,0						;
	jnz .1							;
	
	call Display_Line				;	printf("\n");
	cmp dword [dwType], 1			;	if(dwType==AddressRangeMemory){
	jne .2							;
	mov eax, [dwBaseAddrLow]		;		MemSize=BaseAddrL+LengthLow;
	add eax, [dwLengthLow]			;	}
	cmp eax, [dwMemSize]			;}
	jb .2							;
	mov [dwMemSize], eax			;
									;
	.2:								;
	loop .loop						;
	call Display_Line				; printf("\n");
	push szRAMSize					;
	call Display_Str_In_PM			; printf("RAM size:");
	add esp, 4						;
									;
	push dword [dwMemSize]			; Display_Int(MemSize);
	call Display_Int				;
	add esp, 4						;
	
	pop	ecx
	pop	edi
	pop	esi
	ret
	
	
	Setup_Paging:
	
	xor edx, edx
	mov eax, [dwMemSize]
	mov ebx, 400000h				; 4M for a page
	div ebx							; edx=MemSize%4M;
	mov ecx, eax					; eax=MemSize/4M; 
									; then ecx=eax=page number;
	test edx, edx					
	jz .no_reminder
	inc ecx							; if edx!=0;
									; ++ecx;
	.no_reminder:
	push ecx						; Save page number;
	mov ax, SelectorFlatRW
	mov es, ax
	mov edi, PageDirBase
	xor eax, eax
	mov eax, 0 | PG_P | PG_USS | PG_RWW | PG_PSE
	
	.1: 
	stosd
	add eax, 0x400000
	loop .1
	
	pop eax
	mov ebx, 1024
	mul ebx
	mov ecx, eax
	mov edi,eax
	mov edi, PageTblBase
	xor eax, eax
	mov eax, PG_P | PG_USU | PG_RWW
	
	.2:
	stosd
	add eax, 4096
	loop .2
	
	mov eax, cr4
	or eax, CR4_PSE
	mov cr4, eax

	mov	eax, PageDirBase
	mov	cr3, eax
	mov	eax, cr0
	or	eax, 80000000h
	mov	cr0, eax
	jmp	short .3
	
	.3:
	nop
	ret
	
	; 将 KERNEL.BIN 的内容经过整理对齐后放到新的位置
	; 遍历每一个 Program Header，
	; 根据 Program Header 中的信息来确定把什么放进内存，放到什么位置，以及放多少。
	InitKernel:
    xor   esi, esi
    mov   cx, word [BaseOfKernelFilePhyAddr+2Ch];`. ecx <- pELFHdr->e_phnum
    movzx ecx, cx                               ;/
    mov   esi, [BaseOfKernelFilePhyAddr + 1Ch]  ; esi <- pELFHdr->e_phoff
    add   esi, BaseOfKernelFilePhyAddr;esi<-OffsetOfKernel+pELFHdr->e_phoff
	.Begin:
    mov   eax, [esi + 0]
    cmp   eax, 0                      ; PT_NULL
    jz    .NoAction
    push  dword [esi + 010h]    ;size ;`.
    mov   eax, [esi + 04h]            ; |
    add   eax, BaseOfKernelFilePhyAddr; | memcpy((void*)(pPHdr->p_vaddr),
    push  eax		    ;src  ; |      uchCode + pPHdr->p_offset,
    push  dword [esi + 08h]     ;dst  ; |      pPHdr->p_filesz;
    call  MemCpy                      ; |
    add   esp, 12                     ;/
	.NoAction:
    add   esi, 020h                   ; esi += pELFHdr->e_phentsize
    dec   ecx
    jnz   .Begin

    ret
	
	; Copy memory
	MemCpy:
	push	ebp
	mov	ebp, esp

	push	esi
	push	edi
	push	ecx

	mov	edi, [ebp + 8]	; Destination
	mov	esi, [ebp + 12]	; Source
	mov	ecx, [ebp + 16]	; Counter
	.1:
	cmp	ecx, 0		; 判断计数器
	jz	.2		; 计数器为零时跳出

	mov	al, [ds:esi]		; ┓
	inc	esi			; ┃
					; ┣ 逐字节移动
	mov	byte [es:edi], al	; ┃
	inc	edi			; ┛

	dec	ecx		; 计数器减一
	jmp	.1		; 循环
	.2:
	mov	eax, [ebp + 8]	; 返回值

	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp

	ret			; 函数结束，返回
	
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
	
	%include "loader_func_pm.inc"
	
	[SECTION .data1]

	ALIGN	32

	LABEL_DATA:
	; 实模式下使用这些符号
	; 字符串
	_szMemChkTitle:	db "BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0
	_szRAMSize:	db "RAM size:", 0
	_szReturn:	db 0Ah, 0
	; 变量
	_dwMCRNumber:	dd 0	; Memory Check Result
	_dwMemSize:	dd 0
	_ARDStruct:	; Address Range Descriptor Structure
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:		dd	0
	_dwLengthLow:			dd	0
	_dwLengthHigh:		dd	0
	_dwType:			dd	0
	_MemChkBuf:	times	256	db	0
	_dwDispPos:	dd (80 * 6 + 0) * 2	
	;
	;; 保护模式下使用这些符号
	dwDispPos		equ	BaseOfLoaderPhyAddr + _dwDispPos
	szMemChkTitle		equ	BaseOfLoaderPhyAddr + _szMemChkTitle
	szRAMSize		equ	BaseOfLoaderPhyAddr + _szRAMSize
	szReturn		equ	BaseOfLoaderPhyAddr + _szReturn
	dwMemSize		equ	BaseOfLoaderPhyAddr + _dwMemSize
	dwMCRNumber		equ	BaseOfLoaderPhyAddr + _dwMCRNumber
	ARDStruct		equ	BaseOfLoaderPhyAddr + _ARDStruct
	dwBaseAddrLow	equ	BaseOfLoaderPhyAddr + _dwBaseAddrLow
	dwBaseAddrHigh	equ	BaseOfLoaderPhyAddr + _dwBaseAddrHigh
	dwLengthLow	equ	BaseOfLoaderPhyAddr + _dwLengthLow
	dwLengthHigh	equ	BaseOfLoaderPhyAddr + _dwLengthHigh
	dwType		equ	BaseOfLoaderPhyAddr + _dwType
	MemChkBuf		equ	BaseOfLoaderPhyAddr + _MemChkBuf


	; 堆栈就在数据段的末尾
	StackSpace:	times	1024	db	0
	TopOfStack	equ	BaseOfLoaderPhyAddr + $	; 栈顶