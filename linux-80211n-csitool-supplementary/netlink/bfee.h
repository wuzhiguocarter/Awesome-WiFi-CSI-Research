#ifndef __BFEE_H__
#define __BFEE_H__

#include <stdint.h>

/* Copied and modified by hand from iwl-commands.h */
struct iwl_bfee_notif {
	uint32_t /* __le32 */ timestamp_low;
	uint16_t /* __le16 */ bfee_count;
	uint16_t reserved1;
	uint8_t Nrx, Ntx;
	int8_t rssiA, rssiB, rssiC;
	int8_t noise;
	uint8_t agc, antenna_sel;
	uint16_t /* __le16 */ len;
	uint16_t /* __le16 */ fake_rate_n_flags;
	uint8_t payload[0];
} __attribute__ ((packed));

#endif
