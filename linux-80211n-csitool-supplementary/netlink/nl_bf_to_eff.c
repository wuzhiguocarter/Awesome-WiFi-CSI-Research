#include "bf_to_eff.h"
#include "iwl_nl.h"
#include "iwl_structs.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <arpa/inet.h>

int sock_fd = -1;					// the socket
FILE* out = NULL;

static void check_usage(int argc, char** argv);

static FILE* open_file(char* filename, char* spec);

static void caught_signal(int sig);

static void exit_program(int code);
static void exit_program_err(int code, char* func);

int main(int argc, char** argv)
{
	/* Local variables */
	u_char *buf;
	int len;
	int ret;
	double eff_snrs[MAX_NUM_RATES][4];
	struct iwl5000_bfee_notif *bfee;

	/* Make sure usage is correct */
	check_usage(argc, argv);

	/* Open and check log file */
	out = open_file(argv[1], "w");

	/* Setup the socket */
	sock_fd = open_iwl_netlink_socket();
	if (sock_fd == -1)
		exit_program(-1);

	/* Set up the "caught_signal" function as this program's sig handler */
	signal(SIGINT, caught_signal);

	uint16_t l, l2;

	/* Poll socket forever waiting for a message */
	while (1) {
		/* Receive from socket with infinite timeout */
		ret = iwl_netlink_recv(sock_fd, &buf, &len);
		if (ret == -1)
			exit_program_err(-1, "recv");
		if (buf[0] != IWL_CONN_BFEE_NOTIF) {
			continue;
		}
		/* Log the data to file */
		l = (uint16_t) len;
		l2 = htons(l);
		fwrite(&l2, 1, sizeof(unsigned short), out);
		ret = fwrite(buf, 1, l, out);
		printf("wrote %d bytes\n", ret);
		if (ret != l)
			exit_program_err(1, "fwrite");
		/* Calculate effective SNRs */
		bfee = (struct iwl5000_bfee_notif *)&buf[1];
		calc_eff_snrs(bfee, eff_snrs);
	}
}

static void check_usage(int argc, char** argv)
{
	if (argc != 2) {
		fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
		exit_program(1);
	}
}

static FILE* open_file(char* filename, char* spec)
{
	FILE* fp = fopen(filename, spec);
	if (!fp) {
		perror("fopen");
		exit_program(1);
	}
	return fp;
}

static void caught_signal(int sig)
{
	fprintf(stderr, "Caught signal %d\n", sig);
	exit_program(0);
}

static void exit_program(int code)
{
	if (out) {
		fclose(out);
		out = NULL;
	}
	if (sock_fd != -1) {
		close_iwl_netlink_socket(sock_fd);
		sock_fd = -1;
	}
	exit(code);
}

static void exit_program_err(int code, char* func)
{
	perror(func);
	exit_program(code);
}
