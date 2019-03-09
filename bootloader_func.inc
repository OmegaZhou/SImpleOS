	
	
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
	
	Display_Period:
	push ax
	push bx
	mov	ah,	0eh
	mov	al,	'.'
	mov	bl,	0fh
	int	10h
	pop	bx
	pop	ax
	ret
	
	Odd db 0
	
	Get_Fat_Entry:
	
	push es
	push bx
	
	push ax
	mov ax, 8000h	
	sub ax, 0100h			; Allocate 4kb to save FAT
	mov es, ax
	pop ax					; Now ax save the cluster NO in data area
	
	mov byte [Odd], 0
	mov bx, 3				; 
	mul bx					; These code is used to judge
	mov bx, 2				; ax*1.5 is even number or not
	div bx					; ax*1.5 is the byte number of the FAT12
	cmp dx, 0				;
	jz Is_Even
	mov byte [Odd], 1
	
	Is_Even:
	xor dx, dx
	mov bx, [BPB_BytesPerSec]
	div bx					; After division, ax is the sector NO in the FAT area
							; dx is the byte NO to the sector
	push dx
	mov bx, 0
	add ax, FAT1StartSectors; Now ax is the number of sectors that 
							; the FAT entry starting byte is in the sector 
	mov cl, 2
	call Read_Sector		; Read two sector to avoid the FAT entry over two sectors
	
	pop dx
	mov bx, dx
	mov ax, [es:bx]			
	cmp byte [Odd], 1
	jnz Even_2
	shr ax, 4				; If the byte number is odd, 
							; ax need to be ax>>4 to get the right vale
	
	Even_2:
	and ax, 0fffh			; Set the first 4bit of ax by 0 
	
	Get_Fat_Entry_Ready:
	pop bx
	pop es
	ret