%GET_MIMO2_SNRS_SM Calculates the MIMO2 SNRs for a scaled CSI matrix.
%   Note that the matrix is expected to have dimensions M x N x S, where
%      M = # TX antennas
%      N = # RX antennas
%      S = # subcarriers
%   This version takes into account the spatial mapping performed by Intel NICs.
%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>,
%               Wenjun Hu
%
function ret = get_mimo2_SNRs_sm(csi)
    error(nargchk(1,1,nargin));
    
    % Make sure at least 2 TX and RX antennas
    [M, N, S] = size(csi);
    if (M < 2)
        error('CSI matrix must have at least 2 TX antennas');
    end
    if (N < 2)
        error('CSI matrix must have at least 2 RX antennas');
    end

    % Since the incoming CSI is scaled to single-TX reduce by 2 for 2 streams
    csi = csi / sqrt(2);

    % Separate out 3 and 2 antenna cases
    if M == 2
        ret = zeros(1,2,S);
        for i = 1:S
            ret(1,:,i) = mimo2_mmse_sm(squeeze(csi(:,:,i)));
        end
        return;
    end
    % else M == 3

    % There are 3 TX configs: TX AB, AC, BC
    ret = zeros(3,2,S);
    for i = 1:S
        ret(1,:,i) = mimo2_mmse_sm(squeeze(csi([1 2],:,i)));
        ret(2,:,i) = mimo2_mmse_sm(squeeze(csi([1 3],:,i)));
        ret(3,:,i) = mimo2_mmse_sm(squeeze(csi([2 3],:,i)));
    end
    return;
end

% Compute the MMSE stream SNRs of a single channel matrix
function ret = mimo2_mmse_sm(csi_i)
    % Load and apply SM matrices
    sm_matrices;
    csi = apply_sm(csi_i, sm_2_20);
    
    % We want
    %   H' * H + I
    % but, since csi = H transposed, we instead use
    %   conj(csi) * csi.'
    M = inv(conj(csi) * csi.' + eye(2));
    ret = 1 ./ diag(M) - 1;

    % ret is real. Really.
    ret = real(ret);
end