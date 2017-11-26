#ifndef __BF_TO_EFF_H__
#define __BF_TO_EFF_H__

#include <stdint.h>

/* 3 different SISO configs = 3
 * 3 different MIMO2 configs = 3
 * 1 MIMO3 config = 1
 * total = 7 */
#define NUM_RATES_SISO	3
#define NUM_RATES_MIMO2	3
#define NUM_RATES_MIMO3	1
#define MAX_NUM_RATES		(NUM_RATES_SISO + NUM_RATES_MIMO2 + \
				 NUM_RATES_MIMO3)
#define FIRST_MIMO2		(NUM_RATES_SISO)
#define FIRST_MIMO3		(FIRST_MIMO2 + NUM_RATES_MIMO2)

struct iwl5000_bfee_notif;
int calc_eff_snrs(struct iwl5000_bfee_notif *bfee,
		double eff_snrs[MAX_NUM_RATES][4]);
void shift_power_tables(int8_t shift);

#endif /* __BF_TO_EFF_H__ */
