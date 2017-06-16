function [H,g] = genspacetimechan(M,P,L,beta,alpha,tau,p)
%
% 	M :	 number of antennas
% 	P :	 oversampling factor
% 	L :	 length of pulseshape waveform (truncated raised-cos)
% 	beta :   modulation parameter for raised-cos
% 	alpha :  angles of arrival  (r * d-dim)   (in degrees)
% 	tau :	 relative delays (r * d-dim)
%	p : 	 amplitude+phase changes (r * d-dim)  (complex numbers)
%
% Channel: ULA(M), spacing lambda/2, with signals coming in over 
% angles alpha_i, delays tau_i, init phase/amplitude p_i:
%
% result:
%  H: M * L1 P
%  g: 1 * LP: modulation pulse shape function (raised-cosine)


I = sqrt(-1);
r = length(alpha);			% number of multipath rays
max_tau = ceil(max(max(tau)));		% largest unit delay
t = 0 : 1/P : (L+max_tau)-1/P;		% time interval in which H is evaluated


% Construct H: contains impulse response (sum of delayed waveform)
    H = zeros(M, (L+max_tau)*P);
    for j = 1:r,	% each (alpha,tau,p)
	% generate waveform, delayed by tau
	pulse = raisedcos_filter(t - L/2 - tau(j) ,1,beta );	% waveform
	i = find( (t < tau(j)) | (t >= L + tau(j) ));
	pulse(i) = zeros(1,length(i));  	% clip at desired length (L)

	% add to channel matrix
	dp = length(pulse);%%% 32
        for chan = 1:M,
	    % assume ULA(M) with spacing lambda/2
	    a_pulse = pulse * p(j) * exp( I*pi*sin(pi/180*alpha(j))*(chan-1) );
	    H(chan, 1:dp) = H(chan, 1:dp) + a_pulse;
	    end
    end
   
% generate waveform template (truncated raised-cosine)
    t = -L/2:1/P:L/2-1/P;                   % points in time to evaluate g
    g = raisedcos_filter(t,1,beta);
    
    
 
   