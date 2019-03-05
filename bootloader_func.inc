	
	
	; Use INT 13h AH=02H to read sectors
	; parameter:
	; dl = Driver number	
	; al = The number of the number of sectors which will be read
	; ch = Track number
	; cl = Starting sectors number
	; dh = Magnetic head number
	; result:
	; Save sectors data to es:bx
	
	; The formula to get these information
	; Use sectors number read/SecPerTrk
	; Starting sectors number=remainder+1
	; Magnetic head number=quotient&1
	; Track number=quotient>>1
	
	; The function is used to read sector
	; ax is used to save sectors NO
	; cl save the number of sectors which will be read
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
	