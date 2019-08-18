#include "include/file_sys_op.h"
#include "include/print.h"
#include "include/string.h"
#include "include/keyboard.h"

void init_fs(){
	now_dir_id=ROOT_ID;
}
int ls(int argc, char* argv[])
{
	char info[SECTOR_SIZE];
	int temp = now_dir_id;
	if (argc > 1) {
		for (int j = 1; j < argc; ++j) {
			if (argc > 2) {
				//printf_str("%s:   ", argv[j]);
			}
			int status = jump_to(argv[j]);
			if (status == 2) {
				//printf_str("ls: cannot access \'%s\' : No such file or directory\n", argv[j]);
			} else if (status == 1) {
				//printf_str("%s", argv[j]);
			} else {
				int id = now_dir_id;
				while (id != -1) {
					get_data(FILE_SECTOR(id), 1, info);
					FILE_HEADER* header = (FILE_HEADER*)info;
					int* item_id = (int*)DATA_START_LOC(info, header->name_len);
					int num = get_item_num(header);
					for (int i = 0; i < num; ++i) {
						print_file_name(item_id[i]);
						printf_str(" ");
					}
					id = header->next_id;
				}
				printf_str("\n");
			}
			now_dir_id = temp;
		}
	} else {
		int id = now_dir_id;
		while (id != -1) {
			get_data(FILE_SECTOR(id), 1, info);
			FILE_HEADER* header = (FILE_HEADER*)info;
			int* item_id = (int*)DATA_START_LOC(info, header->name_len);
			int num = get_item_num(header);
			for (int i = 0; i < num; ++i) {
				print_file_name(item_id[i]);
				printf_str(" ");
			}
			id = header->next_id;
		}
		printf_str("\n");
	}

	return 0;
}

int mkfs(int argc, char* argv[])
{
	clear_file_sector(FILE_SECTOR(ROOT_ID));
	clear_bitgraph();
	create_file(DIR_TYPE, -1, "");
	return 0;
}

int pwd(int argc, char* argv[])
{
	get_dir_trace(now_dir_id);
	printf_str("\n");
	return 0;
}

int mkdir(int argc, char* argv[])
{
	int temp = now_dir_id;
	for (int i = 1; i < argc; ++i) {
		int c = -1;
		int size = str_len(argv[i]);
		for (int j = size - 1; j >= 0; --j) {
			if (argv[i][j] == '/') {
				argv[i][j] = '\0';
				if (j != size - 1) {
					c = j;
					break;
				}

			}
		}
		if (c != -1) {
			int flag = jump_to(argv[i]);
			if (flag == 1) {
				if (c != -1) {
					argv[i][c] = '/';
				}
				printf_str("mkdir: ");
				printf_str(argv[i]);
				printf_str(": Not a directory\n");
				continue;
			} else if (flag == 2) {
				if (c != -1) {
					argv[i][c] = '/';
				}
				printf_str("mkdir: ");
				printf_str(argv[i]);
				printf_str(": No such file or directory\n");
				continue;
			}
		}
		if (!create_file(DIR_TYPE, now_dir_id, &argv[i][c + 1])) {
			if (c != -1) {
				argv[i][c] = '/';
			}
			printf_str("mkdir: cannot create directory \'");
			printf_str(argv[i]);
			printf_str("\': File exists\n");
		}
		now_dir_id = temp;
	}
	return 0;
}

int cd(int argc, char* argv[])
{
	if (argc <= 1) {
		now_dir_id = ROOT_ID;
		return 0;
	}
	int flag = jump_to(argv[1]);
	if (flag == 1) {
		printf_str("cd: ");
		printf_str(argv[1]);
		printf_str(": Not a directory\n");
	} else if (flag == 2) {
		printf_str("cd: ");
		printf_str(argv[1]);
		printf_str(": No such file or directory\n");
	}
	return 0;
}

int rm(int argc, char* argv[])
{
	if (argc <= 1) {
		return 0;
	}
	int temp = now_dir_id;
	for (int i = 1; i < argc; ++i) {
		int c = -1;
		int size = str_len(argv[i]);
		for (int j = size - 1; j >= 0; --j) {
			if (argv[i][j] == '/') {
				argv[i][j] = '\0';
				if (j != size - 1) {
					c = j;
					break;
				}

			}
		}
		if (c != -1) {
			int flag = jump_to(argv[i]);
			if (flag == 1) {
				if (c != -1) {
					argv[i][c] = '/';
				}
				printf_str("rm: ");
				printf_str(argv[i]);
				printf_str(": Not a directory\n");
				continue;
			} else if (flag == 2) {
				if (c != -1) {
					argv[i][c] = '/';
				}
				printf_str("rm: ");
				printf_str(argv[i]);
				printf_str(": No such file or directory\n");
				continue;
			}
		}
		if (str_comp(&argv[i][c + 1], ".") == 0 || str_comp(&argv[i][c + 1], "..") == 0) {
			printf_str("rm: refusing to remove '.' or '..'\n");
		} else {
			int id = -1;
			check_file_exist(now_dir_id, &argv[i][c + 1], &id);
			if (id == -1) {
				printf_str("rm: ");
				printf_str(&argv[i][c + 1]);
				printf_str(": No such file or directory\n");
			} else {
				if (check_remove_id(id, temp)) {
					remove_file(id);
				} else {
					printf_str("rm: Can't remove it\n");
				}

			}
		}
		now_dir_id = temp;
	}
	return 0;
}

int mkfl(int argc, char* argv[])
{
	int temp = now_dir_id;
	for (int i = 1; i < argc; ++i) {
		int c = -1;
		int size = str_len(argv[i]);
		for (int j = size - 1; j >= 0; --j) {
			if (argv[i][j] == '/') {
				argv[i][j] = '\0';
				c = j;
				break;

			}
		}
		if (c != -1) {
			int flag = jump_to(argv[i]);
			if (flag == 1) {
				if (c != -1) {
					argv[i][c] = '/';
				}
				printf_str("mkfl: ");
				printf_str(argv[i]);
				printf_str(": Not a directory\n");
				continue;
			} else if (flag == 2) {
				if (c != -1) {
					argv[i][c] = '/';
				}
				printf_str("mkfl: ");
				printf_str(argv[i]);
				printf_str(": No such file or directory\n");
				continue;
			}
		}
		if (!create_file(FILE_TYPE, now_dir_id, &argv[i][c + 1])) {
			if (c != -1) {
				argv[i][c] = '/';
			}
			printf_str("mkfl: cannot create directory \'");
			printf_str(argv[i]);
			printf_str("\': File exists\n");
		}
		now_dir_id = temp;
	}
	return 0;
}

int wrfl(int argc, char* argv[])
{
	if (argc <= 1) {
		return 0;
	}
	int temp = now_dir_id;
	int c = -1;
	int size = str_len(argv[1]);
	for (int j = size - 1; j >= 0; --j) {
		if (argv[1][j] == '/') {
			argv[1][j] = '\0';
			c = j;
			break;

		}
	}
	if (c != -1) {
		int flag = jump_to(argv[1]);
		if (flag == 1) {
			if (c != -1) {
				argv[1][c] = '/';
			}
			printf_str("wrfl: ");
			printf_str(argv[1]);
			printf_str(": Not a directory\n");
			now_dir_id = temp;
			return 0;
		} else if (flag == 2) {
			if (c != -1) {
				argv[1][c] = '/';
			}
			printf_str("wrfl: ");
			printf_str(argv[1]);
			printf_str(": No such file or directory\n");
			now_dir_id = temp;
			return 0;
		}
	}
	char info[SECTOR_SIZE];
	int id = -1;;
	if (check_file_exist(now_dir_id, &argv[1][c+1], &id) != 1) {
		if (c != -1) {
			argv[1][c] = '/';
		}
		printf_str("wrfl: ");
		printf_str(argv[1]);
		printf_str(": No such file or directory\n");
		return 0;
	}
	clear_file(id);
	char ch;
	FILE_HEADER* file = open_file(id, info);
	if (file->type != FILE_TYPE) {
		if (c != -1) {
			argv[1][c] = '/';
		}
		printf_str("wrfl: ");
		printf_str(argv[1]);
		printf_str(": Is a directory\n");
		return 0;
	}
	while ((ch = getchar()) != -1) {
		//printf_int(ch);
		write_file(ch, file);
	}
	while((ch=getchar())!='\n'){

	}
	close_file(file);
	now_dir_id = temp;
	return 0;
}

int cat(int argc, char* argv[])
{
	if (argc <= 1) {
		return 0;
	}
	int temp = now_dir_id;
	int c = -1;
	int size = str_len(argv[1]);
	for (int j = size - 1; j >= 0; --j) {
		if (argv[1][j] == '/') {
			argv[1][j] = '\0';
			c = j;
			break;

		}
	}
	if (c != -1) {
		int flag = jump_to(argv[1]);
		if (flag == 1) {
			if (c != -1) {
				argv[1][c] = '/';
			}
			printf_str("cat: ");
			printf_str(argv[1]);
			printf_str(": Not a directory\n");
			now_dir_id = temp;
			return 0;
		} else if (flag == 2) {
			if (c != -1) {
				argv[1][c] = '/';
			}
			printf_str("cat: ");
			printf_str(argv[1]);
			printf_str(": No such file or directory\n");
			now_dir_id = temp;
			return 0;
		}
	}
	char info[SECTOR_SIZE];
	int id = -1;;
	if (check_file_exist(now_dir_id, &argv[1][c + 1], &id) != 1) {
		if (c != -1) {
			argv[1][c] = '/';
		}
		printf_str("cat: ");
		printf_str(argv[1]);
		printf_str(": No such file or directory\n");
		return 0;
	}
	clear_file(id);
	char ch;
	FILE_HEADER* file = open_file(id, info);
	if (file->type != FILE_TYPE) {
		if (c != -1) {
			argv[1][c] = '/';
		}
		printf_str("cat: ");
		printf_str(argv[1]);
		printf_str(": Is a directory\n");
	}
	int loc = 0;
	while ((ch = read_file(file, &loc)) != -1) {
		char temp[2];
		temp[0]=ch;
		temp[1]='\0';
		printf_str(temp);
	}
	printf_str("\n");
	close_file(file);
	return 0;
}