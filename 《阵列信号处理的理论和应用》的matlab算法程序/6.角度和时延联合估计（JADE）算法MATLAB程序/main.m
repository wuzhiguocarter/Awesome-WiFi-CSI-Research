% joint angle-delay estimation of multipath parameters from knowledge of the pulse shape form. 
% Developed by xiaofei zhang (南京航空航天大学 电子工程系 张小飞）
% EMAIL:zhangxiaofei@nuaa.edu.cn

clear all
close all
M = 8;		         % number of antennas
P = 2;		         % oversampling rate
L = 6;		         % length of waveform (raised-cos) 
N = 100;		     % number of symbol periods in which samples are taken

beta = 0.25;		 % modulation parameter of raised-cos
alpha0 = [-20; 20];  % angles of arrival of each ray of each signal [degrees]
tau0 =  [0; 1.1]; 	 % relative delays of each ray  [baud-periods]
p00 =   [1; 0.8];	 % amplitude factors (powers) of each ray
r = size(alpha0,1);	 % number of rays
phase0 = exp(sqrt(-1)*2*pi*rand(r,1));% random init phase
p0 = p00 .* phase0;
% generate actual data matrices according to parameters
[H,g] = genspacetimechan(M,P,L,beta,alpha0,tau0,p0);
m1 = 3;	% stacking parameters in the algorithm
m2 = 1;
[theta,tau] = jade(H,g,r,P,m1,m2) %joint angle-delay estimation 

