#include "lib.h"

#define INT_M_CTL 0x20
#define INT_M_CTL_MASK 0x21
#define INT_S_CTL 0xa0
#define INT_S_CTL_MASK 0xa1
#define INT_VECTOR_IRQ0 0x20
#define INT_VECTOR_IRQ8 0x28
void init_8259A()
{
	out_byte(INT_M_CTL, 0x11);
	out_byte(INT_S_CTL, 0x11);
	out_byte(INT_M_CTL_MASK, INT_VECTOR_IRQ0);
	out_byte(INT_S_CTL_MASK, INT_VECTOR_IRQ8);
	out_byte(INT_M_CTL_MASK, 0x4);
	out_byte(INT_S_CTL_MASK, 0x2);
	out_byte(INT_M_CTL_MASK, 0x1);
	out_byte(INT_S_CTL_MASK, 0x1);
	out_byte(INT_M_CTL_MASK, 0xfd);
	out_byte(INT_S_CTL_MASK, 0xff);
}

void spurious_irq(int irq)
{
	printf_str("spurious_irq: ");
	printf_int(irq);
	printf_str("\n");
}
