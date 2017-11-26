#ifndef __Q_APPROX_H__
#define __Q_APPROX_H__

/*
 * This is a LUT-based approximation for Q(sqrt(x)) using the order of
 * magnitude of x (exponent of x in double form) and then the first 4 bits of
 * the mantissa
 */
double qfunc_sqrt(double snr);
/*
 * LUT-based inverse of above
 */
double qfuncinv_sqrd(double ber);

#endif /* __Q_APPROX_H__ */
