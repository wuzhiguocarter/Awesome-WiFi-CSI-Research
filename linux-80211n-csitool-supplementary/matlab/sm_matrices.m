% Intel uses indirect mapping (See IEEE 802.11n-2009 Section 20.3.11.10.1)
% for MIMO transmissions.  The matrices below represent the unitary transmit
% matrices Q, not including the CSD shifting which is applied separately.
%
% To convert between CSI using antennas of one type and CSI using antennas of
% another, we need to undo Q for the first type and convert into Q of the
% second.  Suppose C is the CSI for a single subcarrier using 3 streams over 20
% MHz. Then C == H3 * sm_3_20, where H3 is the "real" underlying 3x3 channel.
%
% H3 = C * sm_3_20';   -- note that M' = inv(M) for a unitary M.
% H2 = H3(1:2,1:2);    -- say we're simulating a 2x2 configuration
% C2 = H2 * sm_2_20;   -- convert from the "real" 2x2 H into the 2x2 CSI
%
% Now C2 is the channel we'd see if the Intel 5300 transmitter sent 2-stream
% packet and we used only 2 receive antennas.
sm_1 = 1;

sm_2_20 = [1 1 ; 1 -1] ./ sqrt(2);
sm_2_40 = [1 1j ; 1j 1] ./ sqrt(2);

sm_3_20 = [-2*pi/16      -2*pi/(80/33)  2*pi/(80/3); ...
            2*pi/(80/23)  2*pi/(48/13)  2*pi/(240/13); ...
           -2*pi/(80/13)  2*pi/(240/37) 2*pi/(48/13)];
sm_3_20 = exp(1).^(1j*sm_3_20) ./ sqrt(3);

sm_3_40 = [-2*pi/16      -2*pi/(80/13)   2*pi/(80/23); ...
           -2*pi/(80/37) -2*pi/(48/11)  -2*pi/(240/107); ...
            2*pi/(80/7)  -2*pi/(240/83) -2*pi/(48/11)];
sm_3_40 = exp(1).^(1j*sm_3_40) ./ sqrt(3);
