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
%% Joint DoA and ToF Estimation MUSIC
% 
% Developed by Wu Zhiguo(Beijing University of Post and Telecommunication)
% QQ group for discusion: 366102075
% EMAIL:1600682324@qq.com wuzhiguo@bupt.edu.cn
% Github: https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research
% Blog: http://www.jianshu.com/c/6e0897ba0cec [WiFi CSI Based Indoor Localization]

%% 
function steervec = util_steering_aoa_tof(aoa,tof,Nrx,ant_dist,fc,Nc,Delta_f)
	steervec = zeros(Nrx*Nc,1);
	Phi = zeros(Nrx,1);
	Omega = zeros(Nc,1);
	lambda = 3e8/fc;
	for i = 1:Nrx
	    Phi(i) = exp(-1j*2*pi*(i-1)*ant_dist*sin(aoa*pi/180)/lambda);
	    for j = 1:Nc
	        Omega(j) = exp(-1j*2*pi*(j-1)*Delta_f*tof);
	        steervec((i-1)*Nc + j) = Phi(i)*Omega(j);
	    end
	end
end

