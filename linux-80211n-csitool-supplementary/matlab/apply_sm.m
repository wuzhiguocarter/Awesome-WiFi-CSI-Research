function ret = apply_sm(csi, sm)

error(nargchk(2,2,nargin));

%% Shortcut for 1 TX antenna
[M, ~, S] = size(csi);
if M == 1
    ret = csi;
    return;
end

%% Allocate return array
ret = zeros(size(csi));

%% Actually undo the input spatial mapping
for i=1:S
    t = squeeze(csi(:,:,i));
    H = t.' * sm;
    ret(:,:,i) = H.';
end

end