#include "include/lib.h"
#include "include/i8259.h"

irq_handler irq_table[IRQ_SIZE];

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
	out_byte(INT_M_CTL_MASK, 0xff);
	out_byte(INT_S_CTL_MASK, 0xff);
	for (int i = 0; i < IRQ_SIZE; ++i) {
		irq_table[i] = spurious_irq;
	}
}

void spurious_irq(int irq)
{
	printf_str("spurious_irq: ");
	printf_int(irq);
	printf_str("\n");
}

void add_irq(irq_handler handler, int irq)
{
	irq_table[irq] = handler;
}
void disable_irq(int irq)
{
	unsigned char mask = (1 << (irq % 8));
	if (irq < 8) {
		mask |= in_byte(INT_M_CTL_MASK);
		out_byte(INT_M_CTL_MASK, mask);
	} else {
		mask |= in_byte(INT_S_CTL_MASK);
		out_byte(INT_S_CTL_MASK, mask);
	}
}
void enable_irq(int irq)
{
	unsigned char mask = ~(1 << (irq % 8));
	if (irq < 8) {
		mask &= in_byte(INT_M_CTL_MASK);
		out_byte(INT_M_CTL_MASK, mask);
		
	} else {
		mask &= in_byte(INT_S_CTL_MASK);
		out_byte(INT_S_CTL_MASK, mask);
	}
}