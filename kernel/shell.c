#include "include/keyboard.h"
#include "include/print.h"
#include "include/shell.h"
#include "include/system_call.h"
#include "include/string.h"
#include "include/type.h"
#define MAX_NAME_SIZE 12
struct Command
{
	char name[MAX_NAME_SIZE];
	main_func func;
};
struct Command command_table[] = { {"hello_world",hello_world} };
void get_command()
{
	static char command[BUF_SIZE];
	static char* argv[PARAM_SIZE];
	getline(command);
	main_func command_pointer;
	int command_len = str_len(command);
	int start_flag = 0;
	int end_flag = 0;
	int argc = 0;
	for (int i = 0; i < command_len; ++i) {
		if (!isspace(command[i])) {
			if (start_flag == 0) {
				start_flag = 1;
				end_flag = 0;
				argv[argc] = command + i;
				++argc;
			}
		} else {
			if (end_flag == 0) {
				command[i] = '\0';
				start_flag = 0;
				end_flag = 1;
			}
		}
	}
	int command_table_size = sizeof(command_table) / sizeof(struct Command);
	for (int i = 0; i < command_table_size; ++i) {
		if (str_comp(command_table[i].name, argv[0]) == 0) {
			command_pointer = command_table[i].func;
			(*command_pointer)(argc, argv);
			return;
		}
	}
	printf_str("Command not found\n");
}

void init_shell()
{
	for (;;) {
		printf_str("Zhou>");
		get_command();
	}
}
