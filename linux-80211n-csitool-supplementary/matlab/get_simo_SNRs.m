%GET_SIMO_SNRS Calculates the SIMO SNRs for a scaled CSI matrix.
%   Note that the matrix is expected to have dimensions M x N x S, where
%      M = # TX antennas
%      N = # RX antennas
%      S = # subcarriers
%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>,
%               Wenjun Hu
%
function ret = get_simo_SNRs(csi)
    % SIMO SNR is simply sum squared magnitude of CSI along RX dimension
    ret = sum(csi.*conj(csi), 2);

    % Really, ret is real
    ret = real(ret);
end
