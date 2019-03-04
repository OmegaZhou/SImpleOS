	
	RootDirSectorsNum equ 14
	RootDirStartSectors equ 19
	FAT1StartSectors equ 1
	SectorsBanlance equ 17
	
	; The information of disk
	BS_OEMName db 'ZYDboot '
	BPB_BytesPerSec dw 512
	BPB_SecPerClus db 1
	BPB_RsvdSecCnt dw 1
	BPB_NumFATs db 2
	BPB_RootEntCnt dw 224
	BPB_TotSec16 dw 2880
	BPB_Media db 0xF0
	BPB_FATSz16	dw 9		
	BPB_SecPerTrk dw 18		
	BPB_NumHeads dw 2		
	BPB_HiddSec	dd 0	
	BPB_TotSec32 dd 0		
	BS_DrvNum db 0		
	BS_Reserved1 db 0		
	BS_BootSig db 29h		
	BS_VolID dd 0		
	BS_VolLab db 'Boot Loader'
	BS_FileSysType db 'FAT12   '