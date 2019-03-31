#include "lib.h"
#include "global.h"

extern void printf_color_str_origin(unsigned char* info, int color);

void printf_color_str(unsigned char* info, int color)
{
	judge_clean(info);
	printf_color_str_origin(info, color);
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

void judge_clean(unsigned char* info)
{
	static char temp[(MAX_HEIGHTH + 1)*MAX_LENGTH * 2 + 1];
	static int flag = 1;
	if(flag){
		for (int i = 0; i < (MAX_HEIGHTH + 1)*MAX_LENGTH * 2; ++i) {
			temp[i] = ' ';
		}
		temp[(MAX_HEIGHTH + 1)*MAX_LENGTH * 2] = '\0';
		flag = 0;
	}
	int len = 0;
	for (len = 0; info[len] != '\0'; ++len) {
	}
	
	if (start_pos + len > (MAX_HEIGHTH + 1)*MAX_LENGTH * 2) {
		start_pos = 0;
		printf_color_str_origin(temp, 0x0f);
		start_pos = 0;
		
	}
}

