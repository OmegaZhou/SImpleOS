#include "CRT_control.h"
#include "lib.h"
void set_CRT_port_value(unsigned char index_h, unsigned char index_l, unsigned short value)
{
	out_byte(CRT_ADDR_PORT, index_h);
	out_byte(CRT_DATA_PORT, (value >> 8) & 0xff);

	out_byte(CRT_ADDR_PORT, index_l);
	out_byte(CRT_DATA_PORT, (value) & 0xff);
}