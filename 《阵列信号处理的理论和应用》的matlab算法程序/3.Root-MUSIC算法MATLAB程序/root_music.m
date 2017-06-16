% Developed by xiaofei zhang (ÄÏ¾©º½¿Õº½Ìì´óÑ§ µç×Ó¹¤³ÌÏµ ÕÅÐ¡·É£©
% EMAIL:zhangxiaofei@nuaa.edu.cn

clear all
close all
derad = pi/180;
radeg = 180/pi;
twpi = 2*pi;
kelm = 8;               % 
dd = 0.5;               % 
d=0:dd:(kelm-1)*dd;     % 
iwave = 3;              % number of DOA
theta = [10 20 30];  
snr = 20;               % input SNR (dB)
n =200;                % 
A=exp(-j*twpi*d.'*(sin(theta*derad)));
S=randn(iwave,n);
X0=A*S;
X=awgn(X0,snr,'measured');
Rxx=X*X';
InvS=inv(Rxx); %%%%
[EVx,Dx]=eig(Rxx);%%%% 
EVAx=diag(Dx)';
[EVAx,Ix]=sort(EVAx);
EVAx=fliplr(EVAx);
EVx=fliplr(EVx(:,Ix));
% 
% Root-MUSIC
Unx=EVx(:,iwave+1:kelm);
syms z
pz = z.^([0:kelm-1]');
pz1 = (z^(-1)).^([0:kelm-1]);
fz = z.^(kelm-1)*pz1*Unx*Unx'*pz;
a = sym2poly(fz)
zx = roots(a)
rx=zx.';
[as,ad]=(sort(abs((abs(rx)-1))));
DOAest=asin(sort(-angle(rx(ad([1,3,5])))/pi))*180/pi

