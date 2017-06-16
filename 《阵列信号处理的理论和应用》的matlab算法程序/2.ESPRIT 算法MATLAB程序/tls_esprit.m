function estimate =  tls_esprit(dd,cr,Le)
%*******************************************************
% This function calculates TLS-ESPRIT estimator for
% uniform linear array.
%
% Inputs
%    dd       sensor separation in wavelength
%    cr(K,K)  array output covariance matrix
%    Le       estimated number of sources ==L=iwave
%   
% Output
%    estimate  estimated angles in degrees
%              estimated powers
%*******************************************************

twpi = 2.0*pi;
derad = pi / 180.0;
radeg = 180.0 / pi;

% eigen decomposition of cr
[K,KK] = size(cr);
[V,D]=eig(cr);
EVA = real(diag(D)');
[EVA,I] = sort(EVA);
%disp('Eigenvalues of correlation matrix in TLS-ESPRIT:')
EVA=fliplr(EVA);
EV=fliplr(V(:,I));

%  composition of E_{xy} and E_{xy}^H E_{xy} = E_xys
Exy = [EV(1:K-1,1:Le) EV(2:K,1:Le)];
E_xys = Exy'*Exy;

% eigen decomposition of E_xys
[V,D]=eig(E_xys);
EVA_xys = real(diag(D)');
[EVA_xys,I] = sort(EVA_xys);
EVA_xys=fliplr(EVA_xys);
EV_xys=fliplr(V(:,I));

% decomposition of eigenvectors
Gx = EV_xys(1:Le,Le+1:Le*2);
Gy = EV_xys(Le+1:Le*2,Le+1:Le*2);

% calculation of  Psi = - Gx [Gy]^{-1}
Psi = - Gx/Gy;

% eigen decomposition of Psi
[V,D]=eig(Psi);
EGS = diag(D).';
[EGS,I] = sort(EGS);
EGS=fliplr(EGS);
EVS=fliplr(V(:,I));
 
% DOA estimates
ephi = atan2(imag(EGS), real(EGS));
ange = - asin( ephi / twpi / dd ) * radeg;
estimate(1,:)=ange;

% power estimates
T = inv(EVS);
powe = T*diag(EVA(1:Le) - EVA(K))*T';
powe = abs(diag(powe).')/K;
estimate(2,:)=powe;
% End tls_esprit.m
