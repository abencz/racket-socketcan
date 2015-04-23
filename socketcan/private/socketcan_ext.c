#include "escheme.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <poll.h>
#include <net/if.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
 
#include <linux/can.h>
#include <linux/can/raw.h>


int can_open(const char *name)
  XFORM_SKIP_PROC
{
  int s;
  struct ifreq ifr;
  struct sockaddr_can addr;


  if ((s = socket(PF_CAN, SOCK_RAW, CAN_RAW)) < 0)
  {
    perror("Error while opening socket");
    return -1;
  }

  strcpy(ifr.ifr_name, name);
  ioctl(s, SIOCGIFINDEX, &ifr);

  addr.can_family = AF_CAN;
  addr.can_ifindex = ifr.ifr_ifindex;

  if (bind(s, (struct sockaddr *)&addr, sizeof(addr)) < 0)
  {
    perror("Error in socket bind");
    return -2;
  }

  return s;
}

int can_close(int sock)
  XFORM_SKIP_PROC
{
  if (close(sock) < 0)
  {
    perror("Could not close CAN socket");
    return -1;
  }
}

long unsigned can_write(int sock, int id, const char *data, int length)
  XFORM_SKIP_PROC
{
  struct can_frame frame;

  frame.can_id = id;
  frame.can_dlc = length;
  memcpy(frame.data, data, length);

  return write(sock, &frame, sizeof(frame));
}

long unsigned can_read(int sock, int *id, char *data_buf, unsigned *length)
  XFORM_SKIP_PROC
{
  struct can_frame frame;
  int bytes_read;

  bytes_read = read(sock, &frame, sizeof(frame));
  if (bytes_read < 0)
  {
    perror("CAN raw socket read");
    return bytes_read;
  }

  if (bytes_read < sizeof(frame))
  {
    fprintf(stderr, "read: imcomplete CAN frame\n");
    return bytes_read;
  }

  *id = frame.can_id;
  *length = frame.can_dlc;
  memcpy(data_buf, frame.data, frame.can_dlc);
  
  return bytes_read;
}

int can_check_data(int sock)
  XFORM_SKIP_PROC
{
  int ready;
  struct pollfd poll_desc;
  poll_desc.fd = sock;
  poll_desc.events = POLLIN;
  poll_desc.revents = POLLIN;

  ready = poll(&poll_desc, 1, 5);

  if (ready < 0)
  {
    perror("Failed to poll device");
    return 0;
  }

  if (ready)
  {
    return 1;
  }
}

static void check_socket_arg(int argc, Scheme_Object **argv)
{
  if (!SCHEME_INTP(argv[0]))
  {
    scheme_wrong_type("socket", "integer socket handle", 0, argc, argv);
  }
}

static Scheme_Object* r_can_open(int argc, Scheme_Object **argv)
{
  int sock;
  Scheme_Object* byte_str;

  if (!SCHEME_CHAR_STRINGP(argv[0]))
  {
    scheme_wrong_type("interface", "character string", 0, argc, argv);
  }

  byte_str = scheme_char_string_to_byte_string(argv[0]);
  sock = can_open(SCHEME_BYTE_STR_VAL(byte_str));
  return scheme_make_integer(sock);
}

static Scheme_Object* r_can_close(int argc, Scheme_Object **argv)
{
  int sock;
  check_socket_arg(argc, argv);

  sock = SCHEME_INT_VAL(argv[0]);
  return scheme_make_integer(can_close(sock));
}

static Scheme_Object* r_can_write(int argc, Scheme_Object **argv)
{
  int sock, id, length;
  const char *data;
  check_socket_arg(argc, argv);

  sock = SCHEME_INT_VAL(argv[0]);

  if (!SCHEME_INTP(argv[1]))
  {
    scheme_wrong_type("can-id", "integer CAN id", 0, argc, argv);
  }

  id = SCHEME_INT_VAL(argv[1]);

  if (id < 0 || id >= (1 << 11))
  {
    scheme_wrong_contract("can-id", "0 <= can-id < 2048", 1, argc, argv);
  }

  if (!SCHEME_BYTE_STRINGP(argv[2]))
  {
    scheme_wrong_type("data", "byte string", 0, argc, argv);
  }

  data = SCHEME_BYTE_STR_VAL(argv[2]);
  length = SCHEME_BYTE_STRLEN_VAL(argv[2]);

  if (length > 8)
  {
    scheme_wrong_contract("data", "(<= (bytes-length data) 8)", 2, argc, argv);
  }

  return scheme_make_integer(can_write(sock, id, data, length));
}

static int r_can_ready(Scheme_Object* data)
{
  int sock;
  sock = SCHEME_INT_VAL(data);
  return can_check_data(sock);
}

static void r_needs_wakeup(Scheme_Object *data, void *fds)
{
  int sock;
  sock = SCHEME_INT_VAL(data);
  MZ_FD_SET(sock, fds);
}

static Scheme_Object* r_can_read(int argc, Scheme_Object **argv)
{
  int sock, id, length;
  char data[8];
  Scheme_Object *bytes, *id_int;
  check_socket_arg(argc, argv);

  sock = SCHEME_INT_VAL(argv[0]);
  scheme_block_until(r_can_ready, r_needs_wakeup, argv[0], 0.1);
  can_read(sock, &id, data, &length);

  id_int = scheme_make_integer(id);
  bytes = scheme_make_sized_byte_string(data, length, 1);

  return scheme_make_pair(id_int, scheme_make_pair(bytes, scheme_null));
}

static Scheme_Object* r_can_read_nonblock(int argc, Scheme_Object **argv)
{
  int sock;
  check_socket_arg(argc, argv);

  sock = SCHEME_INT_VAL(argv[0]);

  if (can_check_data(sock))
  {
    return r_can_read(argc, argv);
  }

  return scheme_make_pair(scheme_false, scheme_make_pair(scheme_false, scheme_null));
}

Scheme_Object* scheme_initialize(Scheme_Env *env)
{
  Scheme_Object *name, *proc;
  Scheme_Env *module;

  name = scheme_intern_symbol("socketcan_ext");
  module = scheme_primitive_module(name, env);

  proc = scheme_make_prim_w_arity(r_can_open, "can-open-raw", 1, 1);
  scheme_add_global("can-open", proc, module);

  proc = scheme_make_prim_w_arity(r_can_close, "can-close-raw", 1, 1);
  scheme_add_global("can-close", proc, module);

  proc = scheme_make_prim_w_arity(r_can_write, "can-send-raw", 3, 3);
  scheme_add_global("can-send", proc, module);

  proc = scheme_make_prim_w_arity(r_can_read, "can-receive!-raw", 1, 1);
  scheme_add_global("can-receive!", proc, module);

  proc = scheme_make_prim_w_arity(r_can_read_nonblock, "can-receive!*-raw", 1, 1);
  scheme_add_global("can-receive!*", proc, module);

  scheme_finish_primitive_module(module);

  return scheme_void;
}

Scheme_Object* scheme_reload(Scheme_Env *env)
{
  return scheme_initialize(env);
}

Scheme_Object* scheme_module_name()
{
  return scheme_intern_symbol("socketcan_ext");
}
