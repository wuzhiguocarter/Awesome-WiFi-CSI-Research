function Q = qtrans(m);
% construct unitary centro-hermitian matrix to transform complex data to real

n = floor(m/2);
Pi = eye(n,n); Pi = Pi(n:-1:1,:);
if n == m/2, 	 % m even
    Q = 1/sqrt(2)*[ eye(n,n)  sqrt(-1)*eye(n,n) ;
		    Pi       -sqrt(-1)*Pi       ];
else	          % m odd
    Q = 1/sqrt(2)*[ eye(n,n)   zeros(n,1)  sqrt(-1)*eye(n,n) ;
		    zeros(1,n) sqrt(2)     zeros(1,n)        ;
		    Pi         zeros(n,1)  -sqrt(-1)*Pi      ];
end