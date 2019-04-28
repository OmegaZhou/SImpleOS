#include "include/lib.h"
#include "include/global.h"
#include "include/CRT_control.h"
extern void printf_color_str_origin(unsigned char* info, int color);

void printf_color_str(unsigned char* info, int color)
{
	printf_color_str_origin(info, color);
	judge_screen_local();
}

void printf_str(unsigned char* info)
{
	printf_color_str(info, 0x0f);
}

void printf_int(int num)
{
	char out[16];
	itoa(out, num);
	printf_str(out);
}

void key_back()
{
	if (start_pos >= 2) {
		start_pos -= 2;
		printf_str(" ");
		start_pos -= 2;
		judge_screen_local();
	}
}

char* itoa(char* str, int num)
{
	char* st = str;
	int k;
	int temp;
	*str = '0';
	++str;
	*str = 'x';
	++str;
	if (num == 0) {
		*str = '0';
		++str;
	} else {
		temp = 1;
		while (num/16 >= temp) {
			temp *= 16;
		}
		while (temp) {
			k = num / temp;
			if (k > 9) {
				*str = 'A' + k - 10;
			} else {
				*str = '0' + k;
			}
			++str;
			num %= temp;
			temp /= 16;
		}
	}
	*str = '\0';
	return st;
}

void judge_screen_local(unsigned char* info)
{
	unsigned short local = get_port_value(CRT_ADDR_PORT, SCREEN_START_ADDRESS_H, SCREEN_START_ADDRESS_L);
	unsigned short cursor_local = get_port_value(CRT_ADDR_PORT, CURSOR_LOCAL_H, CURSOR_LOCAL_L);
	if (cursor_local >= local + (MAX_HEIGHTH + 1)*MAX_LENGTH || (start_pos >= 0 && start_pos / 2 < local)) {
		local = cursor_local / MAX_LENGTH * MAX_LENGTH - (MAX_HEIGHTH )*MAX_LENGTH;
		set_CRT_port_value(SCREEN_START_ADDRESS_H, SCREEN_START_ADDRESS_L, local);
	}
}

