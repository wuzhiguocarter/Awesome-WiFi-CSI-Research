/*
 * (c) 2011 Daniel Halperin <dhalperi@cs.washington.edu>
 */
#include "bfee.h"

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
	uint8_t buf[BUF_SIZE];
	int32_t ret;
	uint16_t l, l2;
	FILE* in;
	FILE* out;
	uint8_t code;
	size_t read;
	struct iwl_bfee_notif *bfee;
	uint16_t fake_rate_n_flags;
	int check_Nrx;
	uint8_t Nrx;

	/* Make sure usage is correct */
	check_usage(argc, argv);

	/* Open and check log file */
	in = open_file(argv[1], "r");

	/* Read in fake rate and flags */
	sscanf(argv[2], "%hx", &fake_rate_n_flags);

	/* If optional Nrx argument was provided, get it */
	if (argc > 4) {
		check_Nrx = 1;
		sscanf(argv[4], "%hhu", &Nrx);
	} else {
		check_Nrx = 0;
	}

	/* Program exited successfully */
	ret = 0;

	/* Read the next entry size */
	fread(&l2, 1, sizeof(unsigned short), in);
	l = ntohs(l2);
	while (!feof(in)) {
		/* Sanity-check the entry size */
		if (l == 0) {
			fprintf(stderr, "Error: got entry size=0\n");
			ret = -1;
			break;
		} else if (l > BUF_SIZE) {
			fprintf(stderr,
				"Error: got entry size %u > BUF_SIZE=%u\n",
				l, BUF_SIZE);
			ret = -2;
			break;
		}

		/* Read in the entry */
		read = sizeof(*bfee) + 1;
		if (l < read)
			read = l;
		fread(buf, read, 1, in);
		code = buf[0];

		if (code != 0xBB)
			goto skip;

		bfee = (void *)&buf[1];
		if (bfee->fake_rate_n_flags != fake_rate_n_flags)
			goto skip;
		if (check_Nrx && bfee->Nrx != Nrx)
			goto skip;

		/* Open and check output file */
		out = open_file(argv[3], "wx");
		/* Write it out */
		fread(&buf[1+sizeof(*bfee)], l-read, 1, in);
		fwrite(&l2, 2, 1, out);
      		fwrite(buf, 1, l, out);
		fclose(out);
		break;

skip:
		fseek(in, l - read, SEEK_CUR);

		/* Read the next entry size */
		fread(&l2, 1, sizeof(unsigned short), in);
		l = ntohs(l2);
	}

	fclose(in);

	exit_program(ret);
	return ret;
}

void check_usage(int argc, char** argv)
{
	if (argc < 4 || argc > 5)
	{
		fprintf(stderr, "Usage: %s <trace_file> <fake_rate> <output_file> [optional: Nrx]\n", argv[0]);
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
