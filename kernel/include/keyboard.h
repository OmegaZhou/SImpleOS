#ifndef KEYBOARD_H_
#define KEYBOARD_H_

extern void init_keyboard();
extern void clear_buf();
extern char getchar();
extern void getline(char* re);
extern char getch();
#define BUF_SIZE 256
#define BACKSPACE 0x08
#define SHIFT 0x06
#define CRTL -1
#endif // !KEYBOARD_H_
