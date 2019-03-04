

	org 0x7c00
	; Some const value
	BaseOfStack equ 0x7c00
	BaseOfLoader equ 0x1000
	OffsetOfLoader equ 0x00

	
	jmp short Boot_Start
	nop
	
	%include "FAT.inc"
	
	; Some variable
	StartMessage db 'Start Booting'
	RootDirSizeForLoop	dw	RootDirSectorsNum
	SectorNo		dw	0		
	Odd			db	0
	LoaderFileName db 'MYLOADERBIN'
	NoLoderMessage db 'Error:No Loader Found'
	
	
	Boot_Start:
	; Init stack
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BaseOfStack
	
	; Clear screen
	mov ax, 0600h
	mov bx, 0700h
	mov cx, 0000h
	mov dx, 184fh
	int 10h
	
	; Display string
	mov ax, 1301h
	mov bx, 000fh
	mov dx, 0000h
	mov cx, 13
	push ax
	mov ax, ds
	mov es, ax
	pop ax
	mov bp, StartMessage
	int 10h
	
	; Reset disk
	xor ah, ah
	xor dl, dl
	int 13h
	
	; Search loader.bin
	mov word [SectorNo], RootDirStartSectors
	
	Begin_Search:
	cmp word [RootDirSizeForLoop], 0
	jz No_Loader_Bin
	dec word [RootDirSizeForLoop]
	mov ax, 00h
	mov es, ax
	mov bx, 8000h
	mov ax, [SectorNo]
	mov cl, 1
	call Read_Sector
	mov si, LoaderFileName	; It make ds:si point to LoaderFileName
	mov di, 8000h
	cld
	mov dx, 10h				; One sector has 0x10 directory entry
	
	Search_For_Loader_Bin:
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
	mov ah, 0eh
	mov bl, 0fh
	int 10h
	inc di
	jmp Cmp_File_Name
	
	File_Different:			; Find loader.bin in next directory entry
	and di, 0ffe0h			; Reset the di to the origin address
	add di, 20h				; One directory entry is 32 byte 
							; It make es:di point next directory entry
	mov si, LoaderFileName	; Reset the si point the start of file name
	jmp Search_For_Loader_Bin 
	
	Search_Next_Sector:
	add word [SectorNo], 1
	jmp Begin_Search
	
	No_Loader_Bin:			; Fail finding loader.bin, display error
	mov ax, 1301h
	mov bx, 008ch
	mov dx, 0100h
	mov cx, 21
	push ax
	mov ax, ds
	mov es, ax
	pop ax
	mov bp, NoLoderMessage
	int 10h
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
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader
	mov ax, cx
	
	Loading_File:
	push ax
	push bx
	
	; Display '.' to gain the result like "Start booting...."
	mov ah, 0eh
	mov al, '.'
	mov bl, 0fh
	int 10h
	
	pop bx
	pop ax
	
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
	jmp BaseOfLoader:OffsetOfLoader
	
	Get_Fat_Entry:
	push es
	push bx
	
	push ax
	mov ax, BaseOfLoader	
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
	mov ch, al
	shr al, 1
	
	
	pop bx
	mov dl, [BS_DrvNum]
	Go_On_Read:				; Then use INT 13h to read sectors and if read failed,
							; and then try again
	mov ah, 2
	mov al, byte [bp-2]
	int 13h
	jnc Go_On_Read
	add esp, 2
	pop bp
	ret
	
	times 510 - ($ - $$) db 0
	dw 0xaa55
	
