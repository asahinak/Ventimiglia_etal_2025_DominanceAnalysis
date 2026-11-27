
% Dominance classification based on Facing Angle data
%
% Donovan Ventimiglia. October 8th, 2025
%
% FeatureCollection should have been run before this script.
% Load FlyFeatures and flymatAll before running.
%
% This version:
%   - Does NOT generate plots for individual fly pairs



%% Initialize variables

numFlies = size(FlyFeatures.FacingAngle, 1);

dominanceVector_FA = strings(numFlies, 1);  % Facing-angle classification
dominanceByLunges = strings(numFlies, 1);   % Retained if used later

dominantFlies = [];
submissiveFlies = [];
unclearFlies = [];
similarFlies = [];

shiftCutoff = 1.5;

% Initialize shift direction for each fly
facingAngleShift = strings(numFlies, 2);


%% Define analysis period

% Final 10 minutes of the recording
% 60 fps x 600 sec = 36,000 frames

DomPeriod = [size(FlyFeatures.FacingAngle,2)-36000, ...
             size(FlyFeatures.FacingAngle,2)];


%% ============================================================
% FACING ANGLE-BASED DOMINANCE CLASSIFICATION
% ============================================================

% Facing-angle ranges
facingRange = [0, 0.75];      % Fly is facing opponent
fleeingRange = [2.4, 3.15];   % Fly is fleeing opponent
centerRange = [1.2, 1.8];     % For reference only; not used in classification

% Classification thresholds
thresholdFactor = 0.15;
meanThreshold = 1.5;


% Loop through pairs of flies (1&2, 3&4, etc.)
for i = 1:2:numFlies

    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end

    % Extract facing-angle data for dominance period
    fly1DomData = [];
    fly2DomData = [];

    for j = 1:size(DomPeriod, 1)

        fly1DomData = [fly1DomData, ...
            FlyFeatures.FacingAngle(i, ...
            DomPeriod(j,1):DomPeriod(j,2))];

        fly2DomData = [fly2DomData, ...
            FlyFeatures.FacingAngle(i+1, ...
            DomPeriod(j,1):DomPeriod(j,2))];

    end


    %% Generate histograms numerically for classification

    [fly1Freq, binEdges] = histcounts( ...
        fly1DomData, ...
        'BinEdges', 0:0.1:pi);

    [fly2Freq, ~] = histcounts( ...
        fly2DomData, ...
        'BinEdges', 0:0.1:pi);


    % Bin positions
    validBinEdges = binEdges(1:end-1);

    leftBins = ...
        validBinEdges >= facingRange(1) & ...
        validBinEdges <= facingRange(2);

    rightBins = ...
        validBinEdges >= fleeingRange(1) & ...
        validBinEdges <= fleeingRange(2);


    %% Sum three largest facing/fleeing bins

    % Fly 1
    fly1LeftBins = fly1Freq(leftBins);
    fly1RightBins = fly1Freq(rightBins);

    fly1LeftSum = sum(maxk(fly1LeftBins, 3));
    fly1RightSum = sum(maxk(fly1RightBins, 3));


    % Fly 2
    fly2LeftBins = fly2Freq(leftBins);
    fly2RightBins = fly2Freq(rightBins);

    fly2LeftSum = sum(maxk(fly2LeftBins, 3));
    fly2RightSum = sum(maxk(fly2RightBins, 3));


    %% Mean facing angle

    meanFly1 = mean(fly1DomData);
    meanFly2 = mean(fly2DomData);


    %% Dominance classification
    % Facing/fleeing bias is determined by comparing the sums of the three
    % largest 0.1-rad histogram bins in each range. A range must exceed the
    % other by at least 15%, together with the fly's mean angle being below
    % (facing) or above (fleeing) 1.5 rad.

    if ...
        (fly1LeftSum > fly1RightSum * (1 + thresholdFactor)) && ...
        (fly2LeftSum > fly2RightSum * (1 + thresholdFactor)) && ...
        (meanFly1 < meanThreshold) && ...
        (meanFly2 < meanThreshold)

        % Both flies face one another
        dominanceVector_FA(i) = 'No Dominance';
        dominanceVector_FA(i+1) = 'No Dominance';


    elseif ...
        (fly1LeftSum > fly1RightSum * (1 + thresholdFactor)) && ...
        (fly2RightSum > fly2LeftSum * (1 + thresholdFactor)) && ...
        (meanFly1 < meanThreshold) && ...
        (meanFly2 > meanThreshold)

        % Fly 1 dominant, Fly 2 submissive
        dominanceVector_FA(i) = 'Dominant';
        dominanceVector_FA(i+1) = 'Submissive';


    elseif ...
        (fly2LeftSum > fly2RightSum * (1 + thresholdFactor)) && ...
        (fly1RightSum > fly1LeftSum * (1 + thresholdFactor)) && ...
        (meanFly2 < meanThreshold) && ...
        (meanFly1 > meanThreshold)

        % Fly 2 dominant, Fly 1 submissive
        dominanceVector_FA(i+1) = 'Dominant';
        dominanceVector_FA(i) = 'Submissive';


    else

        % Unclear or balanced
        dominanceVector_FA(i) = 'Unclear';
        dominanceVector_FA(i+1) = 'Unclear';

    end


    %% Print pair-level classification information

    fprintf('Fly Pair %d-%d:\n', i, i+1);

    fprintf( ...
        'Fly %d Left Sum: %.2f, Right Sum: %.2f\n', ...
        i, fly1LeftSum, fly1RightSum);

    fprintf( ...
        'Fly %d Left Sum: %.2f, Right Sum: %.2f\n', ...
        i+1, fly2LeftSum, fly2RightSum);

    fprintf( ...
        'Dominance Classification: Fly %d -> %s, Fly %d -> %s\n\n', ...
        i, dominanceVector_FA(i), ...
        i+1, dominanceVector_FA(i+1));

end


%% Output facing-angle classifications

disp('Facing Angle-Based Dominance Classification for each fly:');
disp(dominanceVector_FA);


%% ============================================================
% FACING ANGLE DISTRIBUTION ANALYSIS
% ============================================================
%
% Compares facing-angle distributions for each fly pair during
% the same final 10-min dominance period.
%
% Analyses:
%   1. Kolmogorov-Smirnov test
%   2. Cohen's d
%   3. Median facing-angle shift
%
% Facing-angle values are also pooled by dominance category.
% ============================================================


%% Initialize pooled category data

dominantFacingAngles = [];
submissiveFacingAngles = [];
noDominanceFacingAngles = [];
unclearDominanceFacingAngles = [];


%% Analyze each pair

for i = 1:2:numFlies

    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end


    %% Extract facing-angle data

    fly1DomData = [];
    fly2DomData = [];

    for j = 1:size(DomPeriod, 1)

        fly1DomData = [fly1DomData, ...
            FlyFeatures.FacingAngle(i, ...
            DomPeriod(j,1):DomPeriod(j,2))];

        fly2DomData = [fly2DomData, ...
            FlyFeatures.FacingAngle(i+1, ...
            DomPeriod(j,1):DomPeriod(j,2))];

    end


    %% 1. Kolmogorov-Smirnov test

    [h, p] = kstest2(fly1DomData, fly2DomData);

    % h = 1: distributions differ significantly
    % h = 0: no significant difference detected
    ksComparison = h;


    %% 2. Cohen's d

    meanFly1 = mean(fly1DomData);
    meanFly2 = mean(fly2DomData);

    stdFly1 = std(fly1DomData);
    stdFly2 = std(fly2DomData);

    pooledStd = sqrt((stdFly1^2 + stdFly2^2) / 2);

    cohensD = abs(meanFly1 - meanFly2) / pooledStd;


    %% 3. Median facing-angle shift

    medianFly1 = median(fly1DomData);
    medianFly2 = median(fly2DomData);


    %% Store facing angles according to dominance classification

    if ...
        strcmp(dominanceVector_FA(i), 'Dominant') && ...
        strcmp(dominanceVector_FA(i+1), 'Submissive')

        % Fly 1 dominant, Fly 2 submissive
        dominantFacingAngles = ...
            [dominantFacingAngles, fly1DomData];

        submissiveFacingAngles = ...
            [submissiveFacingAngles, fly2DomData];


    elseif ...
        strcmp(dominanceVector_FA(i), 'Submissive') && ...
        strcmp(dominanceVector_FA(i+1), 'Dominant')

        % Fly 2 dominant, Fly 1 submissive
        dominantFacingAngles = ...
            [dominantFacingAngles, fly2DomData];

        submissiveFacingAngles = ...
            [submissiveFacingAngles, fly1DomData];


    elseif strcmp(dominanceVector_FA(i), 'No Dominance')

        % Both flies are No Dominance
        noDominanceFacingAngles = ...
            [noDominanceFacingAngles, ...
             fly1DomData, fly2DomData];


    elseif strcmp(dominanceVector_FA(i), 'Unclear')

        % Both flies are unclear
        unclearDominanceFacingAngles = ...
            [unclearDominanceFacingAngles, ...
             fly1DomData, fly2DomData];

    end


    %% Print statistics for pair

    fprintf('Fly Pair %d-%d:\n', i, i+1);

    fprintf( ...
        'Kolmogorov-Smirnov Test: h = %d, p = %.3f\n', ...
        ksComparison, p);

    fprintf( ...
        'Cohen''s d: %.3f\n', ...
        cohensD);

    fprintf( ...
        'Median Shift: Fly %d = %.2f, Fly %d = %.2f\n\n', ...
        i, medianFly1, ...
        i+1, medianFly2);

end


%% ============================================================
% SUMMARY
% ============================================================

fprintf( ...
    'Dominant Facing Angles: %d values collected.\n', ...
    length(dominantFacingAngles));

fprintf( ...
    'Submissive Facing Angles: %d values collected.\n', ...
    length(submissiveFacingAngles));

fprintf( ...
    'No Dominance Facing Angles: %d values collected.\n', ...
    length(noDominanceFacingAngles));

fprintf( ...
    'Unclear Facing Angles: %d values collected.\n', ...
    length(unclearDominanceFacingAngles));

fprintf('Unclear Facing Angles: %d values collected.\n', ...
    length(unclearDominanceFacingAngles));


%% ============================================================
% PLOTS: PAIR-LEVEL DIAGNOSTICS AND POOLED CATEGORY DISTRIBUTIONS
% ============================================================

saveFigures = questdlg( ...
    'Would you like to save the figures?', ...
    'Save Figures', 'Yes', 'No', 'No');

if strcmp(saveFigures, 'Yes')
    matlabFigDir = 'MATLAB_Figures';
    epsDir = 'EPS_Figures';

    if ~exist(matlabFigDir, 'dir'), mkdir(matlabFigDir); end
    if ~exist(epsDir, 'dir'), mkdir(epsDir); end
end

% Define comparison periods for pair-level facing-angle plots.
nFrames = size(FlyFeatures.FacingAngle, 2);
firstTenMin = 1:min(36000, nFrames);
finalTenMin = max(1, nFrames-36000+1):nFrames;
fullRecording = 1:nFrames;
binEdges = 0:0.1:pi;

%% Pair-level facing-angle distributions and lunge rasters

pairNum = 1;

for i = 1:2:numFlies
    if i + 1 > numFlies
        break;
    end

    fly1 = FlyFeatures.FacingAngle(i, :);
    fly2 = FlyFeatures.FacingAngle(i+1, :);

    fig = figure('Color', 'w');

    % First 10 minutes
    subplot(2, 3, 1); hold on;
    histogram(fly1(firstTenMin), 'BinEdges', binEdges, ...
        'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(fly2(firstTenMin), 'BinEdges', binEdges, ...
        'FaceColor', 'r', 'FaceAlpha', 0.5);
    title('First 10 min');
    xlabel('Facing angle (rad)'); ylabel('Frequency');
    legend(sprintf('Fly %d', i), sprintf('Fly %d', i+1));
    hold off;

    % Final 10-minute dominance window
    subplot(2, 3, 2); hold on;
    histogram(fly1(finalTenMin), 'BinEdges', binEdges, ...
        'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(fly2(finalTenMin), 'BinEdges', binEdges, ...
        'FaceColor', 'r', 'FaceAlpha', 0.5);
    title(sprintf('Final 10 min: %s', dominanceVector_FA(i)));
    xlabel('Facing angle (rad)'); ylabel('Frequency');
    legend(sprintf('Fly %d', i), sprintf('Fly %d', i+1));
    hold off;

    % Full recording
    subplot(2, 3, 3); hold on;
    histogram(fly1(fullRecording), 'BinEdges', binEdges, ...
        'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(fly2(fullRecording), 'BinEdges', binEdges, ...
        'FaceColor', 'r', 'FaceAlpha', 0.5);
    title('Full recording');
    xlabel('Facing angle (rad)'); ylabel('Frequency');
    legend(sprintf('Fly %d', i), sprintf('Fly %d', i+1));
    hold off;

    % Lunge raster
    subplot(2, 1, 2);
    rasterplotter_OH(flymatAll(i:i+1), 'lunge', '');
    title(sprintf('Lunge raster: Fly %d vs %d', i, i+1));
    xlabel('Time (frames)');
    ylabel('Lunges');

    if strcmp(saveFigures, 'Yes')
        set(fig, 'Position', [337, 403, 1366, 934]);
        figName = sprintf('Pair_%d', pairNum);
        savefig(fig, fullfile(matlabFigDir, [figName '.fig']));
        exportgraphics(fig, fullfile(epsDir, [figName '.eps']), ...
            'ContentType', 'vector');
    end

    pairNum = pairNum + 1;
end

%% Pooled facing-angle distributions by classification

categories = {'Dominant', 'Submissive', 'No Dominance', 'Unclear'};
facingAnglesData = { ...
    dominantFacingAngles, ...
    submissiveFacingAngles, ...
    noDominanceFacingAngles, ...
    unclearDominanceFacingAngles};

for k = 1:numel(categories)
    if isempty(facingAnglesData{k})
        warning('No data available for category: %s', categories{k});
        continue;
    end

    plotFacingAngleDistribution(facingAnglesData{k}, categories{k});
    fig = gcf;

    if strcmp(saveFigures, 'Yes')
        fileBase = [strrep(categories{k}, ' ', '_'), '_FacingAngle'];
        savefig(fig, fullfile(matlabFigDir, [fileBase '.fig']));
        exportgraphics(fig, fullfile(epsDir, [fileBase '.eps']), ...
            'ContentType', 'vector');
    end
end