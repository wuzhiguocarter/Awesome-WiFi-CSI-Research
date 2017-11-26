#ifndef __UTIL_H__
#define __UTIL_H__

#include <stddef.h>
#include <stdint.h>
#include <sys/time.h>

#define LN_10_BY_10	(0.23025850929940459)
#define _10_BY_LN_10	(4.3429448190325175)

static inline uint64_t get_timestamp()
{
	struct timeval t;
	gettimeofday(&t, NULL);
	return t.tv_sec * 1000000ULL + t.tv_usec;
}
static inline uint32_t max(uint32_t a, uint32_t b)
{
	if (a < b)
		return b;
	return a;
}
static inline uint32_t min(uint32_t a, uint32_t b)
{
	if (a > b)
		return b;
	return a;
}
double db(double x);
double exp_10(double x);

#endif	/* __UTIL_H__ */
