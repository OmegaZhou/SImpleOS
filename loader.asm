
	org 0x10000

	jmp Loader_Begin
	
	%include "FAT.inc"
	
	BaseOfKernel equ 0x00
	OffsetOfKernel equ 0x100000
	
	TempBaseOfKernel equ 0x00
	TempOffsetOfKernel equ 0x7e00
	
	; Some value
	LoaderMessage db 'Start Loading'
	
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
	mov	ax,	1301h
	mov	bx,	000fh
	mov	dx,	0300h
	mov	cx,	13
	push ax
	mov	ax,	ds
	mov	es,	ax
	pop	ax
	mov	bp,	LoaderMessage
	int	10h
	jmp $