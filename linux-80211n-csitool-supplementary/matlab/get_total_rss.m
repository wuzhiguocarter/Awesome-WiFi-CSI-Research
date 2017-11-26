%GET_TOTAL_RSS Calculates the Received Signal Strength (RSS) in dBm from
% a CSI struct.
%
% (c) 2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = get_total_rss(csi_st)
    error(nargchk(1,1,nargin));

    % Careful here: rssis could be zero
    rssi_mag = 0;
    if csi_st.rssi_a ~= 0
        rssi_mag = rssi_mag + dbinv(csi_st.rssi_a);
    end
    if csi_st.rssi_b ~= 0
        rssi_mag = rssi_mag + dbinv(csi_st.rssi_b);
    end
    if csi_st.rssi_c ~= 0
        rssi_mag = rssi_mag + dbinv(csi_st.rssi_c);
    end
    
    ret = db(rssi_mag, 'pow') - 44 - csi_st.agc;
end