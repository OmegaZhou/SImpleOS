#include "include/lib.h"
#include "include/i8259.h"
#include "include/CRT_control.h"
#include "include/keyboard.h"

char buf[BUF_SIZE];
int buf_rear;
static char code_map[0x60] = { 0 ,	 0 ,	'1',	'2',	'3',	'4',	'5',	'6',	'7',	'8',	'9',	'0',	'-',	'=',	BACKSPACE,	'\t',
							'q',	'w',	'e',	'r',	't',	'y',	'u',	'i',	'o',	'p',	'[',	']',	'\n',	 0 ,	'a',		's',
							'd',	'f',	'g',	'h',	'j',	'k',	'l',	';',	'\'',	'`',	SHIFT,	'\\',	'z',	'x',	'c',		'v',
							'b',	'n',	'm',	',',	'.',	'/',	SHIFT,	'*',	 0 ,	' ',	0,		0,		0,		0,		0,			0,
							0,		0,		0,		0,		0,		0,		0,		'7',	'8',	'9',	'-',	'4',	'5',	'6',	'+',		'1',
							'2',	'3',	'0',	'.',	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,			0};
static char shift_code_map[0x60] = { 0 ,	 0 ,	'!',	'@',	'#',	'$',	'%',	'^',	'&',	'*',	'(',	')',	'_',	'+',	BACKSPACE,	'\t',
									'Q',	'W',	'E',	'R',	'T',	'Y',	'U',	'I',	'O',	'P',	'{',	'}',	'\n',	 0 ,	'A',		'S',
									'D',	'F',	'G',	'H',	'J',	'K',	'L',	':',	'"',	'~',	SHIFT,	'|',	'Z',	'X',	'C',		'V',
									'B',	'N',	'M',	'<',	'>',	'?',	SHIFT,	0,		 0 ,	' ',	0,		0,		0,		0,		0,			0,
									0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		'-',	0,		0,		0,		0,			0, 
									0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,			0 };
static int shift_flag;
static char temp[2];
static int flag;
static int e0_flag;

void keyboadr_handler(int irq)
{
	flag = 1;
	unsigned char key=in_byte(0x60);
	//printf_int(key);
	if (key == 0xe0) {
		e0_flag = 1;
		return;
	}
	if (e0_flag == 1) {
		if (key == 0xB5) {
			printf_str("/");
		}
		e0_flag = 0;
		return;
	}
	if ((key^0x80) <0x60) {
		if (code_map[key ^ 0x80] == SHIFT) {
			--shift_flag;
		} else if (shift_flag == 0) {
			if (code_map[key ^ 0x80] == BACKSPACE) {
				if (buf_rear > 0) {
					if (buf[buf_rear - 1] == '\t') {
						for (int i = 0; i < 4; ++i) {
							key_back();
						}
					} else {
						key_back();
					}
					
					--buf_rear;
				}
			} else if (code_map[key ^ 0x80] != 0) {
				temp[0] = code_map[key ^ 0x80];
				buf[buf_rear] = temp[0];
				++buf_rear;
				if (temp[0] == '\t') {
					printf_str("    ");
				} else {
					printf_str(temp);
				}
			}
		} else if (shift_flag == 1) {
			if (shift_code_map[key ^ 0x80] == BACKSPACE) {
				if (buf_rear > 0) {
					if (buf[buf_rear - 1] == '\t') {
						for (int i = 0; i < 4; ++i) {
							key_back();
						}
					} else {
						key_back();
					}
					--buf_rear;
				}
			} else if (shift_code_map[key ^ 0x80] != 0) {
				temp[0] = shift_code_map[key ^ 0x80];
				buf[buf_rear] = temp[0];
				++buf_rear;
				if (temp[0] == '\t') {
					printf_str("    ");
				} else {
					printf_str(temp);
				}

			}
		}
	} else if(key< 0x60){
		if (code_map[key] == SHIFT) {
			++shift_flag;
		}
	}
	

}

void init_keyboard()
{
	e0_flag = 0;
	flag = 0;
	shift_flag = 0;
	buf_rear = 0;
	temp[1] = '\0';
	add_irq(keyboadr_handler, KEYBOARD_IRQ);
}

void clear_buf()
{
	buf_rear = 0;
}

char read_key()
{
	enable_irq(KEYBOARD_IRQ);
	start_int();
	for (;;) {
		if (flag) {
			flag = 0;
			printf_str("");
			break;
		}
	}
	disable_irq(KEYBOARD_IRQ);
	if (buf_rear != 0) {
		return buf[buf_rear - 1];
	} else {
		return 0;
	}
}

int readline(char *re)
{
	char c;
	while ((c = read_key()) != '\n'){
		;
	}
	for (int i = 0; i < buf_rear; ++i) {
		*re = buf[i];
		++re;
	}
	*re = '\0';
	int len = buf_rear;
	clear_buf();
	return len;
}

void getline(char* re)
{
	int len=readline(re);
	*(re + len - 1) = '\0';
}

char getchar()
{
	static char temp_buf[BUF_SIZE];
	static int temp_front = 0;
	static int temp_rear = 0;
	if (temp_front == temp_rear) {
		temp_rear = readline(temp_buf);
		temp_front = 0;
	}
	char c = temp_buf[temp_front];
	temp_front++;
	return c;
}

char getch()
{
	char re = read_key();
	if (buf_rear > 0) {
		--buf_rear;
	}
	return re;
}