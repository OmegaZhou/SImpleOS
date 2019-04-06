#ifndef LIB_H_
#define LIB_H_

extern char* itoa(char* str, int num);
extern void printf_str(unsigned char* info);
extern void printf_int(int num);
extern void printf_color_str(unsigned char* info, int color);
extern void key_back();
extern void judge_screen_local();

extern void memcpy(void* des, void* source,unsigned int size);

extern void read_key();
extern void init_keyboard();

extern void init_port();

extern void start_int();
extern void close_int();

extern unsigned short get_port_value(unsigned short port, unsigned char index_h, unsigned char index_l);

extern void out_byte(unsigned short port_num, unsigned char value);
extern unsigned char in_byte(unsigned short port_num);
extern void init_8259A();
extern void spurious_irq(int irq);

extern void exception_handler(int vec_no, int err_code, int eip, int cs, int flag);

#endif // !LIB_H_

