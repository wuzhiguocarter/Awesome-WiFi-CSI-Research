function h = raisedcos_filter(t,T,alpha)
%%% Generate raised cosine pulse
%%%	   t   -  vector of points [t_k] at which to evaluate h(t)
%%%    T   -  symbol period
%%%    alpha   -  excess bandwidth


t = t/T;
i = find(t<0);
if length(i) > 0,
    h(i) = sinc(t(i)).*pi/2.*sinc( alpha*t(i) +.5 )./(1-2*alpha*t(i));
end

i = find(t>=0);
if length(i) > 0,
    h(i) = sinc(t(i)).*pi/2.*sinc( alpha*t(i) -.5 )./(1+2*alpha*t(i));
end

k = find(h == inf);
h(k) = (1/2)*(h(k-1)+h(k+1));