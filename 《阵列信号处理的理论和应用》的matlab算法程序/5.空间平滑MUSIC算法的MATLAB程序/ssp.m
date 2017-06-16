function crs = ssp(cr, K)
% spatial smoothing 
[M,MM]=size(cr);
N=M-K+1;
crs = zeros(K,K);
for  in =1:N
        crs = crs + cr(in:in+K-1,in:in+K-1)
end
crs = crs / N;