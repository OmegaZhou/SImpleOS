#ifndef CRT_CONTROL_H_
#define CRT_CONTROL_H_

#define CRT_ADDR_PORT 0x3D4
#define CRT_DATA_PORT 0x3D5

#define SCREEN_START_ADDRESS_H 0xC
#define SCREEN_START_ADDRESS_L 0xD

#define CURSOR_LOCAL_H 0xE
#define CURSOR_LOCAL_L 0xF


extern void set_CRT_port_value(unsigned char index_h, unsigned char index_l, unsigned short value);
#endif // ! CRT_CONTROL_H_
