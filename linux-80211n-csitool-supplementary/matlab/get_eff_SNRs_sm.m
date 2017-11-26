%GET_EFF_SNRS_SM Compute the effective SNR values from a CSI matrix
%   Note that the matrix is expected to have dimensions M x N x S, where
%      M = # TX antennas
%      N = # RX antennas
%      S = # subcarriers
%   This version takes into account the spatial mapping performed by Intel NICs.
%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>,
%               Wenjun Hu
%
function ret=get_eff_SNRs_sm(csi)
    ret = zeros(7,4) + eps; % machine epsilon is smallest possible SNR

%    [M N S] = size(csi);  % If next line doesn't compile
    [M N ~] = size(csi);
    k = min(M,N);

    % Do the various SIMO configurations (i.e., TX antenna selection)
    if k >= 1
        snrs = get_simo_SNRs(csi);

        bers = bpsk_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret((1:length(mean_ber)),1) = bpsk_berinv(mean_ber);

        bers = qpsk_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret((1:length(mean_ber)),2) = qpsk_berinv(mean_ber);

        bers = qam16_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret((1:length(mean_ber)),3) = qam16_berinv(mean_ber);

        bers = qam64_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret((1:length(mean_ber)),4) = qam64_berinv(mean_ber);
    end

    % Do the various MIMO2 configurations (i.e., TX antenna selection)
    if k >= 2
        snrs = get_mimo2_SNRs_sm(csi);

        bers = bpsk_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(3+(1:length(mean_ber)),1) = bpsk_berinv(mean_ber);

        bers = qpsk_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(3+(1:length(mean_ber)),2) = qpsk_berinv(mean_ber);

        bers = qam16_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(3+(1:length(mean_ber)),3) = qam16_berinv(mean_ber);

        bers = qam64_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(3+(1:length(mean_ber)),4) = qam64_berinv(mean_ber);
    end

    % Do the MIMO3 configuration
    if k >= 3
        snrs = get_mimo3_SNRs_sm(csi);

        bers = bpsk_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(6+(1:length(mean_ber)),1) = bpsk_berinv(mean_ber);

        bers = qpsk_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(6+(1:length(mean_ber)),2) = qpsk_berinv(mean_ber);

        bers = qam16_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(6+(1:length(mean_ber)),3) = qam16_berinv(mean_ber);

        bers = qam64_ber(snrs);
        mean_ber = mean(mean(bers, 3), 2);
        ret(6+(1:length(mean_ber)),4) = qam64_berinv(mean_ber);
    end

    % Apparently, sometimes it can be infinite so cap it at 40 dB
    %ret(ret==Inf) = dbinv(40);
end
