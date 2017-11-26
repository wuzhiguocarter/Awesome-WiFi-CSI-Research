#include "util.h"

#include <math.h>

double db(double x)
{
	if (fabs(x) < 0.0001) return -10000;
	return log(x) * _10_BY_LN_10;
}
double exp_10(double x)
{
	return exp(x * LN_10_BY_10);
}
