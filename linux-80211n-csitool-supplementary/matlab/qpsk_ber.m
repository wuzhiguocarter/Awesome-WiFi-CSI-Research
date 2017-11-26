%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = qpsk_ber(snr)
    ret = qfunc(sqrt(snr));
end
