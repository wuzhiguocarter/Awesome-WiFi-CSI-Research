#ifndef __IWL_STRUCTS_H__
#define __IWL_STRUCTS_H__

#include <stdint.h>

/**
 * WARNING!
 * This is not the official struct, I've reworked the fields to include
 * packet-level SNRs, noise floor, agc, and antenna selection values.
 */
struct iwl5000_bfee_notif {
	uint8_t reserved;
	int8_t noiseA, noiseB, noiseC;
	uint16_t bfee_count;
	uint16_t reserved1;
	uint8_t Nrx, Ntx;
	uint8_t rssiA, rssiB, rssiC;
	int8_t noise;
	uint8_t agc, antenna_sel;
	uint16_t len;
	uint16_t fake_rate_n_flags;
	uint8_t payload[0];
} __attribute__ ((packed));


/*
 * Struct containing the iperf info.
 * Enabled by setting IWL_CONN_FILTER_IPERF_MSK
 */
struct iperf_connector_msg {
	uint32_t iperf_magic_no;
	uint8_t  src_mac_addr[6];
	uint16_t reserved;
	uint32_t seq;
	uint8_t  good_pkt;
	uint8_t  reserved2;
	uint16_t reserved3;
};


/* Struct containing packet snr feedback received from the rx. */
/* Make sure this struct matches the one in file iwl-connector.h. */

struct snr_feedback_msg {
	uint8_t mcs;
	uint8_t snr_a;
	uint8_t snr_b;
	uint8_t snr_c;
};

/*
 * REPLY_TX = 0x1c (response)
 *
 * This response may be in one of two slightly different formats, indicated
 * by the frame_count field:
 *
 * 1)  No aggregation (frame_count == 1).  This reports Tx results for
 *     a single frame.  Multiple attempts, at various bit rates, may have
 *     been made for this frame.
 *
 * 2)  Aggregation (frame_count > 1).  This reports Tx results for
 *     2 or more frames that used block-acknowledge.  All frames were
 *     transmitted at same rate.  Rate scaling may have been used if first
 *     frame in this new agg block failed in previous agg block(s).
 *
 *     Note that, for aggregation, ACK (block-ack) status is not delivered here;
 *     block-ack has not been received by the time the 4965 records this status.
 *     This status relates to reasons the tx might have been blocked or aborted
 *     within the sending station (this 4965), rather than whether it was
 *     received successfully by the destination station.
 */
struct agg_tx_status {
	uint16_t status;
	uint16_t sequence;
} __attribute__ ((packed));

struct iwl5000_tx_resp {
	uint8_t frame_count;	/* 1 no aggregation, >1 aggregation */
	uint8_t bt_kill_count;	/* # blocked by bluetooth (unused for agg) */
	uint8_t failure_rts;	/* # failures due to unsuccessful RTS */
	uint8_t failure_frame;	/* # failures due to no ACK (unused for agg) */

	/* For non-agg:  Rate at which frame was successful.
	 * For agg:  Rate at which all frames were transmitted. */
	uint32_t rate_n_flags;	/* RATE_MCS_*  */

	/* For non-agg:  RTS + CTS + frame tx attempts time + ACK.
	 * For agg:  RTS + CTS + aggregation tx time + block-ack time. */
	uint16_t wireless_media_time;	/* uSecs */

	uint8_t pa_status;	/* RF power amplifier measurement (not used) */
	uint8_t pa_integ_res_a[3];
	uint8_t pa_integ_res_b[3];
	uint8_t pa_integ_res_C[3];

	uint32_t tfd_info;
	uint16_t seq_ctl;
	uint16_t byte_cnt;
	uint8_t tlc_info;
	uint8_t ra_tid;		/* tid (0:3), sta_id (4:7) */
	uint16_t frame_ctrl;
	/*
	 * For non-agg:  frame status TX_STATUS_*
	 * For agg:  status of 1st frame, AGG_TX_STATE_*; other frame status
	 *           fields follow this one, up to frame_count.
	 *           Bit fields:
	 *           11- 0:  AGG_TX_STATE_* status code
	 *           15-12:  Retry count for 1st frame in aggregation (retries
	 *                   occur if tx failed for this frame when it was a
	 *                   member of a previous aggregation block).  If rate
	 *                   scaling is used, retry count indicates the rate
	 *                   table entry used for all frames in the new agg.
	 *           31-16:  Sequence # for this frame's Tx cmd (not SSN!)
	 */
	struct agg_tx_status status;	/* TX status (in aggregation -
					 * status of 1st frame) */
} __attribute__ ((packed));

/* TX command response is sent after *all* transmission attempts.
 *
 * NOTES:
 *
 * TX_STATUS_FAIL_NEXT_FRAG
 *
 * If the fragment flag in the MAC header for the frame being transmitted
 * is set and there is insufficient time to transmit the next frame, the
 * TX status will be returned with 'TX_STATUS_FAIL_NEXT_FRAG'.
 *
 * TX_STATUS_FIFO_UNDERRUN
 *
 * Indicates the host did not provide bytes to the FIFO fast enough while
 * a TX was in progress.
 *
 * TX_STATUS_FAIL_MGMNT_ABORT
 *
 * This status is only possible if the ABORT ON MGMT RX parameter was
 * set to true with the TX command.
 *
 * If the MSB of the status parameter is set then an abort sequence is
 * required.  This sequence consists of the host activating the TX Abort
 * control line, and then waiting for the TX Abort command response.  This
 * indicates that a the device is no longer in a transmit state, and that the
 * command FIFO has been cleared.  The host must then deactivate the TX Abort
 * control line.  Receiving is still allowed in this case.
 */
enum {
	TX_STATUS_SUCCESS = 0x01,
	TX_STATUS_DIRECT_DONE = 0x02,
	TX_STATUS_FAIL_SHORT_LIMIT = 0x82,
	TX_STATUS_FAIL_LONG_LIMIT = 0x83,
	TX_STATUS_FAIL_FIFO_UNDERRUN = 0x84,
	TX_STATUS_FAIL_MGMNT_ABORT = 0x85,
	TX_STATUS_FAIL_NEXT_FRAG = 0x86,
	TX_STATUS_FAIL_LIFE_EXPIRE = 0x87,
	TX_STATUS_FAIL_DEST_PS = 0x88,
	TX_STATUS_FAIL_ABORTED = 0x89,
	TX_STATUS_FAIL_BT_RETRY = 0x8a,
	TX_STATUS_FAIL_STA_INVALID = 0x8b,
	TX_STATUS_FAIL_FRAG_DROPPED = 0x8c,
	TX_STATUS_FAIL_TID_DISABLE = 0x8d,
	TX_STATUS_FAIL_FRAME_FLUSHED = 0x8e,
	TX_STATUS_FAIL_INSUFFICIENT_CF_POLL = 0x8f,
	TX_STATUS_FAIL_TX_LOCKED = 0x90,
	TX_STATUS_FAIL_NO_BEACON_ON_RADAR = 0x91,
};

#define	TX_PACKET_MODE_REGULAR		0x0000
#define	TX_PACKET_MODE_BURST_SEQ	0x0100
#define	TX_PACKET_MODE_BURST_FIRST	0x0200

enum {
	TX_POWER_PA_NOT_ACTIVE = 0x0,
};

enum {
	TX_STATUS_MSK = 0x000000ff,		/* bits 0:7 */
	TX_STATUS_DELAY_MSK = 0x00000040,
	TX_STATUS_ABORT_MSK = 0x00000080,
	TX_PACKET_MODE_MSK = 0x0000ff00,	/* bits 8:15 */
	TX_FIFO_NUMBER_MSK = 0x00070000,	/* bits 16:18 */
	TX_RESERVED = 0x00780000,		/* bits 19:22 */
	TX_POWER_PA_DETECT_MSK = 0x7f800000,	/* bits 23:30 */
	TX_ABORT_REQUIRED_MSK = 0x80000000,	/* bits 31:31 */
};

/* *******************************
 * TX aggregation status
 ******************************* */

enum {
	AGG_TX_STATE_TRANSMITTED = 0x00,
	AGG_TX_STATE_UNDERRUN_MSK = 0x01,
	AGG_TX_STATE_BT_PRIO_MSK = 0x02,
	AGG_TX_STATE_FEW_BYTES_MSK = 0x04,
	AGG_TX_STATE_ABORT_MSK = 0x08,
	AGG_TX_STATE_LAST_SENT_TTL_MSK = 0x10,
	AGG_TX_STATE_LAST_SENT_TRY_CNT_MSK = 0x20,
	AGG_TX_STATE_LAST_SENT_BT_KILL_MSK = 0x40,
	AGG_TX_STATE_SCD_QUERY_MSK = 0x80,
	AGG_TX_STATE_TEST_BAD_CRC32_MSK = 0x100,
	AGG_TX_STATE_RESPONSE_MSK = 0x1ff,
	AGG_TX_STATE_DUMP_TX_MSK = 0x200,
	AGG_TX_STATE_DELAY_TX_MSK = 0x400
};

#define AGG_TX_STATE_LAST_SENT_MSK  (AGG_TX_STATE_LAST_SENT_TTL_MSK | \
				     AGG_TX_STATE_LAST_SENT_TRY_CNT_MSK | \
				     AGG_TX_STATE_LAST_SENT_BT_KILL_MSK)

/* # tx attempts for first frame in aggregation */
#define AGG_TX_STATE_TRY_CNT_POS 12
#define AGG_TX_STATE_TRY_CNT_MSK 0xf000

/* Command ID and sequence number of Tx command for this frame */
#define AGG_TX_STATE_SEQ_NUM_POS 16
#define AGG_TX_STATE_SEQ_NUM_MSK 0xffff0000

/*
 * REPLY_COMPRESSED_BA = 0xc5 (response only, not a command)
 *
 * Reports Block-Acknowledge from recipient station
 */
struct iwl_compressed_ba_resp {
	uint32_t sta_addr_lo32;
	uint16_t sta_addr_hi16;
	uint16_t reserved;

	/* Index of recipient (BA-sending) station in uCode's station table */
	uint8_t sta_id;
	uint8_t tid;
	uint16_t seq_ctl;
	uint64_t bitmap;
	uint16_t scd_flow;
	uint16_t scd_ssn;
} __attribute__ ((packed));

/**
 * iwlagn rate_n_flags bit fields
 *
 * rate_n_flags format is used in following iwlagn commands:
 *  REPLY_RX (response only)
 *  REPLY_RX_MPDU (response only)
 *  REPLY_TX (both command and response)
 *  REPLY_TX_LINK_QUALITY_CMD
 *
 * High-throughput (HT) rate format for bits 7:0 (bit 8 must be "1"):
 *  2-0:  0)   6 Mbps
 *        1)  12 Mbps
 *        2)  18 Mbps
 *        3)  24 Mbps
 *        4)  36 Mbps
 *        5)  48 Mbps
 *        6)  54 Mbps
 *        7)  60 Mbps
 *
 *  4-3:  0)  Single stream (SISO)
 *        1)  Dual stream (MIMO)
 *        2)  Triple stream (MIMO)
 *
 *    5:  Value of 0x20 in bits 7:0 indicates 6 Mbps FAT duplicate data
 *
 * Legacy OFDM rate format for bits 7:0 (bit 8 must be "0", bit 9 "0"):
 *  3-0:  0xD)   6 Mbps
 *        0xF)   9 Mbps
 *        0x5)  12 Mbps
 *        0x7)  18 Mbps
 *        0x9)  24 Mbps
 *        0xB)  36 Mbps
 *        0x1)  48 Mbps
 *        0x3)  54 Mbps
 *
 * Legacy CCK rate format for bits 7:0 (bit 8 must be "0", bit 9 "1"):
 *  6-0:   10)  1 Mbps
 *         20)  2 Mbps
 *         55)  5.5 Mbps
 *        110)  11 Mbps
 */
#define RATE_MCS_RATE_MSK (RATE_MCS_CODE_MSK | RATE_MCS_SPATIAL_MSK)
#define RATE_MCS_CODE_MSK 0x7
#define RATE_MCS_SPATIAL_POS 3
#define RATE_MCS_SPATIAL_MSK 0x18
#define RATE_MCS_HT_DUP_POS 5
#define RATE_MCS_HT_DUP_MSK 0x20

/* Bit 8: (1) HT format, (0) legacy format in bits 7:0 */
#define RATE_MCS_FLAGS_POS 8
#define RATE_MCS_HT_POS 8
#define RATE_MCS_HT_MSK 0x100

/* Bit 9: (1) CCK, (0) OFDM.  HT (bit 8) must be "0" for this bit to be valid */
#define RATE_MCS_CCK_POS 9
#define RATE_MCS_CCK_MSK 0x200

/* Bit 10: (1) Use Green Field preamble */
#define RATE_MCS_GF_POS 10
#define RATE_MCS_GF_MSK 0x400

/* Bit 11: (1) Use 40Mhz FAT chnl width, (0) use 20 MHz legacy chnl width */
#define RATE_MCS_FAT_POS 11
#define RATE_MCS_FAT_MSK 0x800

/* Bit 12: (1) Duplicate data on both 20MHz chnls.  FAT (bit 11) must be set. */
#define RATE_MCS_DUP_POS 12
#define RATE_MCS_DUP_MSK 0x1000

/* Bit 13: (1) Short guard interval (0.4 usec), (0) normal GI (0.8 usec) */
#define RATE_MCS_SGI_POS 13
#define RATE_MCS_SGI_MSK 0x2000

/**
 * rate_n_flags Tx antenna masks
 * 4965 has 2 transmitters
 * 5100 has 1 transmitter B
 * 5150 has 1 transmitter A
 * 5300 has 3 transmitters
 * 5350 has 3 transmitters
 * bit14:16
 */
#define RATE_MCS_ANT_POS	14
#define RATE_MCS_ANT_A_MSK	0x04000
#define RATE_MCS_ANT_B_MSK	0x08000
#define RATE_MCS_ANT_C_MSK	0x10000
#define RATE_MCS_ANT_AB_MSK	(RATE_MCS_ANT_A_MSK | RATE_MCS_ANT_B_MSK)
#define RATE_MCS_ANT_ABC_MSK	(RATE_MCS_ANT_AB_MSK | RATE_MCS_ANT_C_MSK)
#define RATE_ANT_NUM 3

/*
 * REPLY_RX_PHY_RES = 0xc0 (response only, not a command)
 */
struct iwl_rx_phy_res {
	uint8_t non_cfg_phy_cnt;     /* non configurable DSP phy data byte count */
	uint8_t cfg_phy_cnt;		/* configurable DSP phy data element count */
	uint8_t stat_id;		/* configurable DSP phy data set ID */
	uint8_t reserved1;
	uint64_t timestamp;	/* TSF at on air rise */
	uint32_t beacon_time_stamp; /* beacon at on-air rise */
	uint16_t phy_flags;	/* general phy flags: band, modulation, ... */
	uint16_t channel;		/* channel number */
	uint8_t non_cfg_phy_buf[32]; /* for various implementations of non_cfg_phy */
	uint32_t rate_n_flags;	/* RATE_MCS_* */
	uint16_t byte_count;	/* frame's byte-count */
	uint16_t reserved3;
	uint8_t cfg_phy_buf[0];
} __attribute__ ((packed));

struct tx_agg_ba_connector_msg {
	uint32_t successes;
	uint32_t frame_count;
};

#define IWL_CONN_BFEE_NOTIF	0xbb		/* 0xbb */
#define IWL_CONN_RX_PHY		0xc0		/* 0xc0 */
#define IWL_CONN_RX_MPDU	0xc1		/* 0xc1 */
#define IWL_CONN_RX		0xc3		/* 0xc3 */
#define IWL_CONN_NOISE		0xd0		/* new ID not a command */
#define IWL_CONN_FILTER_IPERF	0xd1		/* new ID not a command */
#define IWL_CONN_TX_RESP	0x1c		/* 0x1c */
#define IWL_CONN_TX_BLOCK_AGG	0xc5		/* 0xc5 */
#define IWL_CONN_PARALLEL_PKT	0xd2		/* new ID not a command */

enum {
	IWL_CONN_BFEE_NOTIF_MSK		= (1 << 0),
	IWL_CONN_RX_PHY_MSK		= (1 << 1),
	IWL_CONN_RX_MPDU_MSK		= (1 << 2),
	IWL_CONN_RX_MSK			= (1 << 3),
	IWL_CONN_NOISE_MSK		= (1 << 4),
	IWL_CONN_FILTER_IPERF_MSK	= (1 << 5),
	IWL_CONN_TX_RESP_MSK		= (1 << 6),
	IWL_CONN_TX_BLOCK_AGG_MSK	= (1 << 7),
	IWL_CONN_PARALLEL_PKT_MSK	= (1 << 8),
};


#endif	/* __IWL_STRUCTS_H__ */
