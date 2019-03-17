	; Display the value of AL to the screen
	Display_AL:
	push ecx
	push edx
	push edi
	
	mov edi, [dwDispPos]
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
	
	mov [dwDispPos], edi
	
	pop edi
	pop edx
	pop ecx
	
	ret
	
	Display_Str_In_PM:
	push	ebp
	mov	ebp, esp
	push	ebx
	push	esi
	push	edi

	mov	esi, [ebp + 8]	; pszInfo
	mov	edi, [dwDispPos]
	mov	ah, 0Fh
	.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah			; Judge whether is '\n'
	jnz	.3
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
	jmp	.1
	.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

	.2:
	mov	[dwDispPos], edi

	pop	edi
	pop	esi
	pop	ebx
	pop	ebp
	ret
	
	Display_Line:
	push	szReturn
	call	Display_Str_In_PM		;printf("\n");
	add	esp, 4
	ret
	
	Display_Int:
	mov	eax, [esp + 4]
	shr	eax, 24
	call	Display_AL

	mov	eax, [esp + 4]
	shr	eax, 16
	call	Display_AL

	mov	eax, [esp + 4]
	shr	eax, 8
	call	Display_AL

	mov	eax, [esp + 4]
	call	Display_AL

	mov	ah, 07h						; 0000b: bg:black    0111b: text:white
	mov	al, 'h'
	push	edi
	mov	edi, [dwDispPos]
	mov	[gs:edi], ax
	add	edi, 4
	mov	[dwDispPos], edi
	pop	edi

	ret