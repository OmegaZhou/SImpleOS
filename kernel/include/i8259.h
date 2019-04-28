#ifndef I8259_H_
#define I8259_H_

#define INT_M_CTL 0x20
#define INT_M_CTL_MASK 0x21
#define INT_S_CTL 0xa0
#define INT_S_CTL_MASK 0xa1
#define INT_VECTOR_IRQ0 0x20
#define INT_VECTOR_IRQ8 0x28

#define IRQ_SIZE 16

#define	CLOCK_IRQ	0
#define	KEYBOARD_IRQ	1
#define	CASCADE_IRQ	2	/* cascade enable for 2nd AT controller */
#define	ETHER_IRQ	3	/* default ethernet interrupt vector */
#define	SECONDARY_IRQ	3	/* RS232 interrupt vector for port 2 */
#define	RS232_IRQ	4	/* RS232 interrupt vector for port 1 */
#define	XT_WINI_IRQ	5	/* xt winchester */
#define	FLOPPY_IRQ	6	/* floppy disk */
#define	PRINTER_IRQ	7
#define	AT_WINI_IRQ	14	/* at winchester */

typedef void(*irq_handler)(int irq);

extern irq_handler irq_table[IRQ_SIZE];
extern void add_irq(irq_handler, int irq);
extern void disable_irq(int irq);
extern void enable_irq(int irq);
extern void init_8259A();
extern void spurious_irq(int irq);


#endif // !I8259_H_

