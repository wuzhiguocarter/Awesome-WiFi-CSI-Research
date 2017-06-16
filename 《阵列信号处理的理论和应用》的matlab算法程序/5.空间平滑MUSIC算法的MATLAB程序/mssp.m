function crs = mssp(cr, K)
% modified spatial smoothing
[M,MM]=size(cr);
N=M-K+1;
J = fliplr(eye(M));
crfb = (cr + J*cr.'*J)/2;
crs = zeros(K,K);
for  in =1:N
  crs = crs + crfb(in:in+K-1,in:in+K-1)
end
crs = crs / N;
%End mssp.m