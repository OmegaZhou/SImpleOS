	
	extern start_pos

	global memcpy
	global printf_color_str_origin
	global out_byte
	global in_byte
	global start_int
	global close_int
	global get_port_value

	[SECTION .text]
	; void* memcpy(void* es:pDest, void* ds:pSrc, int iSize);
	memcpy:
	push	ebp
	mov	ebp, esp

	push	esi
	push	edi
	push	ecx

	mov	edi, [ebp + 8]	; Destination
	mov	esi, [ebp + 12]	; Source
	mov	ecx, [ebp + 16]	; Size of memory
	
	; Copy by byte
	.memcpy1:
	cmp	ecx, 0		
	jz	.memcpy2		

	mov	al, [ds:esi]		
	inc	esi			
					
	mov	byte [es:edi], al	
	inc	edi			

	dec	ecx		
	jmp	.memcpy1		
	.memcpy2:
	mov	eax, [ebp + 8]	

	pop	ecx
	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp

	ret			
	
	; void printf_str(char* info,int color)
	printf_color_str_origin:
	push	ebp
	mov	ebp, esp

	mov	esi, [ebp + 8]	; pszInfo
	mov	edi, [start_pos]
	mov	ah, [ebp + 12]	; color
	.printf_str1:
	lodsb
	test	al, al
	jz	.printf_str2
	cmp	al, 0Ah	
	jnz	.printf_str3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.printf_str1
	.printf_str3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.printf_str1

	.printf_str2:
	mov	[start_pos], edi
	call set_cursor_by_start_pos
	pop	ebp
	ret
	
	; void out_byte(unsigned short port_num,unsigned char value)
	out_byte:
	mov edx, [esp + 4] ; edx=port_num
	mov al, [esp + 8]
	out dx, al
	nop
	nop
	ret
	
	; void in_byte(unsigned short port_num)
	in_byte:
	mov edx, [esp + 4]
	xor eax, eax
	in al, dx
	nop
	nop
	ret
	
	start_int:
	sti
	ret

	close_int:
	cli
	ret

	set_cursor_by_start_pos:
	mov ebx, [start_pos]
	shr ebx, 1

	mov dx, 03d4h
	mov al, 0eh
	out dx, al
	inc dx
	mov al, bh
	out dx, al

	dec dx
	mov al, 0fh
	out dx, al
	inc dx
	mov al, bl
	out dx, al
	ret

	;unsigned short get_port_value(unsigned short port, unsigned char high, unsigned char low)
	get_port_value:
	mov dx, [esp + 4]
	mov al, [esp + 8]
	out dx, al
	inc dx
	in al, dx
	mov bh, al

	dec dx
	mov al, [esp + 12]
	out dx, al
	inc dx
	in al, dx
	mov bl, al

	mov ax, bx
	ret
