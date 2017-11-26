CFLAGS = -O3 -Wall -static -Wno-unknown-pragmas
LDLIBS = -lorcon -lm -lrt
CC = gcc

ALL = random_packets

all: $(ALL)

clean:
	rm -f *.o $(ALL)

random_packets: random_packets.c util.o

util.c: util.h
