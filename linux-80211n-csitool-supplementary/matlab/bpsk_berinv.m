%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = bpsk_berinv(ber)
    ret = qfuncinv(ber).^2 / 2;
end
