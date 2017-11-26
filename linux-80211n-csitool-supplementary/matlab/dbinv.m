%DBINV Convert from decibels.
%
% (c) 2008-2011 Daniel Halperin <dhalperi@cs.washington.edu>
%
function ret = dbinv(x)
    ret = 10.^(x/10);
end
