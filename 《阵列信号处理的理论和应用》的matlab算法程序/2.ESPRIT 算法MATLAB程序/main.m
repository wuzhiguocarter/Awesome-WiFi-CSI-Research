% Developed by xiaofei zhang (ÄÏ¾©º½¿Õº½Ìì´óÑ§ µç×Ó¹¤³ÌÏµ ÕÅÐ¡·É£©
% EMAIL:zhangxiaofei@nuaa.edu.cn
clear all
close all
radeg = 180/pi;
derad=1/radeg;
twpi = 2*pi;
kelm = 8;               % 
dd = 0.5;               % 
d=0:dd:(kelm-1)*dd;     % 
iwave = 3;              % number of DOA
theta = [10 20 30];     % DOA
n = 200                % 
A=exp(-j*twpi*d.'*sin(theta*derad));%%%% direction matrix

S=randn(iwave,n);
snr0=0:3:100;
for isnr=1:10
X0=A*S;
X=awgn(X0,snr0(isnr),'measured');
Rxx=X*X'/n;
[EV,D]=eig(Rxx);
EVA=diag(D)'; [EVA,I]=sort(EVA);
EVA=fliplr(EVA); EV=fliplr(EV(:,I)); 
estimates=(tls_esprit(dd,Rxx,iwave));
doaes(isnr,:)=sort(estimates(1,:));
end


 
