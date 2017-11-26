%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = qam64_ber(snr)
    ret = 7/12*qfunc(sqrt(snr/21));
end
