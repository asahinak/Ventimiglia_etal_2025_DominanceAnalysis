function rasterplotter_Startsm(tempflymat, behavior)
% 
% Raster plot for start times of specified behavior using *_startsm fields
%
% INPUTS:
%   tempflymat: struct array with fields like L_startsm, HB_startsm, etc.
%   behavior: string, e.g., 'lunge', 'butt', 'threat', etc.
%
% Output: raster plot with time in minutes
% Donovan Ventimiglia 10.09.2025

% --- Determine which behavior start times to extract ---
if contains(behavior,'unge') && ~contains(behavior,'~')
    behavTimes = [{tempflymat.L_startsm}];
elseif contains(behavior,'butt') && ~contains(behavior,'~')
    behavTimes = [{tempflymat.HB_startsm}];
elseif contains(behavior,'xtension') && ~contains(behavior,'~')
    behavTimes = [{tempflymat.WE_startsm}];
elseif contains(behavior,'harge') && ~contains(behavior,'~')
    behavTimes = [{tempflymat.CH_startsm}];
elseif contains(behavior,'hreat') && ~contains(behavior,'~')
    behavTimes = [{tempflymat.WT_startsm}];
elseif contains(behavior,'Tussle') && ~contains(behavior,'~')
    behavTimes = [{tempflymat.T_startsm}];
elseif contains(behavior,'Holding') && ~contains(behavior,'~')
    behavTimes = [{tempflymat.H_startsm}];
else
    error('Unrecognized behavior string: %s', behavior);
end

% --- Plotting ---
nFlies = length(tempflymat);
figure; hold on;

for i = 1:nFlies
    starts = behavTimes{i};
    if isempty(starts)
        continue;
    end
    for j = 1:length(starts)
        t_min = starts(j) / 3600;  % convert frame to minutes
        plot([t_min t_min], [i - 0.4, i + 0.4], 'k-', 'LineWidth', 1);
    end
end

% --- Axis formatting ---
ylim([0 nFlies + 1]);
xlim auto;
xlabel('Time (min)');
ylabel('Fly Index');
title(sprintf('Raster Plot: %s (start times)', behavior));
set(gca, 'YDir', 'reverse');  % Optional: fly 1 at top
box off;

end
