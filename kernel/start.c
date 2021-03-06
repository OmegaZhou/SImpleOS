#include "include/pm_struct.h"
#include "include/lib.h"
#include "include/global.h"


void cstart()
{
	start_pos = (MAX_LENGTH * 15 + 0) * 2;
	memcpy(&gdt, (void*)(*((unsigned int*)(&gdt_ptr[2]))), *(unsigned short*)(&gdt_ptr[0]));
	unsigned short* p_gdt_limit = (unsigned short*)(&gdt_ptr[0]);
	unsigned int* p_gdt_base = (unsigned int*)(&gdt_ptr[2]);
	*p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
	*p_gdt_base = (unsigned int)&gdt;

	unsigned short* p_idt_limit = (unsigned short*)(&idt_ptr[0]);
	unsigned int* p_idt_base = (unsigned int*)(&idt_ptr[2]);
	*p_idt_limit = IDT_SIZE * sizeof(GATE) - 1;
	*p_idt_base = (unsigned int)&idt;

	init_port();
}