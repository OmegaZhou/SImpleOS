#include "include/lib.h"
#include "include/global.h"
#include "include/disk.h"
void main()
{
	init_keyboard();
	init_disk();
	for (;;) {
		read_key();
	}
}