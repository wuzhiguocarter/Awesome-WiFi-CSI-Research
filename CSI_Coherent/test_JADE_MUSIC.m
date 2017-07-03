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
% Joint DoA and ToF Estimation MUSIC
% Developed by Wu Zhiguo(Beijing University of Post and Telecommunication)
% QQ group for discusion: 366102075
% EMAIL:1600682324@qq.com wuzhiguo@bupt.edu.cn
% Github: https://github.com/wuzhiguocarter/Awesome-WiFi-Smooth_CSI-Research
% Blog: http://www.jianshu.com/c/6e0897ba0cec [WiFi Smooth_CSI Based Indoor Localization]
%{
  实验结论：
    - 快拍数、信噪比综合影响AoA和ToF的分辨率、准确度
    - 其他条件不变的情况下，带宽决定ToF分辨率
    - 其他条件不变的情况下，阵元数决定AoA的分辨率
    - 阵列孔径 l = (Nrx-1)*ant_dist
    - ant_dis最大取lambda/2，此时可获取最大的阵列孔径
    - 信源数L估计不准，会对AoA和ToF造成很大误差（少一个或者多一个都不行）
    - MUSIC算法只适用于非相干信源
%}
clc;clear;close all;

%% 全局参数配置
CSI_Configure();

global isRealSignal


%% 引用全局参数
global Nrx ant_dist
global paths theta tau  
global fc Nc Delta_f
global SNR samples
global param

if ~isRealSignal
    disp('Display All Global Paramters: ');
    param

    %% 设置的多径AoA和ToF信息
    fprintf('True ToF and AoA of all paths: \n');
    for ipath = 1:paths
        disp(['path ' num2str(ipath) ': (AoA, ToF) = (' num2str(theta(ipath)) ...
            ' [deg], ' num2str(tau(ipath)*1e9) ' [ns])' ]);
    end

    global CoherentPaths
    fprintf('\n%d from %d paths are coherent\n', CoherentPaths+1, paths);
end

global isCoherent
if ~isCoherent
    option = 'non-smoothing';
else
    option = 'smoothing';
end

% option = 'non-smoothing';

if ~isRealSignal
%% 生成观测矩阵CSI和导向向量A
    [Smooth_CSI,A] = API_CSI_Generator( theta, tau, paths, ...
                            Nrx,ant_dist,samples, ...
                            fc,Nc,Delta_f,SNR,option);
else % 使用真实数据
    CSI = load('smoothed_csi.mat');
    Smooth_CSI = CSI.smoothed_csi_to_save;
%     CSI = load('smoothed_sanitized_csi.mat');
%     Smooth_CSI = CSI.smoothed_sanitized_csi_to_save;
    samples = size(Smooth_CSI,3);
    paths = -1;
    Nrx = 3;
    ant_dist = 0.10;
    fc = 5.32 * 10^9; %  5.785 * 10^9
    Nc = 30;
    Delta_f = (40 * 10^6) / 30;
end
%% 计算MUSIC伪谱，寻找谱峰，估计AoA和ToF，并可视化,存为jpeg
API_CSI_MUSIC_Visualize( Smooth_CSI,samples,paths, Nrx,ant_dist, ...
                            fc,Nc,Delta_f,option);
