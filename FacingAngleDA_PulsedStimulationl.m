% Dominance classification based on Facing Angle data
% 6 period pulsed Stimulation protocol.
% Donovan Ventimiglia. October 8th, 2025

% Note:
% FeatureCollection should have been run before this script.
% Load FlyFeatures and flymatAll before running. 


% Setup
numFlies = size(FlyFeatures.FacingAngle, 1);
dominanceVector_FA = strings(numFlies, 1); 
dominanceByLunges = strings(numFlies, 1); 
dominantFlies = []; submissiveFlies = []; unclearFlies = []; similarFlies = [];

% Pulse windows
pulses = [18000, 36000;
          54000, 72000;
          90000, 108000;
          126000, 144000;
          162000, 180000;
          198000, 216000];
lastTwoPulses = [162000, 180000; 198000, 216000];
prestimulationPeriod = [1, 18000];
firstPulse = [18000, 36000];

% Binning
binEdges = 0:0.1:pi;
plotsPerRow = 3;
rowsPerFigure = 2;

% Prompt to save figures
saveFigures = questdlg('Would you like to save the figures?', 'Save Figures', 'Yes', 'No', 'No');

% Create directories if saving is requested
if strcmp(saveFigures, 'Yes')
    if ~exist('MATLAB_Figures', 'dir'), mkdir('MATLAB_Figures'); end
    if ~exist('EPS_Figures', 'dir'), mkdir('EPS_Figures'); end
end

% Loop over fly pairs
pairNum = 1;
for i = 1:2:numFlies
    if i + 1 > numFlies
        warning('Odd number of flies, skipping last unpaired fly.');
        break;
    end

    fly1 = FlyFeatures.FacingAngle(i, :);
    fly2 = FlyFeatures.FacingAngle(i + 1, :);

    %% --- Create Figure ---
    fig = figure;
    plotIndex = 1;

    %% --- Prestimulation ---
    f1 = fly1(prestimulationPeriod(1):prestimulationPeriod(2));
    f2 = fly2(prestimulationPeriod(1):prestimulationPeriod(2));
    subplot(rowsPerFigure, plotsPerRow, plotIndex); hold on;
    histogram(f1, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(f2, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    plot([mean(f1), mean(f1)], ylim, 'b--', 'LineWidth', 2);
    plot([mean(f2), mean(f2)], ylim, 'r--', 'LineWidth', 2);
    title(sprintf('Fly %d vs %d (Prestim)', i, i+1));
    xlabel('Facing Angle'); ylabel('Frequency');
    legend(sprintf('Fly %d (%.2f)', i, mean(f1)), sprintf('Fly %d (%.2f)', i+1, mean(f2)));
    hold off;
    plotIndex = plotIndex + 1;

    %% --- First Pulse ---
    f1 = fly1(firstPulse(1):firstPulse(2));
    f2 = fly2(firstPulse(1):firstPulse(2));
    subplot(rowsPerFigure, plotsPerRow, plotIndex); hold on;
    histogram(f1, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(f2, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    plot([mean(f1), mean(f1)], ylim, 'b--', 'LineWidth', 2);
    plot([mean(f2), mean(f2)], ylim, 'r--', 'LineWidth', 2);
    title(sprintf('Fly %d vs %d (1st Pulse)', i, i+1));
    xlabel('Facing Angle'); ylabel('Frequency');
    legend(sprintf('Fly %d (%.2f)', i, mean(f1)), sprintf('Fly %d (%.2f)', i+1, mean(f2)));
    hold off;
    plotIndex = plotIndex + 1;

    %% --- Last Two Pulses ---
    f1 = []; f2 = [];
    for j = 1:size(lastTwoPulses, 1)
        f1 = [f1, fly1(lastTwoPulses(j,1):lastTwoPulses(j,2))];
        f2 = [f2, fly2(lastTwoPulses(j,1):lastTwoPulses(j,2))];
    end
    subplot(rowsPerFigure, plotsPerRow, plotIndex); hold on;
    histogram(f1, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(f2, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    plot([mean(f1), mean(f1)], ylim, 'b--', 'LineWidth', 2);
    plot([mean(f2), mean(f2)], ylim, 'r--', 'LineWidth', 2);
    title(sprintf('Fly %d vs %d (Last 2 Pulses)', i, i+1));
    xlabel('Facing Angle'); ylabel('Frequency');
    legend(sprintf('Fly %d (%.2f)', i, mean(f1)), sprintf('Fly %d (%.2f)', i+1, mean(f2)));
    hold off;

    %% --- Lunge Raster Plot ---
    subplot(rowsPerFigure, 1, rowsPerFigure);
    rasterplotter_OH(flymatAll(i:i+1), 'lunge', '');
    title(sprintf('Lunge Raster: Fly %d vs %d', i, i+1));
    xlabel('Time (frames)');
    ylabel('Lunges');

    %% --- Save Figure ---
    if strcmp(saveFigures, 'Yes')
        set(fig, 'Position', [337, 403, 1366, 934]);
        set(fig, 'PaperPositionMode', 'auto');
        set(fig, 'PaperUnits', 'points');
        paperPosition = get(fig, 'PaperPosition');
        set(fig, 'PaperSize', [paperPosition(3), paperPosition(4)]);

        figName = sprintf('Pair_%d', pairNum);
        savefig(fig, fullfile('MATLAB_Figures', [figName '.fig']));
        exportgraphics(fig, fullfile('EPS_Figures', [figName '.eps']), 'ContentType', 'vector');
    end

    close(fig);
    pairNum = pairNum + 1;
end



%% --- Facing Angle-Based Dominance Classification (Last Two Pulses) ---
% This section classifies dominance based on the distribution of facing angles during the last 
% two pulses. It analyzes each fly's behavior to determine if it was primarily facing, fleeing, 
% or uncertain during this period.

% Define the left, right, and center ranges for facing, fleeing, and unclear
facingRange = [0, 0.75];     % Fly is facing opponent
fleeingRange = [2.4, 3.15];  % Fly is fleeing opponent
centerRange = [1.2, 1.8];    % Center region for unclear behavior

% Define the 15% threshold for "unclear" classification
thresholdFactor = 0.15;
meanThreshold = 1.5; % Adjust as needed for median threshold

% Define last two pulses for analysis
lastTwoPulses = [162000, 180000; 198000, 216000];

% Loop through pairs of flies (1&2, 3&4, etc.)
for i = 1:2:numFlies
    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end
    
    % Extract the data for the last two pulses for both flies in the pair
    fly1LastTwoPulseData = [];
    fly2LastTwoPulseData = [];
    
    % Combine the data from the last two pulses for each fly
    for j = 1:size(lastTwoPulses, 1)
        fly1LastTwoPulseData = [fly1LastTwoPulseData, FlyFeatures.FacingAngle(i, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
        fly2LastTwoPulseData = [fly2LastTwoPulseData, FlyFeatures.FacingAngle(i + 1, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
    end
    
    % Generate histograms and get the frequencies in each bin
    [fly1Freq, binEdges] = histcounts(fly1LastTwoPulseData, 'BinEdges', 0:0.1:pi);
    [fly2Freq, ~] = histcounts(fly2LastTwoPulseData, 'BinEdges', 0:0.1:pi);
    
    % Find the bins corresponding to the left, center, and right ranges
    validBinEdges = binEdges(1:end-1);  % Use only the first N-1 edges for indexing bins
    leftBins = validBinEdges >= facingRange(1) & validBinEdges <= facingRange(2);
    rightBins = validBinEdges >= fleeingRange(1) & validBinEdges <= fleeingRange(2);

    % For Fly 1, get the three largest bins on the left and right sides
    fly1LeftBins = fly1Freq(leftBins);
    fly1RightBins = fly1Freq(rightBins);
    fly1LeftSum = sum(maxk(fly1LeftBins, 3));  % Sum of the largest 3 bins on the left
    fly1RightSum = sum(maxk(fly1RightBins, 3));  % Sum of the largest 3 bins on the right

    % For Fly 2, get the three largest bins on the left and right sides
    fly2LeftBins = fly2Freq(leftBins);
    fly2RightBins = fly2Freq(rightBins);
    fly2LeftSum = sum(maxk(fly2LeftBins, 3));  % Sum of the largest 3 bins on the left
    fly2RightSum = sum(maxk(fly2RightBins, 3));  % Sum of the largest 3 bins on the right

    % Compute the medians of facing angle distributions
    meanFly1 = mean(fly1LastTwoPulseData);
    meanFly2 = mean(fly2LastTwoPulseData);

    % Classification based on histogram sums and median
    if (fly1LeftSum > fly1RightSum * (1 + thresholdFactor)) && ...
       (fly2LeftSum > fly2RightSum * (1 + thresholdFactor)) && ...
       (meanFly1 < meanThreshold) && (meanFly2 < meanThreshold)
        % Both flies are facing each other -> No Dominance
        dominanceVector_FA(i) = 'No Dominance';
        dominanceVector_FA(i + 1) = 'No Dominance';
    
    elseif (fly1LeftSum > fly1RightSum * (1 + thresholdFactor)) && ...
           (fly2RightSum > fly2LeftSum * (1 + thresholdFactor)) && ...
           (meanFly1 < meanThreshold) && (meanFly2 > meanThreshold)
        % Fly 1 faces opponent, Fly 2 flees -> Dominance Established
        dominanceVector_FA(i) = 'Dominant';
        dominanceVector_FA(i + 1) = 'Submissive';
    
    elseif (fly2LeftSum > fly2RightSum * (1 + thresholdFactor)) && ...
           (fly1RightSum > fly1LeftSum * (1 + thresholdFactor)) && ...
           (meanFly2 < meanThreshold) && (meanFly1 > meanThreshold)
        % Fly 2 faces opponent, Fly 1 flees -> Dominance Established
        dominanceVector_FA(i + 1) = 'Dominant';
        dominanceVector_FA(i) = 'Submissive';
    
    else
        % If unclear or balanced -> Unclear
        dominanceVector_FA(i) = 'Unclear';
        dominanceVector_FA(i + 1) = 'Unclear';
    end

    % Print the results for each pair for verification
    fprintf('Fly Pair %d-%d:\n', i, i + 1);
    fprintf('Fly %d Left Sum: %.2f, Right Sum: %.2f\n', i, fly1LeftSum, fly1RightSum);
    fprintf('Fly %d Left Sum: %.2f, Right Sum: %.2f\n', i + 1, fly2LeftSum, fly2RightSum);
    fprintf('Dominance Classification: Fly %d -> %s, Fly %d -> %s\n\n', ...
        i, dominanceVector_FA(i), i + 1, dominanceVector_FA(i + 1));
    
    % % --- Optional: Plot histograms for visualization ---
    % figure;
    % subplot(2, 1, 1);  % Top subplot for histograms
    % hold on;
    % 
    % % Plot histograms for each fly's data
    % histogram(fly1LastTwoPulseData, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    % histogram(fly2LastTwoPulseData, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    % 
    % % Add dotted lines for the medians of each fly
    % plot([medianFly1 medianFly1], ylim, 'b--', 'LineWidth', 2);  % Blue dotted line for Fly 1 median
    % plot([medianFly2 medianFly2], ylim, 'r--', 'LineWidth', 2);  % Red dotted line for Fly 2 median
    % 
    % % Add title and labels
    % title(sprintf('Facing Angle Distribution for Fly %d vs Fly %d', i, i + 1));
    % xlabel('Facing Angle');
    % ylabel('Frequency');
    % legend(sprintf('Fly %d Median: %.2f', i, medianFly1), sprintf('Fly %d Median: %.2f', i+1, medianFly2));
    % 
    % hold off;
    % 
    % % Plot the classification information without center bin details
    % subplot(2, 1, 2);  % Bottom subplot for dominance classification
    % axis off;
    % text(0.1, 0.9, sprintf('Fly %d (Blue): Left Sum = %.2f, Right Sum = %.2f', i, fly1LeftSum, fly1RightSum), 'FontSize', 10);
    % text(0.1, 0.8, sprintf('Fly %d (Red): Left Sum = %.2f, Right Sum = %.2f', i + 1, fly2LeftSum, fly2RightSum), 'FontSize', 10);
    % text(0.1, 0.7, sprintf('Classification: Fly %d -> %s, Fly %d -> %s', ...
    %     i, dominanceVector_FA(i), i + 1, dominanceVector_FA(i + 1)), 'FontSize', 10);
    % 
    % hold off;
end

% Output facing angle dominance classification results
disp('Facing Angle-Based Dominance Classification for each fly:');
disp(dominanceVector_FA);


%% --- Facing Angle Distribution Analysis for Last Two Pulses ---
% This section compares the facing angle distributions for pairs of flies during the last two
% pulses. Three statistical methods are used for analysis:
%
% 1. **Kolmogorov-Smirnov (K-S) Test**: Tests if the facing angle distributions for the two flies 
%    are significantly different. A result of h = 1 indicates a difference, while h = 0 means 
%    the distributions are similar.
%
% 2. **Cohen's d (Effect Size)**: Measures the magnitude of the difference between the two flies'
%    mean facing angles. A larger Cohen's d value suggests a stronger difference.
%
% 3. **Percentile Shift Comparison**: Compares the medians of the facing angle distributions to 
%    assess directional dominance or submission.
%
% Based on the `dominanceVector_FA` classification, the facing angles for each category 
% (Dominant, Submissive, No Dominance, and Unclear) are stored in separate arrays for further analysis. 
% For each pair, the results of the K-S test, Cohen's d, and the median shift are printed for 
% potential use or reference.

% Define the last two pulse windows
lastTwoPulses = [162000, 180000; 198000, 216000];

% Initialize variables to store facing angles for each category
dominantFacingAngles = [];
submissiveFacingAngles = [];
noDominanceFacingAngles = [];  
unclearDominacneFacingAngles= []; 

% Loop through pairs of flies (1&2, 3&4, etc.)
for i = 1:2:numFlies
    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end

    % Extract the data for the last two pulses for the two flies in the pair
    fly1LastThreePulseData = [];
    fly2LastThreePulseData = [];
    
    % Combine the data from the last two pulses for each fly
    for j = 1:size(lastTwoPulses, 1)
        fly1LastThreePulseData = [fly1LastThreePulseData, FlyFeatures.FacingAngle(i, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
        fly2LastThreePulseData = [fly2LastThreePulseData, FlyFeatures.FacingAngle(i + 1, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
    end

    % 1. Kolmogorov-Smirnov (K-S) Test to compare distributions
    [h, p] = kstest2(fly1LastThreePulseData, fly2LastThreePulseData);  % h = 0 means same distribution, h = 1 means different distribution
    ksComparison = h;  % Result of K-S test: 1 if different, 0 if similar

    % 2. Cohen's d (Effect Size) to measure the difference between means
    meanFly1 = mean(fly1LastThreePulseData);
    meanFly2 = mean(fly2LastThreePulseData);
    stdFly1 = std(fly1LastThreePulseData);
    stdFly2 = std(fly2LastThreePulseData);

    pooledStd = sqrt((stdFly1^2 + stdFly2^2) / 2);
    cohensD = abs(meanFly1 - meanFly2) / pooledStd;  % Effect size (larger d means stronger difference)

    % 3. Percentile shift comparison (e.g., using the median)
    medianFly1 = median(fly1LastThreePulseData);
    meanFly2 = median(fly2LastThreePulseData);

    % Now store the facing angles for each category based on the existing classification
    if strcmp(dominanceVector_FA(i), 'Dominant') && strcmp(dominanceVector_FA(i+1), 'Submissive')
        % Fly 1 is dominant, Fly 2 is submissive
        dominantFacingAngles = [dominantFacingAngles, fly1LastThreePulseData];
        submissiveFacingAngles = [submissiveFacingAngles, fly2LastThreePulseData];
    elseif strcmp(dominanceVector_FA(i), 'Submissive') && strcmp(dominanceVector_FA(i+1), 'Dominant')
        % Fly 2 is dominant, Fly 1 is submissive
        dominantFacingAngles = [dominantFacingAngles, fly2LastThreePulseData];
        submissiveFacingAngles = [submissiveFacingAngles, fly1LastThreePulseData];
    elseif strcmp(dominanceVector_FA(i), 'No Dominance')
        % Both flies are in the no dominance category
        noDominanceFacingAngles = [noDominanceFacingAngles, fly1LastThreePulseData, fly2LastThreePulseData];
    elseif strcmp(dominanceVector_FA(i), 'Unclear') 
        % Both flies are in the no dominance category
        unclearDominacneFacingAngles = [noDominanceFacingAngles, fly1LastThreePulseData, fly2LastThreePulseData];    

    end

    % Print statistics for each pair for potential use
    fprintf('Fly Pair %d-%d:\n', i, i + 1);
    fprintf('Kolmogorov-Smirnov Test: h = %d, p = %.3f\n', ksComparison, p);
    fprintf('Cohen''s d: %.3f\n', cohensD);
    fprintf('Median Shift: Fly %d = %.2f, Fly %d = %.2f\n\n', i, medianFly1, i + 1, meanFly2);
end

% Output summary statistics or store for later use
fprintf('Dominant Facing Angles: %d values collected.\n', length(dominantFacingAngles));
fprintf('Submissive Facing Angles: %d values collected.\n', length(submissiveFacingAngles));
fprintf('No Dominance Facing Angles: %d values collected.\n', length(noDominanceFacingAngles));



%% Plot and Save Facing Angles Distributions for Each Category -- Last Two Pulses

% Define categories and the corresponding data
categories = {'Dominant', 'Submissive', 'No Dominance'};
facingAnglesData = {dominantFacingAngles, submissiveFacingAngles, noDominanceFacingAngles};

% Initialize an array to store the figure handles
figureHandles = [];

% Loop through each category and generate the figures
for k = 1:length(categories)
    % Check if there is data to plot for the current category
    if ~isempty(facingAnglesData{k})
        % Plot the data
        plotFacingAngleDistribution(facingAnglesData{k}, categories{k});
        fig = gcf;  % Get the handle to the current figure
        figureHandles = [figureHandles, fig];  % Store the handle
    else
        warning('No data available for category: %s', categories{k});
    end
end

%% Automatically Save Figures Without Prompting User
% Set desired figure size [x, y, width, height]
desiredFigureSize = [1000, 917, 560, 420]; % Adjust the values as needed

% Create folders for saving the figures if they don't exist
matlabFigDir = 'MATLAB_Figures';
epsDir = 'EPS_Figures';

% Check if the folders exist, if not, create them
if ~exist(matlabFigDir, 'dir')
    mkdir(matlabFigDir);
end

if ~exist(epsDir, 'dir')
    mkdir(epsDir);
end

for i = 1:length(figureHandles)
    set(figureHandles(i), 'Position', desiredFigureSize);  % Resize the figure
    
    % Create file names for saving
    matlabFileName = fullfile(matlabFigDir, [categories{i}, '_FacingAngle.fig']);
    epsFileName = fullfile(epsDir, [categories{i}, '_FacingAngle.eps']);
    
    % Save the figure as MATLAB .fig format
    savefig(figureHandles(i), matlabFileName);
    
    % Adjust the PaperPosition to fit the content tightly
    set(figureHandles(i), 'PaperPositionMode', 'auto');
    set(figureHandles(i), 'PaperUnits', 'points');
    
    % Get the current figure's size to use for the PaperSize
    paperPosition = get(figureHandles(i), 'PaperPosition');
    set(figureHandles(i), 'PaperSize', [paperPosition(3), paperPosition(4)]); % Set the PaperSize to match content size
    
    % Export to EPS format using print for better control
    print(figureHandles(i), epsFileName, '-depsc', '-r300');  % Save as EPS
end

