#include "include/sh_comm.h"
#include "include/print.h"
#include "include/string.h"
extern int help(int argc,char* argv[]);
extern int hello_world(int argc,char* argv[]);
struct Command command_table[] = {{"help", help, "Get command information"},
                                  {"hello_world", hello_world, "Say hello world"},
                                  {"ls", ls, "Get the directory information"},
                                  {"pwd", pwd, "Get the current directory"},
                                  {"mkfs", mkfs, "Initialize the disk"},
                                  {"mkdir", mkdir, "Create new directory"},
                                  {"cd", cd, "Switch the current directory to new direectory"},
                                  {"rm", rm, "Remove the file or directory"},
                                  {"mkfl", mkfl, "Create a new file"},
                                  {"wrfl", wrfl, "Write for a file"},
                                  {"cat", cat, "Display the file data"}};

static void print_command_info(struct Command* command){
	printf_str(command->name);
	printf_str(" : ");
	printf_str(command->help_msg);
	printf_str("\n");
}

struct Command* get_func(char *name){
	int size=sizeof(command_table)/sizeof(struct Command);
	for(int i=0;i<size;++i){
		if(str_comp(command_table[i].name,name)==0){
			return &command_table[i];
		}
	}
	return 0;
}

int hello_world(int argc, char* argv[])
{
	printf_str("Hello World\n");
	for (int i = 1; i < argc; ++i) {
		printf_str(*(argv + i));
		printf_str("\n");
	}
}

int help(int argc,char* argv[])
{
	int size=sizeof(command_table)/sizeof(struct Command);
	if(argc==1){
		for(int i=0;i<size;++i){
			print_command_info(&command_table[i]);
		}
		return 0;
	}
	for(int i=1;i<argc;++i){
		struct Command* temp=get_func(argv[i]);
		if(temp){
			print_command_info(temp);
		}else{
			printf_str("Command :\'");
			printf_str(argv[i]);
			printf_str("\' not found\n");
		}
	}
	
	return 0;
}

