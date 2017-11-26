#ifndef __IWL_NL_H__
#define __IWL_NL_H__

#include <stdint.h>
#include <sys/types.h>

#define IWL_NL_BUFFER_SIZE	4096

int open_iwl_netlink_socket();
void close_iwl_netlink_socket(int sock_fd);
int iwl_netlink_recv(int sock_fd, u_char **buf, int *len);
int iwl_netlink_send(int sock_fd, const u_char *buf, int len);

struct iwl_netlink_msg {
	uint16_t length;	/* __le16 */
	uint8_t code;
	uint8_t payload[0];
} __attribute__ ((packed));

#endif /* __IWL_NL_H__ */
