#ifndef STRING_H_
#define STRING_H_

extern char* itoa_with_16(char* str, int num);
extern int str_len(char* str);

//If str1>str2 return 1 
//If str1<str2 return -1
//If str1==str2 return 0
extern int str_comp(char* str1, char* str2);
#endif // !STRING_H_
