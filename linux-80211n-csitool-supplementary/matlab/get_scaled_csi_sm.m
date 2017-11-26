%GET_SCALED_CSI_SM Converts a CSI struct to a channel matrix H.
% This version undoes Intel's spatial mapping to return the pure
% MIMO channel matrix H.
%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = get_scaled_csi_sm(csi_st)
    % Normal procedure to scale normalized CSI to H
    ret = get_scaled_csi(csi_st);
    
    % Remove the spatial mapping that was used for this H matrix
    ret = remove_sm(ret, csi_st.rate);
end