%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = qam16_ber(snr)
    ret = 3/4*qfunc(sqrt(snr/5));
end
