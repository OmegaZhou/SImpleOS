#include "include/shell.h"
#include "include/type.h"
#include "include/print.h"
#include "include/string.h"
#include "include/keyboard.h"
#include "include/sh_comm.h"

void get_command()
{
	static char command[512] = { 0 };
	static char* argv[PARAM_SIZE];
	char c;
	int size=0;
	while((c=getchar())!='\n'){
		command[size++]=c;
	}
	command[size]='\0';
	//getline(command);
	struct Command* command_pointer;
	int command_len = str_len(command);
	int start_flag = 0;
	int end_flag = 0;
	int argc = 0;
	argv[0]=command;
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
	//printf_str(command);
	if (str_comp("", argv[0]) == 0) {
		return;
	}
	command_pointer=get_func(argv[0]);
	if(command_pointer){
		(*(command_pointer->func))(argc, argv);
		return;
	}
	printf_str("Command not found\n");
}

void init_shell()
{
	printf_str("Use \"help\" command to get command information\n");
	for (;;) {
		printf_str("Zhou>");
		get_command();
	}
}