%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = bpsk_ber(snr)
    ret = qfunc(sqrt(2*snr));
end
