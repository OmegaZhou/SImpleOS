#include "lib.h"

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