#include "include/pm_struct.h"
int start_pos;
unsigned char gdt_ptr[6];
DESCRIPTOR gdt[GDT_SIZE];
unsigned char idt_ptr[6];
GATE idt[IDT_SIZE];
