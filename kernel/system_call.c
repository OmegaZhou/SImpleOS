#include "include/system_call.h"
#include "include/print.h"

int hello_world(int argc, char* argv[])
{
	printf_str("Hello World\n");
	for (int i = 1; i < argc; ++i) {
		printf_str(*(argv + i));
		printf_str("\n");
	}
}