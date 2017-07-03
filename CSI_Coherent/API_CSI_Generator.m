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
%% CSI-GENERATOR Generate CSI Measurements 
% 
% Developed by Wu Zhiguo(Beijing University of Post and Telecommunication)
% QQ group for discusion: 366102075
% EMAIL:1600682324@qq.com wuzhiguo@bupt.edu.cn
% Github: https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research
% Blog: http://www.jianshu.com/c/6e0897ba0cec [WiFi CSI Based Indoor Localization]

function [CSI,A] = API_CSI_Generator( theta, tau, paths, ...
                            Nrx,ant_dist,samples, ...
                            fc,Nc,Delta_f,SNR, option)
                        
if nargin == 10 || (nargin == 11 && strcmp(option, 'non-smoothing'))
    A = zeros(Nrx*Nc,paths);
    X = zeros(Nrx*Nc,samples);
    CSI = zeros(Nrx*Nc,samples);
elseif nargin == 11 && strcmp(option, 'non-smoothing')
    sizeSubArray = ceil(Nrx/2)*ceil(Nc/2);
    A = zeros(sizeSubArray,paths);
    nSubArray = ceil(Nrx/2)*(Nc-ceil(Nc/2)+1);
    X = zeros(sizeSubArray,nSubArray,samples);
    CSI = zeros(sizeSubArray,nSubArray,samples);
end

for ipath = 1:paths
    A(:,ipath) = util_steering_aoa_tof(theta(ipath),tau(ipath), ...
                                        Nrx,ant_dist,fc,Nc,Delta_f, option);
end

global isCoherent CoherentPaths
if isCoherent % 测试相干信源
    Gamma_temp=randn(paths-CoherentPaths,samples)+randn(paths-CoherentPaths,samples)*1j; % complex attuation(不相干信源)
    ComplexConst = randn+1j*randn;
    % 生成与第一条和二条路径信号相干的接收信号
    if strcmp(option,'non-smoothing')
        Gamma = [Gamma_temp;ComplexConst*repmat(Gamma_temp(1,:),CoherentPaths,1)];
    elseif strcmp(option,'smoothing')
        nSubArray = ceil(Nrx/2)*(Nc-ceil(Nc/2)+1);
        Gamma = cell(nSubArray,1);
        for iSubArray = 1:nSubArray
            % 不同子阵的衰落独立，不同快拍的衰落独立
            Gamma_temp=randn(paths-CoherentPaths,samples)+randn(paths-CoherentPaths,samples)*1j; % complex attuation(不相干信源)
            ComplexConst = randn+1j*randn;
            Gamma{iSubArray} = [Gamma_temp;ComplexConst*repmat(Gamma_temp(1,:),CoherentPaths,1)];
        end
    end
    
else
    Gamma = randn(paths,samples)+randn(paths,samples)*1j; % complex attuation
end

global lambda
if nargin == 10 || (nargin == 11 && strcmp(option, 'non-smoothing'))
    X=A*Gamma; % 
    CSI =awgn(X,SNR,'measured');
    save('CSI.mat','CSI', 'A');
elseif nargin == 11 && strcmp(option, 'smoothing')
    nSubArray = ceil(Nrx/2)*(Nc-ceil(Nc/2)+1);
    beta = 2*pi*ant_dist*sin(theta)/lambda;
    D = diag(exp(-1j*beta));
    for iSubArray = 1: nSubArray
        if iSubArray <= nSubArray/2
            X(:,iSubArray,:) = A*D^(iSubArray-1)*Gamma{iSubArray};
        else
            Phi = exp(-1j*2*pi*1*ant_dist*sin(theta*pi/180)/lambda);
            D = D*diag(Phi);
            X(:,iSubArray,:) = A*D.^(iSubArray-1)*Gamma{iSubArray};
        end
        CSI(:,iSubArray,:) = awgn(squeeze(X(:,iSubArray,:)),SNR,'measured');
    end
    save('CSI.mat','CSI', 'A');
end
end