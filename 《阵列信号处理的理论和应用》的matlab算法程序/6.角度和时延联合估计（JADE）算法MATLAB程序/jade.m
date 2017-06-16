function [theta,tau] = jade(H,g,r,P,m1,m2);


    [M,PL] = size(H);
    if length(g) < PL, g = [g zeros(1,PL-length(g))]; end	% zero pad
    if length(g) > PL, 
	H = [H zeros(M,length(g)-PL)]; 		% zero pad
	[M,PL] = size(H);
    end	% zero pad

    if nargin < 4, P=1; end
    if nargin < 5, m1=1; end
    if nargin < 6, m2=1; end

    L = PL/P;		% impulse response length measured in ``symbol periods''

    if m1*M <= r, error('m1 is not large enough to separate all sources'); end


% STEP 1: FFT OF ROWS OF G TO GET VANDERMONDE STRUCTURE ON THE ROWS

    G = fft(g);
    H1 = fft(H.').';

% assume bandlimited signals: truncate out-of-band part
% because G is very small there
    if ( floor(L/2)*2 == L ),
	% L even
	G = G([PL-L/2+1:PL 1:L/2]);
	H1 = H1(:,[PL-L/2+1:PL 1:L/2]);
    else
	% L odd
	L2 = floor(L/2);
	G = G([PL-L2+1:PL 1:L2+1]);
	H1 = H1(:,[PL-L2+1:PL 1:L2+1]);
    end

% divide out the known signal waveform
% (assume it is nonsing! else work on intervals)
    for i = 1:M,
	rat(i,:) = H1(i,:) ./ G;
    end

% STEP 2: FORM HANKEL MATRIX OF DATA, WITH m1 FREQ SHIFTS AND m2 SPATIAL SHIFTS

    [m_rat,n_rat] = size(rat);

    % sanity checks
    if m1 >= n_rat, n_rat, error('m1 too large to form so many shifts'); end
    if m2 >= m_rat, m_rat, error('m2 too large to form so many shifts'); end
    if ((r > (m1-1)*(M-m2+1)) | (r > m1*(M-m2)) | (r > 2*m2*(n_rat-m1+1))), 
	error('m1 too large to form so many shifts and still detect r paths'); 
    end

    % spatial shifts
    X0 = [];
    for i=1:m2;
       X0 = [X0 rat(i:M-m2+i,:)];
    end
    M = M-m2+1;		% number of antennas is reduced by the shifting process

    % freq shifts
    X = [];
    Xt = [];
    for i=1:m1;
       Xshift = [];
       for j=1:m2;
	   Xshift = [Xshift X0(:,(j-1)*n_rat+i:j*n_rat-m1+i)];
       end
       Xt = [Xt; Xshift];
   end
    % size Xt: m1(M-m2+1) * (m2-1)(n_rat-m1+1)
    Rat = Xt;

% STEP 3: TRANSFORM TO REAL; DOUBLE NUMBER OF OBSERVATIONS
% same tricks as in `unitary esprit'

    Q2m = qtrans(m1);
    Im = eye(m1,m1);
    Jm = Im(m1:-1:1,:);
    Q2M = qtrans(M);
    IM = eye(M,M);
    JM = IM(M:-1:1,:);
    Q2M = qtrans(M);

    Q2 = kron(Q2m,Q2M);
    J = kron(Jm,JM);

    [mR,NR] = size(Rat);
    Ratreal = [];
    for i=1:NR,
	z1 = Rat(:,i);		% kron(a1,a2)
	z2 = J*conj(z1);	% kron(J a1,J a2)
	Z = real(Q2' * [z1 z2] * [1 sqrt(-1); 1 -sqrt(-1)] ); 

	Ratreal = [Ratreal Z];
    end

    Rat = Ratreal;
    [mR,NR] = size(Rat);



% STEP 4: SELECT (should be ESTIMATE?) NUMBER OF MULTIPATHS FROM Rat

    [u,s,v] = svd(Rat);		% only need u: use subspace tracking...
    u = u(:,1:r);
    v = v(:,1:r);

% r should be set at a gap in the singular values


% STEP 5: FORM SHIFTS OF THE DATA MATRICES
% AND REDUCE RANKS OF DATA MATRICES

    [mM,PL1] = size(Rat);

% selection and transform matrices:
    Jxm = [eye(m1-1,m1-1)  zeros(m1-1,1)];
    Jym = [zeros(m1-1,1) eye(m1-1,m1-1) ];
    JxM = [eye(M-1,M-1)  zeros(M-1,1)];
    JyM = [zeros(M-1,1) eye(M-1,M-1) ];

    Q1m = qtrans(m1-1);
    Q1M = qtrans(M-1);

    Kxm = real( kron(Q1m',IM) * kron(Jxm+Jym,IM) * kron(Q2m,IM) );
    Kym = real( kron(Q1m',IM) * sqrt(-1)*kron(Jxm-Jym,IM) * kron(Q2m,IM) );

    KxM = real( kron(Im,Q1M') * kron(Im,JxM+JyM) * kron(Im,Q2M) );
    KyM = real( kron(Im,Q1M') * sqrt(-1)*kron(Im,JxM-JyM) * kron(Im,Q2M) );

% For estimating DOA:
    Ex1 = KxM*u;
    Ey1 = KyM*u;
    % size: m(M-1) by r

% For estimating tau:
    % select first/last m1-1 blocks (each of M rows)
    Ex2 = Kxm*u;
    Ey2 = Kym*u;
    % size: (M-1)m1 by r


% sanity checks:
    % X1, X2, Y1, Y2 should be taller and wider than r
    if size(Ex1,1) < r, error('Ex1 not tall enough'); end
    if size(Ex2,1) < r, error('Ex2 not tall enough'); end

% reduce to r columns
    [Q,R] = qr([Ex1,Ey1]);
    Ex1 = R(1:r,1:r);
    Ey1 = R(1:r,r+1:2*r);

    [Q,R] = qr([Ex2,Ey2]);
    Ex2 = R(1:r,1:r);
    Ey2 = R(1:r,r+1:2*r);



% STEP 6: DO JOINT DIAGONALIZATION on Ex2\Ey2 and Ex1\Ey1

% 2-D Mathews-Zoltowski-Haardt method.  There are at least 4 other methods, but
% the differences are usually small.  This one is easiest with standard matlab

    A = Ex2\Ey2 + sqrt(-1)*Ex1\Ey1;
    [V,Lambda] = eig(A);
    Phi = real( Lambda );
    Theta = -imag( Lambda );

% STEP 7: COMPUTE THE DELAYS AND ANGLES
    Phi = diag(Phi);
    Theta = diag(Theta);
    
    tau = -2*atan(real(Phi))/(2*pi)*L;
    sintheta = 2*atan(real(Theta));

    theta = asin(sintheta/pi);
    theta = theta*180/pi;			% DOA in degrees