char* itoa_with_16(char* str, int num)
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
		while (num / 16 >= temp) {
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

int str_len(char* str)
{
	int re = 0;
	while (str[re]) {
		++re;
	}
	return re;
}

int str_comp(char* str1, char* str2)
{
	int len_1 = str_len(str1);
	int len_2 = str_len(str2);
	for (int i = 0; i < len_1&&i < len_2; ++i) {
		if (str1[i] > str2[i]) {
			return 1;
		} else if (str1[i] < str2[i]) {
			return -1;
		}
	}
	if (len_1 > len_2) {
		return 1;
	} else if (len_1 < len_2) {
		return -1;
	} else {
		return 0;
	}
}