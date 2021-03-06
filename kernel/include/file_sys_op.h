#ifndef FILE_SYS_OP_H_
#define FILE_SYS_OP_H_
#include "file_sys_config.h"
void clear_bitgraph();
//Return the id is relative to file sectors.
int get_free_sector();
//file_section_id is relative to file sectors
void use_sector(int file_section_id);
void unuse_sector(int file_id);
void clear_file_sector(int id);
int add_file_sector(int type, int father_id, int last_id, char *name, FILE_HEADER* file_header);
void add_item(int father_id, int son_id);
int check_file_name(int father_id, char* name);
int create_file(int type, int father_id, char* name);
int get_item_num(FILE_HEADER* header);
void print_file_name(int id);
void get_dir_trace(int id);
void get_file_name(int id, char* name);
int check_file_exist(int father_id, char* name,int* get_id);
int divide_dir_para(char* info, char** para);
void get_header(FILE_HEADER* i, int id);
int jump_to(char* location);
void remove_file(int start_id);
int check_remove_id(int rm_id, int now_id);
void clear_file(int id);
FILE_HEADER* open_file(int id, char* space);
void write_file(char c, FILE_HEADER* file);
int read_file(FILE_HEADER* file, int* loc);
void close_file(FILE_HEADER* file);
extern int now_dir_id;
#endif // !FILE_SYS_OP_H_

