#include "keyboard.h"
#include "lib.h"
#include "i8259.h"
#define BUF_SIZE 256
char buf[BUF_SIZE];
int buf_head;
int buf_rear;


void keyboadr_handler(int irq)
{
	char key;
	key = in_byte(0x60);
	printf_int(key);
}

void read_key()
{
	out_byte(INT_M_CTL_MASK, 0xfd);
}

void init_keyboard()
{
	buf_head = 0;
	buf_rear = 0;
	//irq_table[KEYBOARD_IRQ] = keyboadr_handler;
}

