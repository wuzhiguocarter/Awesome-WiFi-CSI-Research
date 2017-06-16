function R=R_hankel(m,Rxy,N,Q)
R1=[];
R2=[];
for mm=1:Q
    R1=[R1;Rxy(m,mm)];
end
for i=1:N-Q+1
  R2=[R2,Rxy(m,i+Q-1)];  
end
R=hankel(R1,R2);