#include "lib.h"
#include "global.h"
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

void judge_clean()
{
	if (start_pos == (MAX_HEIGHTH + 1)*MAX_LENGTH * 2) {
		start_pos = 0;
		for (int i = 0; i < (MAX_HEIGHTH + 1)*MAX_LENGTH * 2; ++i) {
			printf_str(" ");
		}
		start_pos = 0;
	}
}
