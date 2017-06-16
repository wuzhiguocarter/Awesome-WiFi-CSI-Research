%%% DOA estimation by  spatial smoothing or modified spatial smoothing
% Developed by xiaofei zhang (南京航空航天大学 电子工程系 张小飞）
% EMAIL:zhangxiaofei@nuaa.edu.cn
clear all
close all
derad = pi/180;         % deg -> rad
radeg = 180/pi;
twpi = 2*pi;
Melm = 7;               
kelm = 6;               
dd = 0.5;              
d=0:dd:(Melm-1)*dd;     
iwave = 3;              
theta = [0 30 60];      
n = 200                % 
A=exp(-j*twpi*d.'*sin(theta*derad));%%%% direction matrix
S0=randn(iwave-1,n);
S=[S0(1,:);S0];
X0=A*S;
X=awgn(X0,10,'measured');
Rxxm=X*X'/n;
issp = 1;  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% spatial smoothing music
if issp == 1
  Rxx = ssp(Rxxm,kelm);
elseif issp == 2
  Rxx = mssp(Rxxm,kelm);
else
  Rxx = Rxxm;
  kelm = Melm;
end
  
% Rxx
[EV,D]=eig(Rxx);
EVA=diag(D)'; [EVA,I]=sort(EVA);
EVA=fliplr(EVA), EV=fliplr(EV(:,I));

for iang = 1:361
        angle(iang)=(iang-181)/2;
        phim=derad*angle(iang);
        a=exp(-j*twpi*d(1:kelm)*sin(phim)).';
        L=iwave;     
        En=EV(:,L+1:kelm);
        SP(iang)=(a'*a)/(a'*En*En'*a);
end
   
SP=abs(SP);
SPmax=max(SP);
SP=10*log10(SP/SPmax);
%SP=SP/SPmax;
figure
h=plot(angle,SP);
set(h,'Linewidth',2)
xlabel('angle (degree)')
ylabel('magnitude (dB)')
axis([-90 90 -60 0])
set(gca, 'XTick',[-90:30:90], 'YTick',[-60:10:0])
grid on   
hold on
legend('平滑MUSIC')
 