#include "keyboard.h"
#include "lib.h"
#include "i8259.h"
#define BUF_SIZE 256
char buf[BUF_SIZE];
int buf_rear;

#define BACKSPACE 0x08
#define SHIFT 0x06
static char code_map[0x50] = { 0 ,	 0 ,	'1',	'2',	'3',	'4',	'5',	'6',	'7',	'8',	'9',	'0',	'-',	'=',	BACKSPACE,	'\t',
							'q',	'w',	'e',	'r',	't',	'y',	'u',	'i',	'o',	'p',	'[',	']',	'\n',	 0 ,	'a',		's',
							'd',	'f',	'g',	'h',	'j',	'k',	'l',	';',	'\'',	'`',	SHIFT,	'\\',	'z',	'x',	'c',		'v',
							'b',	'n',	'm',	',',	'.',	'/',	SHIFT,	'*',	 0 ,	' ',	0,		0,		0,		0,		0,			0,
							0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		'-',	0,		0,		0,		'+',		0, };
static char shift_code_map[0x50] = { 0 ,	 0 ,	'!',	'@',	'#',	'$',	'%',	'^',	'&',	'*',	'(',	')',	'_',	'+',	BACKSPACE,	'\t',
									'Q',	'W',	'E',	'R',	'T',	'Y',	'U',	'I',	'O',	'P',	'{',	'}',	'\n',	 0 ,	'A',		'S',
									'D',	'F',	'G',	'H',	'J',	'K',	'L',	':',	'"',	'~',	SHIFT,	'|',	'Z',	'X',	'C',		'V',
									'B',	'N',	'M',	'<',	'>',	'?',	SHIFT,	0,		 0 ,	' ',	0,		0,		0,		0,		0,			0,
									0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		'-',	0,		0,		0,		0,			0, };
static int shift_flag;
static char temp[2];
static int flag;
void keyboadr_handler(int irq)
{
	flag = 1;
	unsigned char key=in_byte(0x60);

	if ((key^(unsigned char)0x80) < (unsigned char)0x50) {
		if (code_map[key ^ 0x80] == SHIFT) {
			--shift_flag;
		} else if (shift_flag == 0) {
			if (code_map[key ^ 0x80] == BACKSPACE) {

				if (buf_rear > 0) {
					key_back();
					--buf_rear;
				}
			} else if (code_map[key ^ 0x80] != 0) {
				judge_clean();
				temp[0] = code_map[key ^ 0x80];
				buf[buf_rear] = temp[0];
				++buf_rear;
				printf_str(temp);
			}
		} else if (shift_flag == 1) {
			if (shift_code_map[key ^ 0x80] == BACKSPACE) {
				if (buf_rear > 0) {
					key_back();
					--buf_rear;
				}
			} else if (shift_code_map[key ^ 0x80] != 0) {
				judge_clean();
				temp[0] = shift_code_map[key ^ 0x80];
				buf[buf_rear] = temp[0];
				++buf_rear;
				printf_str(temp);

			}
		}
	} else if(key< (unsigned char)0x50){
		if (code_map[key] == SHIFT) {
			++shift_flag;
		}
	}
	if (buf_rear != 0 && buf[buf_rear - 1] == '\n') {
		buf_rear = 0;
	}

}

void read_key()
{
	start_sti();
	for (;;) {
		if (flag) {
			flag = 0;
			printf_str("");
			break;
		}
	}

}

void init_keyboard()
{
	flag = 0;
	shift_flag = 0;
	buf_rear = 0;
	temp[1] = '\0';
	out_byte(INT_M_CTL_MASK, 0xfd);
	irq_table[KEYBOARD_IRQ] = keyboadr_handler;
}

