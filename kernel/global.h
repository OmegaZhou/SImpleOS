#ifndef GLOBAL_H_
#define FLOBAL_H_
#include "pm_struct.h"

#define	PRIVILEGE_KRNL	0
#define	PRIVILEGE_TASK	1
#define	PRIVILEGE_USER	3
#define MAX_LENGTH 80
#define MAX_HEIGHTH 24
extern int start_pos;
extern unsigned char gdt_ptr[6];
extern DESCRIPTOR gdt[GDT_SIZE];
extern unsigned char idt_ptr[6];
extern GATE idt[IDT_SIZE];

#endif // !GLOBAL_H_

