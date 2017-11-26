/*
 * (c) 2011 Daniel Halperin <dhalperi@cs.washington.edu>
 */
#include <stdio.h>
#include <stdlib.h>
#include <arpa/inet.h>

#define BUF_SIZE	4096

void check_usage(int argc, char** argv);

FILE* open_file(char* filename, char* spec);

void exit_program(int code);
void exit_program_err(int code, char* func);

int main(int argc, char** argv)
{
	/* Local variables */
	unsigned char buf[BUF_SIZE];
	unsigned short l, l2;
	FILE* in;

	/* Make sure usage is correct */
	check_usage(argc, argv);

	/* Open and check log file */
	in = open_file(argv[1], "r");

	/* Read the next entry size */
	fread(&l2, 1, sizeof(unsigned short), in);
	l = ntohs(l2);
	while (!feof(in)) {
		/* Sanity-check the entry size */
		if (l == 0) {
			fprintf(stderr, "Error: got entry size=0\n");
			exit_program(-1);
		} else if (l > BUF_SIZE) {
			fprintf(stderr,
				"Error: got entry size %u > BUF_SIZE=%u\n",
				l, BUF_SIZE);
			exit_program(-2);
		}

		/* Read in the entry */
		fread(buf, l, sizeof(*buf), in);

		printf("Entry size=%d, code=0x%X\n", l, buf[0]);

		/* Read the next entry size */
		fread(&l2, 1, sizeof(unsigned short), in);
		l = ntohs(l2);
	}

	exit_program(0);
	return 0;
}

void check_usage(int argc, char** argv)
{
	if (argc != 2)
	{
		fprintf(stderr, "Usage: %s <trace_file>\n", argv[0]);
		exit_program(1);
	}
}

FILE* open_file(char* filename, char* spec)
{
	FILE* fp = fopen(filename, spec);
	if (!fp)
	{
		perror("fopen");
		exit_program(1);
	}
	return fp;
}

void caught_signal(int sig)
{
	fprintf(stderr, "Caught signal %d\n", sig);
	exit_program(0);
}

void exit_program(int code)
{
	exit(code);
}

void exit_program_err(int code, char* func)
{
	perror(func);
	exit_program(code);
}
