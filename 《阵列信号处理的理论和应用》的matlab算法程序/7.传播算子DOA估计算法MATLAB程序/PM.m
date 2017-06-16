%%%%%%%%%%%%%%%%%%%%%Propagator Method 
% Developed by xiaofei zhang (ÄÏ¾©º½¿Õº½Ìì´óÑ§ µç×Ó¹¤³ÌÏµ ÕÅÐ¡·É£©
% EMAIL:zhangxiaofei@nuaa.edu.cn

clear all
close all
derad = pi/180;
radeg = 180/pi;
twpi = 2*pi;
kelm = 16;  % the number of array
dd = 0.5;  % space between array
d=0:dd:(kelm-1)*dd; 
iwave = 3;   % the number of wave
theta = [10 20 30 ]; % DOA
pw= [1 0.8 0.7 ]'  ; %power

nv=ones(1,kelm);        % normalized noise variance
snr=20;              % input SNR (dB)
snr0= 10^(snr/10);
n = 200; % Ñù±¾ÊýÁ¿
A=exp(-j*twpi*d.'*sin(theta*derad)); % direction matrix
K=length(d);
cr=zeros(K,K);
L=length(theta);
%randn('state',12345);
data=randn(L,n);
data=sign(data);
%data(1,:)=data(4,:);
twpi = 2.0 * pi;
derad = pi / 180.0;
s = diag(pw)*data;
A1=exp(-j*twpi*d.'*sin([0:0.2:90]*derad));
received_signal = A*s;% 
cx = received_signal + diag(sqrt(nv/snr0/2))*(randn(K,n)+j*randn(K,n));% x=AS+n  
Rxx=cx*cx'/n;

%%%%%%%%%
%%Propagator Method 
G=Rxx(:,1:iwave);
H=Rxx(:,iwave+1:end);
P=inv(G'*G)*G'*H;
Q=[P',-diag(ones(1,kelm-iwave))];

for iang = 1:361
        angle(iang)=(iang-181)/2;
        phim=derad*angle(iang);
        a=exp(-j*twpi*d*sin(phim)).';
        SP(iang)=1/(a'*Q'*Q*a);
end
SP=abs(SP);
SPmax=max(SP);
SP=10*log10(SP/SPmax);
% 
figure
h=plot(angle,SP,'-k');
set(h,'Linewidth',2)
xlabel('angle (degree)')
ylabel('magnitude (dB)')
axis([-90 90 -60 0])
set(gca, 'XTick',[-90:30:90])
grid on  
hold on
legend('Propagator Method ')

