%%
% The MIT License (MIT)
% Copyright (c) 2017 Wu Zhiguo <wuzhiguo@bupt.edu.cn>
% 
% Permission is hereby granted, free of charge, to any person obtaining a 
% copy of this software and associated documentation files (the "Software"), 
% to deal in the Software without restriction, including without limitation 
% the rights to use, copy, modify, merge, publish, distribute, sublicense, 
% and/or sell copies of the Software, and to permit persons to whom the 
% Software is furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
% DEALINGS IN THE SOFTWARE.
%
%CSI_Configure
% 
% Developed by Wu Zhiguo(Beijing University of Post and Telecommunication)
% QQ group for discusion: 366102075
% EMAIL:1600682324@qq.com wuzhiguo@bupt.edu.cn
% Github: https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research
% Blog: http://www.jianshu.com/c/6e0897ba0cec [WiFi CSI Based Indoor Localization]
function CSI_Configure
%CONFIGURE 此处显示有关此函数的摘要
%   此处显示详细说明

%%
global degree2radian radian2degree twoPi LIGHTSPEED lambda
global Nrx ant_dist
global paths theta tau isCoherent CoherentPaths
global fc Nc Delta_f BW
global SNR samples
global PLOT_MUSIC_AOA PLOT_MUSIC_TOF
global SAVE_FIGURE
global USE_NumOfSignalsEstimation
global isRealSignal

isRealSignal = true;

USE_NumOfSignalsEstimation = true;

PLOT_MUSIC_AOA = true;
PLOT_MUSIC_TOF = true;
SAVE_FIGURE = false;

degree2radian = pi/180;             % deg -> rad
radian2degree = 180/pi;
twoPi = 2*pi;


%% 信号参数
LIGHTSPEED = 3e8;                   % 光速 3*10^8 [m/s]
if ~isRealSignal
    fc = 5.8e9;                         % 5.8GHz
    lambda = LIGHTSPEED/fc;             % 约3cm

    Nc = 30;                            % number of subcarriers 至少为2
    BW = 40e6;                          % Bandwidth = 20MHz
    Delta_f = BW/Nc;                    % 子载波频率间隔

    SNR = 10;                           % input SNR (dB) 10dB 代表信号功率是噪声功率的10倍,10lg10
    samples = 100;                      % 快拍数 500， 200

    %% 多径参数配置
    paths = 3;
    if paths == 3
        theta = [-40 10 30];                % 各径AoA[deg]
        tau = [73 18 43]*1e-9;              % 各径ToA[ns]
    elseif paths == 5
        % 多径参数 5路信号， 备注： -40deg,10ns和第二条路径信号难以分开
        theta = [-60 -25 10 30 60];         % 各径AoA[deg]
        tau = [40 5 50 20 70]*1e-9;         % 各径ToA[ns]
    end
end

isCoherent = true;
if isCoherent
    if paths <= 3
        CoherentPaths = 1;          % 和第一条路径相干的路径个数
    elseif paths >=5
        CoherentPaths = 2;
    end
else
    CoherentPaths = 0;
end

if ~isRealSignal
%% 阵列参数
Nrx = 3;
ant_dist = lambda/2;                % space = lambda/2 [m]

save 'para.mat'
global param
param = load('para.mat');
end

end

