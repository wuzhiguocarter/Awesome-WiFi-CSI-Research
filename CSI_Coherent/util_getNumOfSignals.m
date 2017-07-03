%% Developed by Wu Zhiguo(Beijing University of Post and Telecommunication)
% QQ group for discusion: 366102075
% EMAIL:1600682324@qq.com wuzhiguo@bupt.edu.cn
% Github: https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research
% Blog: http://www.jianshu.com/c/6e0897ba0cec [WiFi CSI Based Indoor Localization]
% 本算法参考《空间谱估计理论与算法》（王永良）Page42
% reference paper: Using eigenvalue grads method to estimate the number of signal source
function q = util_getNumOfSignals(sorted_eigval,samples,option)
%% Estimation of Number of Signals Or Number of Paths for 
% Uncoherent Sources/Smoothing Coherent Sources
%
%  sorted_eigval ...... sorted eigen values in descending order
%  samples       ...... number of CSI measurement samples
%  option        ...... option to determine estimation method
%
    nElems = length(sorted_eigval);
    L = samples;
    M = nElems;
    J = zeros(M-1,1);
    if nargin == 2
        option = 'AIC';
    end
    Delta_lambda = zeros(M-1,1);
    Delta_lamda_average = zeros(1,1);
    for n = 1:M-1
        Lamda_up = (1/(M-n))*sum(sorted_eigval(n+1:M));
        Lamda_down = (prod(sorted_eigval(n+1:M)))^(1/(M-n));
        Lambda = Lamda_up/Lamda_down;
        if strcmp(option,'AIC')
            J(n) = 2*L*(M-n)*log(Lambda)+2*n*(2*M-n);
        elseif strcmp(option,'MDL')
            J(n) = L*(M-n)*log(Lambda)+(1/2)*n*(2*M-n)*log(L);
        elseif strcmp(option,'HQ')
            J(n) = L*(M-n)*log(Lambda)+(1/2)*n*(2*M-n)*log(log(L));
        else
            if strcmp(option,'EGM1')
                Delta_lamda_average = (sorted_eigval(1) - sorted_eigval(M))/(M-1);
                Delta_lambda(n) = sorted_eigval(n) - sorted_eigval(n+1);
            elseif strcmp(option,'EGM2')
                Delta_lamda_average = log(sorted_eigval(1)/sorted_eigval(M))/(M-1);
                Delta_lambda(n) = log(sorted_eigval(n)/sorted_eigval(n+1));
            end
            
            if Delta_lambda(n) <= Delta_lamda_average
                q = n-1;
                return
            end
        end
    end
%     J
    [J_sorted, index_J_sorted] = sort(J,'ascend');
    q = index_J_sorted(1);
%     [~,index] = min(J);
%     q = index;
end

