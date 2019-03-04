
	org 0x10000

	jmp Loader_Begin
	
	%include "FAT.inc"
	
	BaseOfKernel equ 0x00
	OffsetOfKernel equ 0x100000
	
	TempBaseOfKernel equ 0x00
	TempOffsetOfKernel equ 0x7e00
	
	; Some value
	FindLoaderMessage db 'Booting successfully'
	
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
	jmp $
	
	Display_Str:
	mov ax, 1301h
	push ax
	mov ax, ds
	mov es, ax
	pop ax
	int 10h
	ret