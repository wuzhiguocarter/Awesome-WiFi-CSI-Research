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
%% API_CSI_MUSIC_Visualize
% 
% Developed by Wu Zhiguo(Beijing University of Post and Telecommunication)
% QQ group for discusion: 366102075
% EMAIL:1600682324@qq.com wuzhiguo@bupt.edu.cn
% Github: https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research
% Blog: http://www.jianshu.com/c/6e0897ba0cec [WiFi CSI Based Indoor Localization]
function API_CSI_MUSIC_Visualize( Xt,samples,paths, Nrx,ant_dist,fc,Nc,Delta_f,option)
if strcmp(option,'non-smoothing')
    Rxx=Xt*Xt'/samples;
elseif strcmp(option,'smoothing')
    Rxx = zeros(size(Xt,1));
    for isamples = 1:samples
        Xt_squeeze = squeeze(Xt(:,:,isamples));
        Rxx = Rxx+Xt_squeeze*Xt_squeeze';
    end
    Rxx = Rxx/samples;
end
[eigvec_mat,diag_mat_of_eigval]=eig(Rxx); % 返回特征向量矩阵与特征值对角矩阵
eigval=diag(diag_mat_of_eigval);     % 取所有特征值
% [sorted_eigval,IndexVector]=sort(eigval);        % 对特征值升序排序，并返回index vector
% % 将特征向量矩阵按列调整顺序，调整原则为：大的特征值对应的特征向量靠左排
% % 即特征向量按特征值进行降序排列，把特征值看做key，把特征向量看做value
% eigvec_mat=fliplr(eigvec_mat(:,IndexVector)); 

[sorted_eigval,IndexVector]=sort(eigval,'descend');
eigvec_mat = eigvec_mat(:,IndexVector); 


%% 信源数估计
global USE_NumOfSignalsEstimation
if ~USE_NumOfSignalsEstimation
    L = paths;  % 不使用信源数估计，直接人为给出
else
    % 'AIC','MDL','HQ','EGM1','EGM2'
    algo_option = 'EGM1';
    L = util_getNumOfSignals(sorted_eigval,samples,algo_option);
    fprintf('\nUsing %s NumOfSignalsEstimation, Estimate Paths is %d\n',algo_option, L);
end

%% 计算MUSIC伪谱
aoa = -90:1:90;       % -90~90 [ns]
tof = (0:1:100)*1e-9; % 1~100 [ns]
Pmusic = zeros(length(aoa),length(tof));
for iAoA = 1:length(aoa)
    for iToF = 1:length(tof)
        a = util_steering_aoa_tof(aoa(iAoA),tof(iToF), ...
            Nrx,ant_dist,fc,Nc,Delta_f, option);
        En=eigvec_mat(:,L+1:length(a));
        %Pmusic(iAoA,iToF) = abs(1/(a'*(En*En')*a));
        % 归一化MUSIC伪谱
        Pmusic(iAoA,iToF) = abs((a'*a)/(a'*(En*En')*a));
    end
end

LOG_DATE = strrep(datestr(now,30),'T','');

%% MUSIC_AOA_TOF可视化
hMUSIC = figure('Name', 'MUSIC_AOA_TOF', 'NumberTitle', 'off');
[meshAoA,meshToF] = meshgrid(aoa,tof);
SPmax=max(max(Pmusic));
Pmusic=10*log10(Pmusic/SPmax);
mesh(meshAoA,meshToF*1e9,Pmusic');
xlabel('Angle of Arrival in degrees[deg]')
ylabel('Time of Flight[ns]')
zlabel('Spectrum Peaks[dB]')
title('AoA and ToF Estimation from Modified MUSIC Algorithm')
grid on

fprintf('\nFind all peaks of MUSIC spectrum: \n');

global PLOT_MUSIC_AOA PLOT_MUSIC_TOF 
global SAVE_FIGURE
%% MUSIC_AOA可视化
if PLOT_MUSIC_AOA
    num_computed_paths = L;
    figure_name_string = sprintf('MUSIC_AOA, Number of Paths: %d', num_computed_paths);
    figure('Name', figure_name_string, 'NumberTitle', 'off')

    PmusicEnvelope_AOA = zeros(length(aoa),1);
    for i = 1:length(aoa)
        PmusicEnvelope_AOA(i) = max(Pmusic(i,:));
    end

    plot(aoa, PmusicEnvelope_AOA, '-k')
    xlabel('Angle, \theta[deg]')
    ylabel('Spectrum function P(\theta, \tau)  / dB')
    title('AoA Estimation')
    grid on;grid minor;hold on;

   %% 计算所有路径的AoA
    % 降序返回前paths大的峰值及其索引
    [pkt,lct]  = findpeaks(PmusicEnvelope_AOA,aoa,'SortStr','descend','NPeaks',num_computed_paths); 
    % 标记峰值
    plot(lct,pkt,'o','MarkerSize',12)
    % 升序输出峰值的索引
    disp(['Calculated AoA: ' num2str(sort(round(lct),'ascend')) ' [deg]'] )
    
    if SAVE_FIGURE
        figureName = ['./figure/' LOG_DATE '_' 'MUSIC_AOA' '.jpg'];
        saveas(gcf,figureName);
    end
end

%% MUSIC_TOF可视化
if PLOT_MUSIC_TOF
    figure_name_string = sprintf('MUSIC_TOF, %d paths', num_computed_paths);
    figure('Name', figure_name_string, 'NumberTitle', 'off');

    PmusicEnvelope_ToF = zeros(length(tof),1);
    for i = 1:length(tof)
        PmusicEnvelope_ToF(i) = max(Pmusic(:,i));
    end

    plot(tof*1e9, PmusicEnvelope_ToF, '-k')
    xlabel('ToF, \tau[ns]')
    ylabel('Spectrum function P(\theta, \tau)  / dB')
    title('ToF Estimation')
    grid on;grid minor;hold on;
   %% 计算所有路径的ToF
    [pkt,lct]  = findpeaks(PmusicEnvelope_ToF,tof*1e9,'SortStr','descend','NPeaks',num_computed_paths); % 'MinPeakHeight',-4
    plot(lct,pkt,'o','MarkerSize',12)
    disp(['Calculated ToF: ' num2str(sort(round(lct),'ascend')) ' [ns]'] );
    
    if SAVE_FIGURE
        figureName = ['./figure/' LOG_DATE '_' 'MUSIC_TOF' '.jpg'];
        saveas(gcf,figureName);
    end
    
   %% 计算直射径AoA和ToF
    fprintf('\nFind Direct Path AoA and ToF: \n')
    direct_path_tof_index = find(tof*1e9 == min(lct));
    direct_path_tof = min(lct); %[ns]
    [~,direct_path_aoa_index] = max(Pmusic(:,direct_path_tof_index));
    direct_path_aoa = aoa(direct_path_aoa_index);
    disp(['(AOA, ToF) =  ('  num2str(direct_path_aoa) ' [deg], '  ...
       num2str(direct_path_tof) ' [ns]) ']);

   %% 在MUSIC伪谱中标记直射径
    set(0,'CurrentFigure',hMUSIC);hold on;
    x_aoa = direct_path_aoa;
    y_tof = direct_path_tof;
    z_dB = Pmusic(direct_path_aoa_index,direct_path_tof_index);
    plot3(x_aoa,y_tof,z_dB,'o','MarkerSize',12);
%         scatter3(direct_path_aoa,direct_path_tof, ...
%             Pmusic(direct_path_aoa_index,direct_path_tof_index), ... 
%                 'filled', ...
%                 'MarkerEdgeColor','r');
    txt = sprintf('Direct Path: \n( %d[deg], %d[ns])', ...
        round(direct_path_aoa), ...
        round(direct_path_tof));
    text(x_aoa,y_tof,z_dB,txt);
    % 设置figure hMUSIC为当前视图
    figure(hMUSIC);
    view(-60,30);
    
    if SAVE_FIGURE
        figureName = ['./figure/' LOG_DATE '_' 'MUSIC_AOA_TOF' '.jpg'];
        saveas(gcf,figureName);
    end
end
end


