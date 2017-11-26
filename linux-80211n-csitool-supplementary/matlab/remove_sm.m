function ret = remove_sm(csi, rate)

%% Shortcut for 1 TX antenna
[M, ~, S] = size(csi);
if M == 1
    ret = csi;
    return;
end

%% Allocate return array
ret = zeros(size(csi));

%% Figure out the right SM matrix
sm_matrices;
if bitand(rate, 2048) == 2048
    if M == 3
        sm = sm_3_40;
    elseif M == 2
        sm = sm_2_40;
    end
else
    if M == 3
        sm = sm_3_20;
    elseif M == 2
        sm = sm_2_20;
    end
end

%% Actually undo the input spatial mapping
for i=1:S
    t = squeeze(csi(:,:,i));
    H = t.' * sm';
    ret(:,:,i) = H.';
end

end