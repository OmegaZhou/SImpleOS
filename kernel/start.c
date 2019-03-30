#include "pm_struct.h"
#include "lib.h"
#include "global.h"


void cstart()
{
	start_pos = (80 * 15 + 0) * 2;
	printf_str("cstart_begin\n");
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
	printf_str("cstart_end\n");
}