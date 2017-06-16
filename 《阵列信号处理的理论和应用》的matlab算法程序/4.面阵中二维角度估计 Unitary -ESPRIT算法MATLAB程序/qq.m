function p=qq(N)
k=fix(N/2);
I=eye(k);
II=fliplr(I);
if mod(N,2)==0
    p=[I,j*I;II,-j*II]/sqrt(2);
else
    p=[I,zeros(k,1),j*I;zeros(1,k),sqrt(2),zeros(1,k);II,zeros(k,1),-j*II]/sqrt(2);
end