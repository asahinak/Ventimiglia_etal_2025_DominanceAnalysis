function rasterplotter(tempflymat, behavior, makeNewFig)
% Raster plot for start times of specified behavior using *_startsm fields
%
% INPUTS:
%   tempflymat: struct array with fields like L_startsm, HB_startsm, etc.
%   behavior: string, e.g., 'lunge', 'butt', 'threat', etc.
%   vswho: unused here but kept for compatibility
%   makeNewFig: 1 = make new figure (default), 0 = plot into existing figure (hold on)
%
% Output: raster plot with time in minutes
% Optimized version - faster for large datasets
% Donovan Ventimiglia, optimized 10.09.2025
% Updated: 10.10.2025 — added figure control, thinner lines,
% and fixed x-axis to recording length from L_binary

% --- Handle default input ---
if nargin < 4 || isempty(makeNewFig)
    makeNewFig = 1; % default to creating a new figure
end

% --- Determine which behavior start times to extract ---
if contains(behavior,'unge') && ~contains(behavior,'~')
    behavTimes = {tempflymat.L_startsm};
elseif contains(behavior,'butt') && ~contains(behavior,'~')
    behavTimes = {tempflymat.HB_startsm};
elseif contains(behavior,'xtension') && ~contains(behavior,'~')
    behavTimes = {tempflymat.WE_startsm};
elseif contains(behavior,'harge') && ~contains(behavior,'~')
    behavTimes = {tempflymat.CH_startsm};
elseif contains(behavior,'hreat') && ~contains(behavior,'~')
    behavTimes = {tempflymat.WT_startsm};
elseif contains(behavior,'Tussle') && ~contains(behavior,'~')
    behavTimes = {tempflymat.T_startsm};
elseif contains(behavior,'Holding') && ~contains(behavior,'~')
    behavTimes = {tempflymat.H_startsm};
else
    error('Unrecognized behavior string: %s', behavior);
end

% --- Collect all lines into large arrays before plotting ---
X = {};  % For time in minutes (x start & stop)
Y = {};  % For y start & stop
nFlies = length(tempflymat);

for i = 1:nFlies
    starts = behavTimes{i};
    if isempty(starts)
        continue;
    end
    t = starts / 3600;  % convert to minutes
    X{end+1} = [t; t; NaN(size(t))];  % vertical lines with NaNs to separate
    Y{end+1} = [i - 0.4 + zeros(size(t)); i + 0.4 + zeros(size(t)); NaN(size(t))];
end

% --- Plot all at once for speed ---
if makeNewFig
    figure;
else
    hold on;
end

Xcat = cat(2, X{:});
Ycat = cat(2, Y{:});
plot(Xcat(:), Ycat(:), 'k-', 'LineWidth', 0.1);  % thinner lines

% --- Determine x-axis limit from L_binary length (recording duration) ---
if isfield(tempflymat, 'L_binary')
    lengths = arrayfun(@(x) size(x.L_binary, 2), tempflymat);
    maxLen = max(lengths);
    xlim([0 maxLen / 3600]);  % convert frames to minutes
end

% --- Axis formatting (only if new figure) ---
if makeNewFig
    ylim([0 nFlies + 1]);
    xlabel('Time (min)');
    ylabel('Fly Index');
    title(sprintf('%s Raster', behavior), 'Interpreter', 'none');
    set(gca, 'YDir', 'reverse');
    box off;
end

end
