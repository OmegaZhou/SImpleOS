#include "lib.h"
#include "global.h"

void main()
{
	init_keyboard();
	for (;;) {
		read_key();
	}
}