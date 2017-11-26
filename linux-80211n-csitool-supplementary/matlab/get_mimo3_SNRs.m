%GET_MIMO3_SNRS Calculates the MIMO3 SNRs for a scaled CSI matrix.
%   Note that the matrix is expected to have dimensions M x N x S, where
%      M = # TX antennas
%      N = # RX antennas
%      S = # subcarriers
%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>,
%               Wenjun Hu
%
function ret = get_mimo3_SNRs(csi)
    % Make sure at least 3 TX and RX antennas
    [M N S] = size(csi);
    if (M < 3)
        error('CSI matrix must have at least 3 TX antennas');
    end
    if (N < 3)
        error('CSI matrix must have at least 3 RX antennas');
    end

    % Since the incoming CSI is scaled to single-TX reduce by 3 for 3 streams
    %
    % Take away 4.5 dB (Intel-specific version of "1/3" ~ -4.77 dB)
    csi = csi / sqrt(dbinv(4.5));
    % Divide power by 3 (Real version of 3)
    % csi = csi / sqrt(3);

    ret = zeros(1,3,S);
    for i = 1:S
        ret(1,:,i) = mimo3_mmse(squeeze(csi(:,:,i)));
    end
    return;
end

% Compute the MMSE stream SNRs of a single channel matrix
function ret = mimo3_mmse(csi)
    % We want
    %   H' * H + I
    % but, since csi = H transposed, we instead use
    %   conj(csi) * csi.'
    M = inv(conj(csi) * csi.' + eye(3));
    ret = 1 ./ diag(M) - 1;

    % ret is real. Really.
    ret = real(ret);
end
