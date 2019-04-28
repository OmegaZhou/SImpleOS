#ifndef LIB_H_
#define LIB_H_

#include "print.h"
#include "i8259.h"
#include "keyboard.h"
#include "print.h"
#include "exception_handler.h"
#include "disk.h"
extern void memcpy(void* des, void* source,unsigned int size);



extern void start_int();
extern void close_int();

extern unsigned short get_port_value(unsigned short port, unsigned char index_h, unsigned char index_l);

extern void out_byte(unsigned short port_num, unsigned char value);
extern unsigned char in_byte(unsigned short port_num);
extern void port_read(short port, void* buf, int n);
extern void port_write(short port, void* buf, int n);


#endif // !LIB_H_

