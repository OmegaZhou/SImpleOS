#ifndef SHELL_H_
#define SHELL_H_

typedef int(*main_func)(int argc, char* argv[]);
extern void init_shell();
extern void init_fs();
#define PARAM_SIZE 10

#endif // !SHELL_H_
