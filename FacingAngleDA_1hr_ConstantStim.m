% Dominance classification based on Facing Angle data
% Donovan Ventimiglia. October 8th, 2025

% 1-hour constant-stimulation protocol (75-min recording;
% stimulation from recording minute 5 to minute 65).

% Note:
% FeatureCollection should have been run before this script.
% Load FlyFeatures and flymatAll before running. 


% Initialize dominance vectors for Facing Angle and Lunge data
numFlies = size(FlyFeatures.FacingAngle, 1);
dominanceVector_FA = strings(numFlies, 1); % For Facing Angle
dominanceByLunges = strings(numFlies, 1); % For Lunges
dominantFlies = [];  % Indices of dominant flies
submissiveFlies = [];  % Indices of submissive flies
unclearFlies = [];  % Indices of unclear flies
similarFlies = [];  % Indices of similar flies
shiftCutoff = 1.5;  % Cutoff for left or right shift

% Initialize shift direction for each
facingAngleShift = strings(numFlies, 2); % overall and last window

% Define parameters for each figure layout
plotsPerRow = 3;  % Three histograms per row
rowsPerFigure = 2;  % Two rows: one for histograms, one for raster plot
figureCounter = 1;  % Figure number counter
binEdges = 0:0.1:pi;  % Bin edges for histogram

% Define analysis periods (60 fps; recording is 75 min)
First_5min = [1, 18000];          % Prestimulation period: recording minutes 0–5
TP_30min = [108000, 144000];     % Recording minutes 30–40
DomPeriod = [198000, 234000];    % Final 10 min of stimulation: recording minutes 55–65

%% --- Prompt user to save figures or not ---
saveFigures = questdlg('Would you like to save the figures?', ...
    'Save Figures', ...
    'Yes', 'No', 'No');  % Default is 'No'

% Only proceed with folder creation if user says 'Yes'
if strcmp(saveFigures, 'Yes')
    % Create folders for saving the figures if they don't exist
    matlabFigDir = 'MATLAB_Figures';
    epsDir = 'EPS_Figures';

    if ~exist(matlabFigDir, 'dir')
        mkdir(matlabFigDir);
    end

    if ~exist(epsDir, 'dir')
        mkdir(epsDir);
    end
end

% --- Main loop for pairs of flies (1&2, 3&4, etc.) ---
% figureCounter is not strictly necessary anymore if we handle everything in this loop,
% but you can keep it if you want a consecutive numbering in the filename.
figureCounter = 1;  
for i = 1:2:numFlies
    
    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end
    
    % Extract data for the two flies in the pair
    fly1 = FlyFeatures.FacingAngle(i, :);
    fly2 = FlyFeatures.FacingAngle(i + 1, :);

    % --- Create a new figure for the current pair of flies ---
    figHandle = figure('Name', sprintf('Fly Pair %d & %d', i, i+1), ...
                       'NumberTitle', 'off');

    % --- Prestimulation Period Analysis ---
    fly1PrestimData = fly1(First_5min(1):First_5min(2));
    fly2PrestimData = fly2(First_5min(1):First_5min(2));
    meanFly1Prestim = mean(fly1PrestimData);
    meanFly2Prestim = mean(fly2PrestimData);

    subplot(rowsPerFigure, plotsPerRow, 1);
    hold on;
    histogram(fly1PrestimData, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(fly2PrestimData, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    plot([meanFly1Prestim meanFly1Prestim], ylim, 'b--', 'LineWidth', 2);
    plot([meanFly2Prestim meanFly2Prestim], ylim, 'r--', 'LineWidth', 2);
    title(sprintf('Fly %d vs Fly %d (Prestimulation)', i, i+1));
    xlabel('Facing Angle Values');
    ylabel('Frequency');
    legend(sprintf('Fly %d (Mean: %.2f)', i, meanFly1Prestim), ...
           sprintf('Fly %d (Mean: %.2f)', i+1, meanFly2Prestim));
    hold off;

    % --- First region Analysis ---
    fly1FirstWindow = fly1(TP_30min(1):TP_30min(2));
    fly2FirstWindow = fly2(TP_30min(1):TP_30min(2));
    meanFly1FirstWindow = mean(fly1FirstWindow);
    meanFly2FirstWindow = mean(fly2FirstWindow);

    subplot(rowsPerFigure, plotsPerRow, 2);
    hold on;
    histogram(fly1FirstWindow, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(fly2FirstWindow, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    plot([meanFly1FirstWindow meanFly1FirstWindow], ylim, 'b--', 'LineWidth', 2);
    plot([meanFly2FirstWindow meanFly2FirstWindow], ylim, 'r--', 'LineWidth', 2);
    title(sprintf('Fly %d vs Fly %d (1st Window)', i, i+1));
    xlabel('Facing Angle Values');
    ylabel('Frequency');
    legend(sprintf('Fly %d (Mean: %.2f)', i, meanFly1FirstWindow), ...
           sprintf('Fly %d (Mean: %.2f)', i+1, meanFly2FirstWindow));
    hold off;

    % --- Classification window Analysis ---
    fly1DomWindow = [];
    fly2DomWinow = [];
    for j = 1:size(DomPeriod, 1)
        fly1DomWindow = [fly1DomWindow, fly1(DomPeriod(j, 1):DomPeriod(j, 2))];
        fly2DomWinow = [fly2DomWinow, fly2(DomPeriod(j, 1):DomPeriod(j, 2))];
    end
    meanFly1_DomWindow = mean(fly1DomWindow);
    meanFly2_DomWindow = mean(fly2DomWinow);

    subplot(rowsPerFigure, plotsPerRow, 3);
    hold on;
    histogram(fly1DomWindow, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    histogram(fly2DomWinow, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
    plot([meanFly1_DomWindow meanFly1_DomWindow], ylim, 'b--', 'LineWidth', 2);
    plot([meanFly2_DomWindow meanFly2_DomWindow], ylim, 'r--', 'LineWidth', 2);
    title(sprintf('Fly %d vs Fly %d (Dom Window)', i, i+1));
    xlabel('Facing Angle Values');
    ylabel('Frequency');
    legend(sprintf('Fly %d (Mean: %.2f)', i, meanFly1_DomWindow), ...
           sprintf('Fly %d (Mean: %.2f)', i+1, meanFly2_DomWindow));
    hold off;

    % --- Lunge Raster Plot (assuming full-width subplot) ---
    subplot(rowsPerFigure, 1, rowsPerFigure);
    rasterplotter(flymatAll(i:i+1), 'lunge', '');
    title(sprintf('Lunge Raster for Fly %d vs Fly %d', i, i+1));
    xlabel('Time (frames)');
    ylabel('Lunge Events');

    % --- If the user chose to save figures, do so for this figure ---
    if strcmp(saveFigures, 'Yes')
        % You can customize the file naming scheme however you want
        baseFileName = sprintf('FlyPair_%d_%d_Fig%d', i, i+1, figureCounter);

        matlabFileName = fullfile(matlabFigDir, [baseFileName '.fig']);
        epsFileName    = fullfile(epsDir,    [baseFileName '.eps']);

        % Save as MATLAB figure
        savefig(figHandle, matlabFileName);

        % Adjust figure so EPS export is properly sized
        set(figHandle, 'PaperPositionMode', 'auto');
        set(figHandle, 'PaperUnits', 'points');
        paperPosition = get(figHandle, 'PaperPosition');
        set(figHandle, 'PaperSize', [paperPosition(3), paperPosition(4)]);

        % Export to EPS using exportgraphics (vector format)
        exportgraphics(figHandle, epsFileName, 'ContentType', 'vector');
    end

    % --- Close this figure to free memory ---
    close(figHandle);
    
    % Increment the counter if you want consistent numbering
    figureCounter = figureCounter + 1;
end

% --- End of code ---


%% --- Facing Angle-Based Dominance Classification ---
% This section classifies dominance based on the distribution of facing angles during the classification
% window. It analyzes each fly's behavior to determine if it was primarily facing, fleeing, 
% or uncertain during this period.

% Define the facing and fleeing ranges used for classification.
% The center range is shown for reference but is not used by the classifier.

facingRange = [0, 0.75];     % Fly is facing opponent
fleeingRange = [2.4, 3.15];  % Fly is fleeing opponent
centerRange = [1.2, 1.8];    % Center region for unclear behavior

% Define the 15% threshold comparing facing- and fleeing-range histogram sums
thresholdFactor = 0.15;
meanThreshold = 1.5; % Adjust as needed for mean threshold


% Loop through pairs of flies (1&2, 3&4, etc.)
for i = 1:2:numFlies
    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end
    
    % Extract the data from dominance test window for both flies in the pair
    fly1DomWindow = [];
    fly2DomWinow = [];
    
    % Combine the data
    for j = 1:size(DomPeriod, 1)
        fly1DomWindow = [fly1DomWindow, FlyFeatures.FacingAngle(i, DomPeriod(j, 1):DomPeriod(j, 2))];
        fly2DomWinow = [fly2DomWinow, FlyFeatures.FacingAngle(i + 1, DomPeriod(j, 1):DomPeriod(j, 2))];
    end
    
    % Generate histograms and get the frequencies in each bin
    [fly1Freq, binEdges] = histcounts(fly1DomWindow, 'BinEdges', 0:0.1:pi);
    [fly2Freq, ~] = histcounts(fly2DomWinow, 'BinEdges', 0:0.1:pi);
    
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
    meanFly1 = mean(fly1DomWindow);
    meanFly2 = mean(fly2DomWinow);

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
    % histogram(fly1_DomWindow, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);
    % histogram(fly2_DomWindow, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);
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


%% --- Facing Angle Distribution Analysis ---
% This section compares the facing angle distributions for pairs of flies
% during the classification window. Three statistical methods are used for analysis:
%
% 1. **Kolmogorov-Smirnov (K-S) Test**: Tests if the facing angle distributions for the two flies 
%    are significantly different. A result of h = 1 indicates a difference, while h = 0 means 
%    the distributions are similar.
%
% 2. **Cohen's d (Effect Size)**: Measures the magnitude of the difference between the two flies'
%    mean facing angles. A larger Cohen's d value suggests a stronger difference.
%
% 3. **Median Comparison**: Compares the medians of the facing angle distributions to 
%    assess directional dominance or submission.
%
% Based on the `dominanceVector_FA` classification, the facing angles for each category 
% (Dominant, Submissive, No Dominance, and Unclear) are stored in separate arrays for further analysis. 
% For each pair, the results of the K-S test, Cohen's d, and the median shift are printed for 
% potential use or reference.


% Initialize variables to store facing angles for each category
dominantFacingAngles = [];
submissiveFacingAngles = [];
noDominanceFacingAngles = [];  
unclearDominanceFacingAngles= []; 

% Loop through pairs of flies (1&2, 3&4, etc.)
for i = 1:2:numFlies
    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end

    % Extract the data
    fly1_DomWindow = [];
    fly2_DomWindow = [];
    
    % Combine the data
    for j = 1:size(DomPeriod, 1)
        fly1_DomWindow = [fly1_DomWindow, FlyFeatures.FacingAngle(i, DomPeriod(j, 1):DomPeriod(j, 2))];
        fly2_DomWindow = [fly2_DomWindow, FlyFeatures.FacingAngle(i + 1, DomPeriod(j, 1):DomPeriod(j, 2))];
    end

    % 1. Kolmogorov-Smirnov (K-S) Test to compare distributions
    [h, p] = kstest2(fly1_DomWindow, fly2_DomWindow);  % h = 0 means same distribution, h = 1 means different distribution
    ksComparison = h;  % Result of K-S test: 1 if different, 0 if similar

    % 2. Cohen's d (Effect Size) to measure the difference between means
    meanFly1 = mean(fly1_DomWindow);
    meanFly2 = mean(fly2_DomWindow);
    stdFly1 = std(fly1_DomWindow);
    stdFly2 = std(fly2_DomWindow);

    pooledStd = sqrt((stdFly1^2 + stdFly2^2) / 2);
    cohensD = abs(meanFly1 - meanFly2) / pooledStd;  % Effect size (larger d means stronger difference)

    % 3. Percentile shift comparison (e.g., using the median)
    medianFly1 = median(fly1_DomWindow);
    medianFly2 = median(fly2_DomWindow);

    % Now store the facing angles for each category based on the existing classification
    if strcmp(dominanceVector_FA(i), 'Dominant') && strcmp(dominanceVector_FA(i+1), 'Submissive')
        % Fly 1 is dominant, Fly 2 is submissive
        dominantFacingAngles = [dominantFacingAngles, fly1_DomWindow];
        submissiveFacingAngles = [submissiveFacingAngles, fly2_DomWindow];
    elseif strcmp(dominanceVector_FA(i), 'Submissive') && strcmp(dominanceVector_FA(i+1), 'Dominant')
        % Fly 2 is dominant, Fly 1 is submissive
        dominantFacingAngles = [dominantFacingAngles, fly2_DomWindow];
        submissiveFacingAngles = [submissiveFacingAngles, fly1_DomWindow];
    elseif strcmp(dominanceVector_FA(i), 'No Dominance')
        % Both flies are in the no dominance category
        noDominanceFacingAngles = [noDominanceFacingAngles, fly1_DomWindow, fly2_DomWindow];
    elseif strcmp(dominanceVector_FA(i), 'Unclear') 
        % Store both flies' facing angles for the Unclear category.
        unclearDominanceFacingAngles = [unclearDominanceFacingAngles, fly1_DomWindow, fly2_DomWindow];    

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



%% Plot and Save Facing Angles Distributions for Each Category --

% Define categories and the corresponding data
categories = {'Dominant', 'Submissive', 'No Dominance', 'Unclear'};
facingAnglesData = {dominantFacingAngles, submissiveFacingAngles, ...
                    noDominanceFacingAngles, unclearDominanceFacingAngles};

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

