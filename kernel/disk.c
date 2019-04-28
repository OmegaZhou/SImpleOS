#include "disk.h"
#include "lib.h"
#include "i8259.h"
#define DEVICE_VALUE 0xe0
#define DISK_DATA_PORT 0x1f0
#define DISK_ERROR_PORT 0x1f1
#define DISK_SECTOR_NUM 0x1f2
#define DISK_LOW_PORT 0x1f3
#define DISK_MID_PORT 0x1f4
#define DISK_HIGH_PORT 0x1f5
#define DISK_DEVICE_PORT 0x1f6
#define DISK_STATE_CMD_PORT 0x1f7

#define READ_CMD 0x20
#define WRITE_CMD 0x30
#define DISK_BUSY (1<<7)
#define DISK_READY (1<<6)
#define DISK_DATA_REQ (1<<3)
static int flag;
static char buf[SECTOR_SIZE];
static char* data_info;
void disk_handler(int irq)
{
	port_read(DISK_DATA_PORT, buf, SECTOR_SIZE);
	for (int i = 0; i < SECTOR_SIZE; ++i,++data_info) {
		*data_info = buf[i];
	}
	--flag;
}

void disk_init()
{
	flag = 0;
	data_info = NULL;
	add_irq(disk_handler, AT_WINI_IRQ);
}

void get_data(int sector_id,int sector_num,char* info)
{
	flag = sector_num;
	data_info = info;
	while (flag) {
		while (in_byte(DISK_STATE_CMD_PORT)&DISK_BUSY) {
			;
		}
		out_byte(DISK_DEVICE_PORT, DEVICE_VALUE);
		out_byte(DISK_ERROR_PORT, 0);
		out_byte(DISK_SECTOR_NUM, 1);
		out_byte(DISK_LOW_PORT, (sector_id) && 0xff);
		out_byte(DISK_MID_PORT, (sector_id >> 8) && 0xff);
		out_byte(DISK_HIGH_PORT, (sector_id >> 16) && 0xff);
		while (!(in_byte(DISK_STATE_CMD_PORT)&DISK_READY)) {
			;
		}
		out_byte(DISK_STATE_CMD_PORT, READ_CMD);
	}
}
void save_data(int secotr_id, int sector_num, char* info)
{
	while (in_byte(DISK_STATE_CMD_PORT)&DISK_BUSY) {
		;
	}
	out_byte(DISK_DEVICE_PORT, DEVICE_VALUE);
	out_byte(DISK_ERROR_PORT, 0);
	out_byte(DISK_SECTOR_NUM, sector_num);
	out_byte(DISK_LOW_PORT, (sector_id) && 0xff);
	out_byte(DISK_MID_PORT, (sector_id >> 8) && 0xff);
	out_byte(DISK_HIGH_PORT, (sector_id >> 16) && 0xff);
	while (!(in_byte(DISK_STATE_CMD_PORT)&DISK_READY)) {
		;
	}
	out_byte(DISK_STATE_CMD_PORT, WRITE_CMD);
	while (!(in_byte(DISK_STATE_CMD_PORT)&DISK_DATA_REQ)) {
		;
	}
	port_write(DISK_DATA_PORT, info, sector_num*SECTOR_SIZE);
}
char* get_buf()
{
	return buf;
}