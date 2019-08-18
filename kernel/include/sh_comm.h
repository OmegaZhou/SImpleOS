#ifndef SH_COMM_H
#define SH_COMM_H
#include "file_sys_command.h"
#include "shell.h"
#include "file_sys_command.h"
#define MAX_NAME_SIZE 12
#define HELP_MSG_SIZE 512
struct Command
{
    char name[MAX_NAME_SIZE];
    main_func func;
    char help_msg[HELP_MSG_SIZE];
};
extern struct Command* get_func(char *name);

#endif // !SH_COMM_H_
