
int can_open(const char *name);
long unsigned can_write(int sock, int id, const char *data, int length);
long unsigned can_read(int sock, int *id, char *data_buf, unsigned *length);
int can_check_data(int sock);

