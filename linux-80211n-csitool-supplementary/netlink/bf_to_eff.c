#include "bf_to_eff.h"
#include "iwl_structs.h"
#include "q_approx.h"
#include "util.h"

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define DB_1		(1.2589254117941673)	/* 1 dB */
#define DB_1_5		(1.4125375446227544)
#define DB_3_5		(2.2387211385683394)
#define DB_4_5		(2.8183829312644537)
#define DB_5		(3.1622776601683795)
#define DB_N1		(0.79432823472428149)	/* -1 dB */
#define DB_N1_5		(0.70794578438413791)
#define DB_N3_5		(0.44668359215096315)
#define DB_N4_5		(0.35481338923357547)
#define DB_N5		(0.31622776601683794)

#define DEBUG1	(0)
#define DEBUG2	(0)
#define DEBUG3	(0)
#define DEBUG (0+DEBUG1+DEBUG2+DEBUG3)

/*
 * If true, will also compute antenna pairs like AC and BC instead of just A,
 * AB, and ABC
 */
#define	MULTI	(1)

/**
 * These arrays are used to convert the SNR calculated from a received packet
 * of a certain rate to the SNR assuming that packet had been tx'ed with MCS 0,
 * i.e. SISO-BPSK-1/2.  And to do the reverse, i.e. convert an SNR for MCS 0 to
 * an SNR with some other MCS.
 *
 * These values are iwl5300-specific and are reported by the response to the
 * TX_DBM_LIMIT_CMD.
 *
 * On something like 7 different cards I uniformly found the same values:
 *
 * New txpower limit: 30
 * BPSK A:	 0x1e 0x18 0x15
 * QAM-64-2/3 A: 0x1b 0x18 0x15
 * QAM-64-3/4 A: 0x17 0x17 0x15
 * QAM-64-5/6 A: 0x14 0x14 0x14
 *
 * where the values across are for increasing numbers of streams.
 *
 * These values are in half-dBm, i.e. 0x1e = 30 = 15 dBm.  So, to explain the
 * table, the first row is used to convert SISO SNRs to MCS 0 SNRs.
 * 	MCS 0 -> MCS 0 is of course no change, a factor of 1.
 * 	MCS 5 -> MCS 0 is 0x1e - 0x1b = 3 * 0.5 = 1.5 dB = ~1.4125 as defined
 * 		by constant DB_1_5.
 * The code is similar for other entries.
 */
static const double power_convert_to_mcs_0_orig[12] = {
	/* Order is: BPSK, QAM-64-2/3, QAM-64-3/4, QAM-64-5/6 */
	1, DB_1_5, DB_3_5, DB_5,	/* SISO */
	2, 2, DB_3_5, DB_5,		/* MIMO2 */
	DB_4_5, DB_4_5, DB_4_5, DB_5,	/* MIMO3 */
};
static double power_convert_to_mcs_0[12] = {
	/* Order is: BPSK, QAM-64-2/3, QAM-64-3/4, QAM-64-5/6 */
	1, DB_1_5, DB_3_5, DB_5,	/* SISO */
	2, 2, DB_3_5, DB_5,		/* MIMO2 */
	DB_4_5, DB_4_5, DB_4_5, DB_5,	/* MIMO3 */
};
/**
 * This table is used to convert in the other direction, i.e. from an MCS 0 SNR
 * to an SNR that would be seen at some other MCS.  They are the multiplicative
 * inverse of the entries above; DB_N1_5 is -1.5 dB.
 */
static const double power_convert_from_mcs_0_orig[12] = {
	/* Order is: BPSK, QAM-64-2/3, QAM-64-3/4, QAM-64-5/6 */
	1, DB_N1_5, DB_N3_5, DB_N5,		/* SISO */
	0.5, 0.5, DB_N3_5, DB_N5,		/* MIMO2 */
	DB_N4_5, DB_N4_5, DB_N4_5, DB_N5,	/* MIMO3 */
};
static double power_convert_from_mcs_0[12] = {
	/* Order is: BPSK, QAM-64-2/3, QAM-64-3/4, QAM-64-5/6 */
	1, DB_N1_5, DB_N3_5, DB_N5,		/* SISO */
	0.5, 0.5, DB_N3_5, DB_N5,		/* MIMO2 */
	DB_N4_5, DB_N4_5, DB_N4_5, DB_N5,	/* MIMO3 */
};
/**
 * BPSK through QAM-16-3/4 are all same power as BPSK.
 * QAM-16 has different rates for all different coding schemes.
 */
static const uint32_t rate_to_pwr_index[24] = {
	0, 0, 0, 0, 0, 1, 2, 3,
	4, 4, 4, 4, 4, 5, 6, 7,
	8, 8, 8, 8, 8, 9, 10, 11,
};
#define PCTM0(x) (power_convert_to_mcs_0[x])
#define PCTM0O(x) (power_convert_to_mcs_0_orig[x])
#define PCFM0(x) (power_convert_from_mcs_0[x])
#define PCFM0O(x) (power_convert_from_mcs_0_orig[x])

void shift_power_tables(int8_t shift)
{
	int i;
	int j;

	/* Reset power tables to original values */
	for (j = 0; j < 12; ++j) {
		PCTM0(j) = PCTM0O(j);
		PCFM0(j) = PCFM0O(j);
	}

	/* Now do RSSI shifts */
	for (i = 0; i < shift; ++i) {
		for (j = 0; j < 12; ++j) {
			PCTM0(j) = PCTM0(j) * DB_N1;
			if (PCTM0(j) < PCTM0O(j&~3))
				PCTM0(j) = PCTM0O(j&~3);
			PCFM0(j) = PCFM0(j) * DB_1;
			if (PCFM0(j) > PCFM0O(j&~3))
				PCFM0(j) = PCFM0O(j&~3);
		}
	}

}

static void compute_11(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4]);
static void compute_31(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4]);
static void compute_32(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4]);
static void compute_33(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4]);
static void snr_31_in_32(int32_t *array, double snrs[2], double scale);
static void snr_31_in_33(int32_t *array, double snrs[3], double scale);
static void snr_32_in_33(int32_t *array, double snrs[3][2], double scale,
		int32_t scale_inv);
static void snr_11(int32_t *array, double *snrs, double scale);
static void snr_31(int32_t *array, double *snrs, double scale);
static void snr_32(int32_t *array, double *snrs, double scale,
		int32_t scale_inv);
static void snr_33(int32_t *array, double *snrs, double scale,
		int32_t scale_inv);

int no_noise_value = 0;

int calc_eff_snrs(struct iwl5000_bfee_notif *bfee,
		double eff_snrs[MAX_NUM_RATES][4])
{
	/* Number of antennas on each dimension */
	uint8_t Nrx = bfee->Nrx;
	uint8_t Ntx = bfee->Ntx;
	uint32_t i;
	uint16_t rate_n_flags = bfee->fake_rate_n_flags;

	/* If calculated length != actual length, exit early */
	uint32_t calc_len = (30 * (Nrx * Ntx * 2 * 8 + 3) + 7) / 8;
	if (calc_len != bfee->len)
		return 0;

	/* If not 3 RX antennas, exit */
	if (!((Nrx == 3) || ((Nrx == 1) && (Ntx == 1))))
		return 0;

	/* Now compute values needed for SNR calculation */
	uint8_t rssi[3] = {bfee->rssiA, bfee->rssiB, bfee->rssiC};
	int16_t noise = bfee->noise;
	if (noise == -127) {
		if (!no_noise_value) {
			fprintf(stderr, "warning: packet has no noise value\n");
			no_noise_value = 1;
		}
		noise = -95;
	}
	int16_t agc = bfee->agc;
	double noise_inverted = exp_10(-44 - noise - agc);
	/* If Nrx < 3, some RSSIs might be 0, but that has negligible effect */
	double signal = exp_10(rssi[0]) + exp_10(rssi[1]) + exp_10(rssi[2]);
	double packet_snr = signal * noise_inverted *
		PCTM0(rate_to_pwr_index[rate_n_flags & 0x1f]);
#if DEBUG
	printf("PCTM0(%d) is %lf\n", rate_n_flags & 0x1f, PCTM0(rate_to_pwr_index[rate_n_flags & 0x1f]));
	printf("PCFM0(%d) is %lf\n", rate_n_flags & 0x1f, PCFM0(rate_to_pwr_index[rate_n_flags & 0x1f]));
#endif
	/**
	 * As long as we use all 3 RX antennas, antenna selection doesn't
	 * matter without beam forming
	uint8_t antenna_sel = bfee->antenna_sel;
	 */

#if DEBUG
	printf("Ntx=%u Nrx=%u\n", (uint32_t)Ntx, (uint32_t)Nrx);
	printf("calc_len: %u\n", calc_len);
	printf("agc: %d noise: %d\n", agc, noise);
	printf("signal: %lf\n", signal);
	printf("packet_snr: %lf\n", packet_snr/30);
	printf("rssis: %d %d %d\n", rssi[0], rssi[1],rssi[2]);
	printf("snrs: %d %d %d\n", rssi[0]-agc-noise-44, rssi[1]-agc-noise-44,rssi[2]-agc-noise-44);
	printf("rate: 0x%x\n", rate_n_flags);
#endif

	/* Before we start calculating, zero out eff snrs */
	memset(eff_snrs, 0, MAX_NUM_RATES * 4 * sizeof(double));

	/* Depending on the numbers of streams, compute effective SNRs */
	if ((Nrx == 1) && (Ntx == 1))
		compute_11(bfee->payload, packet_snr, eff_snrs);
	else if (Ntx == 1)
		compute_31(bfee->payload, packet_snr, eff_snrs);
	else if (Ntx == 2)
		compute_32(bfee->payload, packet_snr, eff_snrs);
	else if (Ntx == 3)
		compute_33(bfee->payload, packet_snr, eff_snrs);

	printf("eff_snrs:\n");
	for (i = 0; i < MAX_NUM_RATES; ++i) {
		if (i == 0)
			printf("   SISO:\n");
		else if (i == FIRST_MIMO2)
			printf("   MIMO2:\n");
		else if (i == FIRST_MIMO3)
			printf("   MIMO3:\n");
		printf("\t %.1lf %.1lf %.1lf %.1lf\n",
				db(eff_snrs[i][0]), db(eff_snrs[i][1]),
				db(eff_snrs[i][2]), db(eff_snrs[i][3]));
	}

	return Ntx;
}

static void compute_add_siso_bers(double bers[4], const double snr)
{
	bers[0] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[0])*2);
	bers[1] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[1]));
	bers[2] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[3])/5);
	bers[3] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[6])/21);
#if DEBUG1
	printf("snr=%lf, bers=%lf %lf %lf %lf\n", snr, qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[0])*2), qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[1])), qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[3])/5), qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[6])/21));
#endif
}

static void compute_add_mimo2_bers(double bers[4], double snr)
{
	/**
	 * We actually already took the factor of 3 dB for 2 streams out
	 * above in MMSE calculation, add it back in here so the below
	 * power compensation crap works.
	 */
	snr = snr * 2;
	bers[0] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[8])*2);
	bers[1] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[9]));
	bers[2] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[11])/5);
	bers[3] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[14])/21);
}

static void compute_add_mimo3_bers(double bers[4], double snr)
{
	/**
	 * We actually already took the factor of 4.5 dB for 3 streams out
	 * above in MMSE calculation, add it back in here so the below
	 * power compensation crap works.
	 */
	snr = snr * DB_4_5;
	bers[0] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[16])*2);
	bers[1] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[17]));
	bers[2] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[19])/5);
	bers[3] += qfunc_sqrt(snr*PCFM0(rate_to_pwr_index[22])/21);
}


static void compute_11(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4])
{
	const uint32_t size = 1*1*2*8+3; /* 1 byte + 3 bits for index */
	const uint32_t size_byte = size / 8;
	const uint32_t size_rem = size % 8;
	uint32_t index_byte = 0;
	uint32_t index_rem = 3;
	uint32_t cur;
	int8_t *curi = (int8_t *)&cur;
	uint32_t i, j;
	int32_t t;

	double snr_acc = 0;
	double snrs[30];
	double bers[4] = {0, 0, 0, 0};
	int32_t csi[30][1*1*2];
	/**
	 * Loop through subcarriers, computing ber-subcarrier SNRs
	 * and accumulating total sum of matrix values
	 */
	for (i = 0; i < 30; ++i) {
		/* Get 4 bytes (Need 2) */
		cur = *((uint32_t *)&payload[index_byte]);
		/* Shift down by remainder */
		if (index_rem != 0)
			cur >>= index_rem;

		/* Convert int8_t to int32_t and update SNR accumulator */
		for (j = 0; j < 1*1*2; ++j) {
			t = curi[j];
			csi[i][j] = t;
			snr_acc += t*t;
		}

		/* Update index_byte and index_rem */
		index_byte += size_byte;
		index_rem += size_rem;
		if (index_rem > 7) {
			index_byte++;
			index_rem -= 8;
		}
	}

	/* Compute SNR correction factor */
	double scale = 30 * packet_snr / snr_acc;
#if DEBUG1
	printf("scale=%f\n", scale);
#endif

	/* Compute per-subcarrier BERs */
	for (i = 0; i < 30; ++i) {
		snr_11(csi[i], &snrs[i], scale);
	}

	/* Compute average BERs (div 30 is below) */
	for (i = 0; i < 30; ++i) {
#if DEBUG1
		printf("\tAcc BER %u=%lf %lf %lf %lf\n", i, bers[0], bers[1], bers[2]*3/4, bers[3]*7/12);
#endif
		compute_add_siso_bers(bers, snrs[i]);
	}

#if DEBUG1
	printf("total ber: 1=%lf 2=%lf 3=%lf 4=%lf\n", bers[0], bers[1], bers[2]*3/4, bers[3]*7/12);
#endif

	/* Effective SNR from BERs */
	eff_snrs[0][0] = qfuncinv_sqrd(bers[0]/30)/2;
	eff_snrs[0][1] = qfuncinv_sqrd(bers[1]/30);
	eff_snrs[0][2] = qfuncinv_sqrd(bers[2]/30)*5;
	eff_snrs[0][3] = qfuncinv_sqrd(bers[3]/30)*21;
}

static void compute_31(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4])
{
	const uint32_t size = 3*1*2*8+3; /* 6 bytes + 3 bits for index */
	const uint32_t size_byte = size / 8;
	const uint32_t size_rem = size % 8;
	uint32_t index_byte = 0;
	uint32_t index_rem = 3;
	uint64_t cur;
	int8_t *curi = (int8_t *)&cur;
	uint32_t i, j;
	int32_t t;

	double snr_acc = 0;
	double snrs[30];
	double bers[4] = {0, 0, 0, 0};
	int32_t csi[30][3*1*2];
	/**
	 * Loop through subcarriers, computing ber-subcarrier SNRs
	 * and accumulating total sum of matrix values
	 */
	for (i = 0; i < 30; ++i) {
		/* Get 8 bytes (Need 6) */
		cur = *((uint64_t *)&payload[index_byte]);
		/* Shift down by remainder */
		if (index_rem != 0)
			cur >>= index_rem;

		/* Convert int8_t to int32_t and update SNR accumulator */
		for (j = 0; j < 3*1*2; ++j) {
			t = curi[j];
			csi[i][j] = t;
			snr_acc += t*t;
		}

		/* Update index_byte and index_rem */
		index_byte += size_byte;
		index_rem += size_rem;
		if (index_rem > 7) {
			index_byte++;
			index_rem -= 8;
		}
	}

	/* Compute SNR correction factor */
	double scale = 30 * packet_snr / snr_acc;
#if DEBUG1
	printf("scale=%f\n", scale);
#endif

	/* Compute per-subcarrier BERs */
	for (i = 0; i < 30; ++i) {
		snr_31(csi[i], &snrs[i], scale);
	}

	/* Compute average BERs (div 30 is below) */
	for (i = 0; i < 30; ++i) {
#if DEBUG1
		printf("\tAcc BER %u=%lf %lf %lf %lf\n", i, bers[0], bers[1], bers[2]*3/4, bers[3]*7/12);
#endif
		compute_add_siso_bers(bers, snrs[i]);
	}

#if DEBUG1
	printf("total ber: 1=%lf 2=%lf 3=%lf 4=%lf\n", bers[0], bers[1], bers[2]*3/4, bers[3]*7/12);
#endif

	/* Effective SNR from BERs */
	eff_snrs[0][0] = qfuncinv_sqrd(bers[0]/30)/2;
	eff_snrs[0][1] = qfuncinv_sqrd(bers[1]/30);
	eff_snrs[0][2] = qfuncinv_sqrd(bers[2]/30)*5;
	eff_snrs[0][3] = qfuncinv_sqrd(bers[3]/30)*21;
}

static void compute_32(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4])
{
	const uint32_t size = 3*2*2*8+3; /* 12 bytes + 3 bits for index */
	const uint32_t size_byte = size / 8;
	const uint32_t size_rem = size % 8;
	uint32_t index_byte = 0;
	uint32_t index_rem = 3;
	uint64_t cur[2];
	int8_t *curi = (int8_t *)cur;
	uint32_t i, j;
	int32_t t;

	double snrs_1[30][2];
	double snrs_2[30][2];
	int32_t snr_acc = 0;
	double bers_1[2][4] = { {0,0,0,0}, {0,0,0,0}, };
	double bers_2[4] = {0,0,0,0};
	int32_t csi[30][3*2*2];
	/**
	 * Loop through subcarriers, casting int8_t to int32_t
	 * and accumulating total sum of matrix values
	 */
	for (i = 0; i < 30; ++i) {
		/* Get 16 bytes (Need 12) */
		cur[0] = *((uint64_t *)&payload[index_byte]);
		cur[1] = *((uint64_t *)&payload[index_byte] + 1);

		/* Shift down by remainder */
		if (index_rem != 0) {
			cur[0] >>= index_rem;
			cur[0] |= (cur[1] << (64-index_rem));
			cur[1] >>= index_rem;
		}

		/* Convert int8_t to int32_t and update SNR accumulator */
		for (j = 0; j < 3*2*2; ++j) {
			t = curi[j];
			csi[i][j] = t;
			snr_acc += t*t;
		}

		/* Update index_byte and index_rem */
		index_byte += size_byte;
		index_rem += size_rem;
		if (index_rem > 7) {
			index_byte++;
			index_rem -= 8;
		}
	}

	/* Compute SNR correction factor and inverted for use in MMSE */
	double scale = 30 * packet_snr / snr_acc;
	double scale2 = 30 * packet_snr / snr_acc / 2;
	int32_t scale_inv2 = (int32_t) (snr_acc * 2 / (30 * packet_snr));

	/* Compute per-subcarrier BERs */
	for (i = 0; i < 30; ++i) {
		snr_31_in_32(csi[i], snrs_1[i], scale);
		snr_32(csi[i], snrs_2[i], scale2, scale_inv2);
	}

#if MULTI
	int8_t n_siso = 2;
#else
	int8_t n_siso = 1;
#endif

	/* Compute average BERs (div 30 is below) */
	for (i = 0; i < 30; ++i) {
		/* Update SISO bers */
		for (j = 0; j < n_siso; ++j) {
			compute_add_siso_bers(bers_1[j], snrs_1[i][j]);
#if DEBUG1
			printf("\tAcc BER %u=%lf %lf %lf %lf\n", i, bers_1[0][0], bers_1[0][1], bers_1[0][2]*3/4, bers_1[0][3]*7/12);
#endif
		}
		/* Update MIMO2 bers */
		for (j = 0; j < 2; ++j) {
			compute_add_mimo2_bers(bers_2, snrs_2[i][j]);

#if DEBUG2
			printf("i=%u j=%u bers_1[j][0]=%lf snrs_1[i][j]=%lf\n",
					i, j, bers_1[j][0], snrs_1[i][j]);
			printf("i=%u j=%u bers_2[j][0]=%lf snrs_2[i][j]=%lf\n",
					i, j, bers_2[0], snrs_2[i][j]);
#endif

		}
	}

#if DEBUG1
	printf("total ber1: 1=%lf 2=%lf 3=%lf 4=%lf\n", bers_1[0][0], bers_1[0][1], bers_1[0][2]*3/4, bers_1[0][3]*7/12);
#endif

	/* Effective SNR from BERs */
	/* SISO */
	for (j = 0; j < n_siso; ++j) {
		eff_snrs[j][0] = qfuncinv_sqrd(bers_1[j][0]/30)/2;
		eff_snrs[j][1] = qfuncinv_sqrd(bers_1[j][1]/30);
		eff_snrs[j][2] = qfuncinv_sqrd(bers_1[j][2]/30)*5;
		eff_snrs[j][3] = qfuncinv_sqrd(bers_1[j][3]/30)*21;
	}
	/* MIMO2 */
	eff_snrs[FIRST_MIMO2][0] = qfuncinv_sqrd(bers_2[0]/60)/2;
	eff_snrs[FIRST_MIMO2][1] = qfuncinv_sqrd(bers_2[1]/60);
	eff_snrs[FIRST_MIMO2][2] = qfuncinv_sqrd(bers_2[2]/60)*5;
	eff_snrs[FIRST_MIMO2][3] = qfuncinv_sqrd(bers_2[3]/60)*21;
}

static void compute_33(const uint8_t *payload, double packet_snr,
		double eff_snrs[MAX_NUM_RATES][4])
{
	const uint32_t size = 3*3*2*8+3; /* 12 bytes + 3 bits for index */
	const uint32_t size_byte = size / 8;
	const uint32_t size_rem = size % 8;
	uint32_t index_byte = 0;
	uint32_t index_rem = 3;
	uint64_t cur[3];
	int8_t *curi = (int8_t *)cur;
	uint32_t i, j, k;
	int32_t t;

	int32_t snr_acc = 0;
	double snrs_1[30][3];
	double snrs_2[30][3][2];
	double snrs_3[30][3];
	double bers_1[3][4] = { {0,0,0,0}, {0,0,0,0}, {0,0,0,0}, };
	double bers_2[3][4] = { {0,0,0,0}, {0,0,0,0}, {0,0,0,0}, };
	double bers_3[4] = {0,0,0,0};
	int32_t csi[30][3*3*2];
	for (i = 0; i < 30; ++i) {
		/* Get 24 bytes (need 18) */
		cur[0] = *((uint64_t *)&payload[index_byte]);
		cur[1] = *((uint64_t *)&payload[index_byte] + 1);
		cur[2] = *((uint64_t *)&payload[index_byte] + 2);

		/* Shift down by remainder */
		if (index_rem != 0) {
			cur[0] >>= index_rem;
			cur[0] |= (cur[1] << (64-index_rem));
			cur[1] >>= index_rem;
			cur[1] |= (cur[2] << (64-index_rem));
			cur[2] >>= index_rem;
		}

		/* Convert int8_t to int32_t and update SNR accumulator */
		for (j = 0; j < 3*3*2; ++j) {
			t = curi[j];
			csi[i][j] = t;
			snr_acc += t*t;
		}

		/* Update index_byte and index_rem */
		index_byte += size_byte;
		index_rem += size_rem;
		if (index_rem > 7) {
			index_byte++;
			index_rem -= 8;
		}
	}

	/* Compute SNR correction factor */
	double scale = 30 * packet_snr / snr_acc;
	double scale2 = 30 * packet_snr / snr_acc / 2;
	int32_t scale_inv2 = (int32_t) (snr_acc * 2 / (30 * packet_snr));
	double scale3 = 30 * packet_snr / snr_acc * DB_N4_5;
	int32_t scale_inv3 = (int32_t) (snr_acc * DB_4_5 / (30 * packet_snr));
#if DEBUG
	printf("scale=%lf\n", scale);
	printf("scale_inv2=%d\n", scale_inv2);
	printf("scale_inv3=%d\n", scale_inv3);
#endif

	for (i = 0; i < 30; ++i) {
		/* Pass in bytes as int8_t array */
		snr_31_in_33(csi[i], snrs_1[i], scale);
		snr_32_in_33(csi[i], snrs_2[i], scale2, scale_inv2);
		snr_33(csi[i], snrs_3[i], scale3, scale_inv3);
#if DEBUG3
		printf("snrs_3[%u] = %f %f %f\n", i, snrs_3[i][0], snrs_3[i][1], snrs_3[i][2]);
#endif
	}

#if MULTI
	int8_t n_siso = 3;
	int8_t n_mimo2 = 3;
#else
	int8_t n_siso = 1;
	int8_t n_mimo2 = 1;
#endif

	/* Compute average BERs (div 30 is below) */
	for (i = 0; i < 30; ++i) {
		for (j = 0; j < n_siso; ++j)
			compute_add_siso_bers(bers_1[j], snrs_1[i][j]);

		for (j = 0; j < n_mimo2; ++j) {
			for (k = 0; k < 2; ++k)
				compute_add_mimo2_bers(bers_2[j],
						snrs_2[i][j][k]);
		}

		for (j = 0; j < 3; ++j) {
			compute_add_mimo3_bers(bers_3, snrs_3[i][j]);
#if DEBUG3
			printf("i=%u j=%u bers_1[j][0]=%lf snrs_1[i][j]=%lf\n",
					i, j, bers_1[j][0], snrs_1[i][j]);
			printf("i=%u j=%u bers_2[j][0]=%lf "
					"snrs_2[i][0][j]=%lf\n",
					i, j, bers_2[j][0], snrs_2[i][0][j]);
			printf("i=%u j=%u bers_3[0]=%lf snrs_3[i][j]=%lf\n",
					i, j, bers_3[0], snrs_3[i][j]);
#endif

		}
	}

#if DEBUG1
	printf("total ber1: 1=%lf 2=%lf 3=%lf 4=%lf\n", bers_1[0][0], bers_1[0][1], bers_1[0][2]*3/4, bers_1[0][3]*7/12);
	printf("total ber2: 1=%lf 2=%lf 3=%lf 4=%lf\n", bers_1[1][0], bers_1[1][1], bers_1[1][2]*3/4, bers_1[1][3]*7/12);
	printf("total ber3: 1=%lf 2=%lf 3=%lf 4=%lf\n", bers_1[2][0], bers_1[2][1], bers_1[2][2]*3/4, bers_1[2][3]*7/12);
#endif

	/* Effective SNR from BERs */
	/* SISO */
	for (j = 0; j < n_siso; ++j) {
		eff_snrs[j][0] = qfuncinv_sqrd(bers_1[j][0]/30)/2;
		eff_snrs[j][1] = qfuncinv_sqrd(bers_1[j][1]/30);
		eff_snrs[j][2] = qfuncinv_sqrd(bers_1[j][2]/30)*5;
		eff_snrs[j][3] = qfuncinv_sqrd(bers_1[j][3]/30)*21;
	}
	/* MIMO2 */
	for (j = 0; j < n_mimo2; ++j) {
		eff_snrs[FIRST_MIMO2+j][0] = qfuncinv_sqrd(bers_2[j][0]/60)/2;
		eff_snrs[FIRST_MIMO2+j][1] = qfuncinv_sqrd(bers_2[j][1]/60);
		eff_snrs[FIRST_MIMO2+j][2] = qfuncinv_sqrd(bers_2[j][2]/60)*5;
		eff_snrs[FIRST_MIMO2+j][3] = qfuncinv_sqrd(bers_2[j][3]/60)*21;
	}
	/* MIMO3 */
	eff_snrs[FIRST_MIMO3][0] = qfuncinv_sqrd(bers_3[0]/90)/2;
	eff_snrs[FIRST_MIMO3][1] = qfuncinv_sqrd(bers_3[1]/90);
	eff_snrs[FIRST_MIMO3][2] = qfuncinv_sqrd(bers_3[2]/90)*5;
	eff_snrs[FIRST_MIMO3][3] = qfuncinv_sqrd(bers_3[3]/90)*21;
}

static void snr_11_calc(int32_t ar, int32_t ac, double *snrs, double scale)
{
	int32_t snr = ar*ar + ac*ac;
	snrs[0] = snr * scale;
#if DEBUG1
	printf("A=%d+%dj, snr=%d scaled=%lf\n", ar, ac, snr, snrs[0]);
#endif
}

static void snr_11(int32_t *array, double *snrs, double scale)
{
	snr_11_calc(array[0], array[1], snrs, scale);
}

static void snr_31_calc(int32_t ar, int32_t ac, int32_t br, int32_t bc,
		int32_t cr, int32_t cc, double *snrs, double scale)
{
	int32_t snr = ar*ar + ac*ac + br*br + bc*bc + cr*cr + cc*cc;
	snrs[0] = snr * scale;
#if DEBUG1
	printf("A=%d+%dj, B=%d+%dj, C=%d+%dj, snr=%d scaled=%lf\n", ar, ac, br, bc, cr, cc, snr, snrs[0]);
#endif
}

static void snr_31(int32_t *array, double *snrs, double scale)
{
	snr_31_calc(array[0], array[1], array[2], array[3], array[4], array[5],
			snrs, scale);
}

/**
 * Matrix is:
 * [A B
 *  C D
 *  E F];
 * Entries are complex
 */
static void snr_31_in_32(int32_t *array, double snrs[2], double scale)
{
	int32_t ar = array[0], ac = array[1];
	int32_t cr = array[4], cc = array[5];
	int32_t er = array[8], ec = array[9];

	/* First column */
	snr_31_calc(ar, ac, cr, cc, er, ec, &snrs[0], scale);
#if MULTI
	int32_t br = array[2], bc = array[3];
	int32_t dr = array[6], dc = array[7];
	int32_t fr = array[10], fc = array[11];
	/* Second column */
	snr_31_calc(br, bc, dr, dc, fr, fc, &snrs[1], scale);
#endif
}

/**
 * Matrix is:
 * [A B C
 *  D E F
 *  G H I];
 * Entries are complex
 */
static void snr_31_in_33(int32_t *array, double snrs[3], double scale)
{
	int32_t ar = array[0], ac = array[1];
	int32_t dr = array[6], dc = array[7];
	int32_t gr = array[12], gc = array[13];
#if MULTI
	int32_t br = array[2], bc = array[3];
	int32_t cr = array[4], cc = array[5];
	int32_t er = array[8], ec = array[9];
	int32_t fr = array[10], fc = array[11];
	int32_t hr = array[14], hc = array[15];
	int32_t ir = array[16], ic = array[17];
#endif

	/* First column */
	snr_31_calc(ar, ac, dr, dc, gr, gc, &snrs[0], scale);
#if MULTI
	/* Second column */
	snr_31_calc(br, bc, er, ec, hr, hc, &snrs[1], scale);
	/* Third column */
	snr_31_calc(cr, cc, fr, fc, ir, ic, &snrs[2], scale);
#endif
}

static void snr_32_calc(int32_t ar, int32_t ac, int32_t br, int32_t bc,
		int32_t cr, int32_t cc, int32_t dr, int32_t dc,
		int32_t er, int32_t ec, int32_t fr, int32_t fc,
		double *snrs, double scale, int32_t scale_inv)
{
	/* First, compute A^H * A */
	int32_t x11r = ar*ar + ac*ac + cr*cr + cc*cc + er*er + ec*ec;
	int32_t x12r = ar*br + ac*bc + cr*dr + cc*dc + er*fr + ec*fc;
	int32_t x12c = ar*bc - ac*br + cr*dc - cc*dr + er*fc - ec*fr;
	int32_t x21r = x12r;
	int32_t x21c = -x12c;
	int32_t x22r = br*br + bc*bc + dr*dr + dc*dc + fr*fr + fc*fc;
#if DEBUG2
	printf("A=%d+%dj, B=%d+%dj, C=%d+%dj, D=%d+%dj, E=%d+%dj, F=%d+%dj, scale_inv=%d\n", ar, ac, br, bc, cr, cc, dr, dc, er, ec, fr, fc, scale_inv);
	printf("A'*A = %d+%dj %d+%dj %d+%dj %d+%dj\n",
			x11r, 0, x12r, x12c, x21r, x21c, x22r, 0);
#endif

	/* For MMSE, add in the inverse scaling factor */
	x11r += scale_inv;
	x22r += scale_inv;

	/* Now compute the inverse of the new matrix
	   .. but actually only the entries we need */
	int32_t det = x11r * x22r - x21r * x12r + x21c * x12c;
#if DEBUG2
	printf("det = %d\n", det);
#endif
	/* For MMSE, subtract 1 after to remove bias */
	snrs[0] = det * scale / (double)x22r - 1;
	snrs[1] = det * scale / (double)x11r - 1;
}

/**
 * Matrix is:
 * [A B
 *  C D
 *  E F];
 * Entries are complex
 */
static void snr_32(int32_t *array, double *snrs, double scale, int32_t scale_inv)
{
	int32_t ar = array[0], ac = array[1];
	int32_t br = array[2], bc = array[3];
	int32_t cr = array[4], cc = array[5];
	int32_t dr = array[6], dc = array[7];
	int32_t er = array[8], ec = array[9];
	int32_t fr = array[10], fc = array[11];

	snr_32_calc(ar, ac, br, bc, cr, cc, dr, dc, er, ec, fr, fc, snrs,
			scale, scale_inv);
}

/**
 * Matrix is:
 * [A B C
 *  D E F
 *  G H I];
 * Entries are complex
 */
static void snr_32_in_33(int32_t *array, double snrs[3][2], double scale, int32_t scale_inv)
{
	int32_t ar = array[0], ac = array[1];
	int32_t br = array[2], bc = array[3];
	int32_t dr = array[6], dc = array[7];
	int32_t er = array[8], ec = array[9];
	int32_t gr = array[12], gc = array[13];
	int32_t hr = array[14], hc = array[15];
#if MULTI
	int32_t cr = array[4], cc = array[5];
	int32_t fr = array[10], fc = array[11];
	int32_t ir = array[16], ic = array[17];
#endif

	/* First, antennas A and B (first 2 columns) */
	snr_32_calc(ar, ac, br, bc, dr, dc, er, ec, gr, gc, hr, hc,
			snrs[0], scale, scale_inv);
#if MULTI
	/* Second, antennas A and C (outer columns) */
	snr_32_calc(ar, ac, cr, cc, dr, dc, fr, fc, gr, gc, ir, ic,
			snrs[1], scale, scale_inv);
	/* Last, antennas B and C (second 2 columns) */
	snr_32_calc(br, bc, cr, cc, er, ec, fr, fc, hr, hc, ir, ic,
			snrs[2], scale, scale_inv);
#endif
}

/**
 * Matrix is:
 * [A B C
 *  D E F
 *  G H I];
 * Entries are complex
 */
static void snr_33_calc(int32_t ar, int32_t ac, int32_t br, int32_t bc,
		int32_t cr, int32_t cc, int32_t dr, int32_t dc,
		int32_t er, int32_t ec, int32_t fr, int32_t fc,
		int32_t gr, int32_t gc, int32_t hr, int32_t hc,
		int32_t ir, int32_t ic,
		double *snrs, double scale, int32_t scale_inv)
{

#if DEBUG3
	printf("%d+%dj %d+%dj %d+%dj\n"
	       "%d+%dj %d+%dj %d+%dj\n"
	       "%d+%dj %d+%dj %d+%dj\n", ar, ac, br, bc, cr, cc, dr, dc, er, ec, fr, fc, gr, gc, hr, hc, ir, ic);
#endif

	/* First, compute A^H * A */
	/* .. Diagonals */
	int64_t x11r = ar*ar + ac*ac + dr*dr + dc*dc + gr*gr + gc*gc;
	int64_t x22r = br*br + bc*bc + er*er + ec*ec + hr*hr + hc*hc;
	int64_t x33r = cr*cr + cc*cc + fr*fr + fc*fc + ir*ir + ic*ic;
	/* .. 12, 21 */
	int64_t x12r = ar*br + ac*bc + dr*er + dc*ec + gr*hr + gc*hc;
	int64_t x12c = ar*bc - ac*br + dr*ec - dc*er + gr*hc - gc*hr;
	int64_t x21r = x12r;
	int64_t x21c = -x12c;
	/* .. 13, 31 */
	int64_t x13r = ar*cr + ac*cc + dr*fr + dc*fc + gr*ir + gc*ic;
	int64_t x13c = ar*cc - ac*cr + dr*fc - dc*fr + gr*ic - gc*ir;
	int64_t x31r = x13r;
	int64_t x31c = -x13c;
	/* .. 23, 32 */
	int64_t x23r = br*cr + bc*cc + er*fr + ec*fc + hr*ir + hc*ic;
	int64_t x23c = br*cc - bc*cr + er*fc - ec*fr + hr*ic - hc*ir;
	int64_t x32r = x23r;
	int64_t x32c = -x23c;

#if DEBUG3
	printf("%lld+%lldj %lld+%lldj %lld+%lldj\n"
	       "%lld+%lldj %lld+%lldj %lld+%lldj\n"
	       "%lld+%lldj %lld+%lldj %lld+%lldj\n", x11r, (int64_t)0, x12r, x12c, x13r, x13c, x21r, x21c, x22r, (int64_t)0, x23r, x23c, x31r, x31c, x32r, x32c, x33r, (int64_t)0);
#endif

	/* Now add I * 1/scale */
	x11r += scale_inv;
	x22r += scale_inv;
	x33r += scale_inv;

	int64_t det11r = x22r*x33r - x23r*x32r + x23c*x32c;
#if DEBUG3
	printf("det11 = %" PRId64 "\n", det11r);
#endif

	int64_t det12r = x21r*x33r - x23r*x31r + x23c*x31c;
	int64_t det12c = x21c*x33r - x23r*x31c - x23c*x31r;
#if DEBUG3
	printf("det12 = %" PRId64 "+%" PRId64 "j\n", det12r, det12c);
#endif

	int64_t det13r = x21r*x32r - x21c*x32c - x22r*x31r;
	int64_t det13c = x21r*x32c + x21c*x32r - x22r*x31c;
#if DEBUG3
	printf("det13 = %" PRId64 "+%" PRId64 "j\n", det13r, det13c);
#endif

	int64_t det22r = x11r*x33r - x13r*x31r + x13c*x31c;
#if DEBUG3
	printf("det22 = %" PRId64 "\n", det22r);
#endif

	int64_t det33r = x11r*x22r - x12r*x21r + x12c*x21c;
#if DEBUG3
	printf("det33 = %" PRId64 "\n", det33r);
#endif

	int64_t detr = x11r*det11r +
			-x12r*det12r + x12c*det12c +
			x13r*det13r - x13c*det13c;
#if DEBUG3
	printf("det = %" PRId64 "\n", detr);
#endif

	snrs[0] = detr * scale / (double) det11r - 1;
	snrs[1] = detr * scale / (double) det22r - 1;
	snrs[2] = detr * scale / (double) det33r - 1;
}

static void snr_33(int32_t *array, double *snrs, double scale, int32_t scale_inv)
{
	int32_t ar = array[0], ac = array[1];
	int32_t br = array[2], bc = array[3];
	int32_t cr = array[4], cc = array[5];
	int32_t dr = array[6], dc = array[7];
	int32_t er = array[8], ec = array[9];
	int32_t fr = array[10], fc = array[11];
	int32_t gr = array[12], gc = array[13];
	int32_t hr = array[14], hc = array[15];
	int32_t ir = array[16], ic = array[17];

	snr_33_calc(ar, ac, br, bc, cr, cc, dr, dc, er, ec, fr, fc, gr, gc,
			hr, hc, ir, ic, snrs, scale, scale_inv);
}
