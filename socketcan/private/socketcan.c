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
