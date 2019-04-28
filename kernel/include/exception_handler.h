#ifndef EXCEPTION_HANDLER_H_
#define EXCEPTION_HANDLER_H_

extern void init_port();
extern void exception_handler(int vec_no, int err_code, int eip, int cs, int flag);
#endif // !EXCEPTION_HANDLER_H_
