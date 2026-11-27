%% --- Cross-Metric Comparison (Facing Angles vs Lunge-Based Dominance) ---
% This compares facing angle and Lunge classifications and assigns an
% updated classification based on their integration.

% Mismatched classifications from facing-angle and lunging classifiers are
% plotted. These should be manually inspected for final dominance call. 

% Donovan Ventimiglia Oct 2026

% Initialize a variable to track mismatches between the two analyses
pairComparison = strings(numPairs, 1);  % Will store if the classifications agree or not

% Define dominance-analysis window.
timeWindow=[size(FlyFeatures.FacingAngle,2)-36000,size(FlyFeatures.FacingAngle,2)]; %last 10min of recording


% Define facing-angle bin edges
binEdges = 0:0.1:pi; 

% Loop through pairs of flies (1&2, 3&4, etc.)
for i = 1:2:numFlies
    pairIndex = LungeAnalysis(i).PairIndex;  % Get the pair index
    
    % Skip pairs flagged as "No Fighting"
    if strcmp(LungeAnalysis(i).PairClassification, 'No Fighting')
        fprintf('Skipping Fly Pair %d-%d (No Fighting)\n', i, i + 1);
        pairComparison(pairIndex) = 'Skipped (No Fighting)';
        continue;  % Skip this pair and move to the next one
    end
    
    % Extract the facing angle classifications for the two flies in the pair
    facingAngleClass1 = dominanceVector_FA(i);
    facingAngleClass2 = dominanceVector_FA(i + 1);
    
    % Extract the lunge-based dominance classification for the pair
    lungeClass = LungeAnalysis(i).PairClassification;
    
    % Decision based on facing angle analysis: If both flies are marked as submissive or dominant
    if strcmp(facingAngleClass1, 'Dominant') && strcmp(facingAngleClass2, 'Submissive') || ...
       strcmp(facingAngleClass1, 'Submissive') && strcmp(facingAngleClass2, 'Dominant')
        % This pair has a clear dominance relationship from facing angles
        pairFacingClass = 'Dominance Established';
    else
        % If the classifications are unclear, similar, or both flies are the same, classify as no clear dominance
        pairFacingClass = 'No Dominance';
    end
    
    % Compare the lunge-based classification (LungeAnalysis) with the facing angle-based pair classification
    if strcmp(lungeClass, pairFacingClass)
        pairComparison(pairIndex) = 'Match';
    else
        pairComparison(pairIndex) = 'Mismatch';
        
        % If there's a mismatch, investigate why by comparing the specific metrics for each fly
        fprintf('Mismatch for Fly Pair %d-%d\n', i, i + 1);
        
        % Extract the facing angle data for the dominance window
        fly1Last_10min = FlyFeatures.FacingAngle(i,timeWindow(1):timeWindow(2));
        fly2Last_10min = FlyFeatures.FacingAngle(i+1,timeWindow(1):timeWindow(2));
        
        % Generate histograms for both flies with the same bin edges
        [fly1Freq, ~] = histcounts(fly1Last_10min, 'BinEdges', binEdges);
        [fly2Freq, ~] = histcounts(fly2Last_10min, 'BinEdges', binEdges);
        
        % Total lunges for each fly (use L_startsm)
        totalLunges1 = numel(flymatAll(i).L_startsm);
        totalLunges2 = numel(flymatAll(i + 1).L_startsm);
        

        % --- Create new figure for mismatch investigation ---
        figure;

        % Plot the histogram of the facing angles for the mismatched pair (Last 10min data)
        subplot(3, 1, 1);  % Top subplot for facing angle histogram
        hold on;
        % Histogram for Fly 1
        histogram(fly1Last_10min, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);  
        % Histogram for Fly 2
        histogram(fly2Last_10min, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);  

        % Calculate and plot Mean
        meanFly1 = mean(fly1Last_10min);
        meanFly2 = mean(fly2Last_10min);

        % Plot the mean lines
        plot([meanFly1, meanFly1], ylim, 'b--', 'LineWidth', 2);  % Median for Fly 1 (blue)
        plot([meanFly2, meanFly2], ylim, 'r--', 'LineWidth', 2);  % Median for Fly 2 (red)

        % Add labels, title, and legend
        title(sprintf('Facing Angle Distribution for Fly %d vs Fly %d (Mismatch - DominanceWindow)', i, i + 1));
        xlabel('Facing Angle');
        ylabel('Frequency');
        legend(sprintf('Fly %d (Mean: %.2f)', i, meanFly1), sprintf('Fly %d (Mean: %.2f)', i + 1, meanFly2));
        hold off;

        % Plot the lunge raster for the mismatched pair
        subplot(3, 1, 2);  % Middle subplot for lunge raster
        rasterplotter(flymatAll(i:i+1), 'lunge', '');  % Use the rasterplotter function
        title(sprintf('Lunge Raster for Fly %d vs Fly %d (Mismatch)', i, i + 1));

        % Add the text with details below the raster plot
        subplot(3, 1, 3);  % Bottom subplot for information
        axis off;  % Turn off axis

        % Create the text content for display
        infoText = sprintf(['Facing Angle Classification: Fly %d: %s, Fly %d: %s\n', ...
                            'Mean Facing Angles: Fly %d: %.2f, Fly %d: %.2f\n', ...
                            'Lunge-Based Dominance: %s\n', ...
                            'Total Lunges: Fly %d: %d, Fly %d: %d\n', ...
                            'Fly 1 (Fly %d) Lunges Per Pulse: %s\n', ...
                            'Fly 2 (Fly %d) Lunges Per Pulse: %s'], ...
                            i, facingAngleClass1, i + 1, facingAngleClass2, ...
                            i, meanFly1, i + 1, meanFly2, ...
                            lungeClass, ...
                            i, totalLunges1, i + 1, totalLunges2);

        % Display the text information in the figure
        text(0.5, 0.5, infoText, 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 10);

    end
end

% Output the comparison result
disp('Cross-Metric Comparison (Lunges vs Facing Angle) for each pair:');
disp(pairComparison);

%% --- New Dominance Classification Based on Lunges and facing angle intersection. 

% Initialize a variable for the new dominance classification for each fly
newDominanceClassification = strings(numFlies, 1);  % New classification for each fly

% Initialize PairClassification as a string array with size numPairs
numPairs = numFlies / 2;  % Number of pairs
PairClassification = strings(numPairs, 1);  % Preallocate for each pair


% Loop through pairs of flies (1&2, 3&4, etc.)
for i = 1:2:numFlies
    pairIndex = (i + 1) / 2;  % Calculate the index for the pair

    % Skip pairs flagged as "No Fighting"
    if strcmp(LungeAnalysis(i).DominanceClassification, 'No Fighting') && strcmp(LungeAnalysis(i + 1).DominanceClassification, 'No Fighting')
        newDominanceClassification(i) = 'No Fighting';
        newDominanceClassification(i + 1) = 'No Fighting';
        PairClassification(pairIndex) = 'No Fighting';
        continue;  % Skip this pair and move to the next one
    end

    % Retrieve classifications for each fly
    lunge_Fly1 = LungeAnalysis(i).DominanceClassification;
    lunge_Fly2 = LungeAnalysis(i + 1).DominanceClassification;
    FA_Fly1 = dominanceVector_FA(i);
    FA_Fly2 = dominanceVector_FA(i + 1);

    % Skip if classifications match
    if strcmp(lunge_Fly1, FA_Fly1) && strcmp(lunge_Fly2, FA_Fly2)
        newDominanceClassification(i) = lunge_Fly1;
        newDominanceClassification(i + 1) = lunge_Fly2;
        PairClassification(pairIndex) = lunge_Fly1;
        continue;  % Move to the next pair
    end

    % Determine the new individual classifications for Fly 1

    % If lunges are low and facing angles unclear, call unclear
    if strcmp(lunge_Fly1, 'Low Lunges') && strcmp(FA_Fly1, 'Unclear')
        newDominanceClassification(i) = 'Unclear';
        newDominanceClassification(i + 1) = 'Unclear';
        PairClassification(pairIndex) = 'Unclear';
    % if Lunges are low, and FA is clear, use FA dominance
    elseif strcmp(lunge_Fly1, 'Low Lunges') && ~strcmp(FA_Fly1, 'Unclear')
        newDominanceClassification(i) = FA_Fly1;
        newDominanceClassification(i + 1) = FA_Fly2;
        PairClassification(pairIndex) = FA_Fly1;

    %  if FA is unclear, but lunges are, use lunges
    elseif strcmp(FA_Fly1, 'Unclear') && ~strcmp(lunge_Fly1, 'Low Lunges')
        newDominanceClassification(i) = lunge_Fly1;
        newDominanceClassification(i + 1) = lunge_Fly2;
        PairClassification(pairIndex) = lunge_Fly1;

    % if FA calls No Dominance, but Lunges call dominance, check the number of lunges in the high lunger. If > 10 (last 10 min) use lunge call, otherwise use FA Call.     
        elseif strcmp(FA_Fly1, 'No Dominance') && ~strcmp(lunge_Fly1, 'Low Lunges')

        % Default to FA call
        newDominanceClassification(i) = FA_Fly1;
        newDominanceClassification(i + 1) = FA_Fly2;
        PairClassification(pairIndex) = FA_Fly1;

        % Identify high lunger / lunge-classified dominant fly
        if strcmp(lunge_Fly1, 'Dominant')
            highLungerIndex = i;
        elseif strcmp(lunge_Fly2, 'Dominant')
            highLungerIndex = i + 1;
        else
            highLungerIndex = [];
        end

        % Check high-lunger activity
        if ~isempty(highLungerIndex)

            highLungerLunges = sum(LungeAnalysis(highLungerIndex).timeWindow);

            if highLungerLunges < 10
                % Too few lunges: use Facing Angle call
                newDominanceClassification(i) = FA_Fly1;
                newDominanceClassification(i + 1) = FA_Fly2;
                PairClassification(pairIndex) = FA_Fly1;

            else
                % Sufficient lunging: retain Lunge call
                newDominanceClassification(i) = lunge_Fly1;
                newDominanceClassification(i + 1) = lunge_Fly2;
                PairClassification(pairIndex) = lunge_Fly1;
            end
        end

    else
        % Fallback to lunge-based classification if no other conditions are met
        newDominanceClassification(i) = lunge_Fly1;
        newDominanceClassification(i + 1) = lunge_Fly2;
        PairClassification(pairIndex) = lunge_Fly1;
    end
  end


% Output the new dominance classification for each fly
disp('Final Dominance Classification from Lunge and Facing-Angle Integration:');
disp(newDominanceClassification);


%% Check-out unclear pairs 


% Loop through each pair to find and plot "Unclear" classifications
for i = 1:2:numFlies
    pairIndex = (i + 1) / 2;

    % Check if the pair is classified as "Unclear"
    if strcmp(PairClassification(pairIndex), 'Unclear')
        
        % Initialize variables
        fly1FacingAngletimeWindow = [];
        fly2FacingAngletimeWindow = [];
        fly1LungestimeWindow = [];
        fly2LungestimeWindow = [];

        % Extract facing angle and lunge data 
        for j = 1:size(timeWindow, 1)
            fly1FacingAngletimeWindow = [fly1FacingAngletimeWindow, FlyFeatures.FacingAngle(i, timeWindow(j, 1):timeWindow(j, 2))];
            fly2FacingAngletimeWindow = [fly2FacingAngletimeWindow, FlyFeatures.FacingAngle(i + 1, timeWindow(j, 1):timeWindow(j, 2))];
            fly1LungestimeWindow = [fly1LungestimeWindow, flymatAll(i).L_startsm(flymatAll(i).L_startsm >= timeWindow(j, 1) & flymatAll(i).L_startsm <= timeWindow(j, 2))];
            fly2LungestimeWindow = [fly2LungestimeWindow, flymatAll(i + 1).L_startsm(flymatAll(i + 1).L_startsm >= timeWindow(j, 1) & flymatAll(i + 1).L_startsm <= timeWindow(j, 2))];
        end

        % Calculate Mean for facing angles
        meanFly1FacingAngle = mean(fly1FacingAngletimeWindow);
        meanFly2FacingAngle = mean(fly2FacingAngletimeWindow);

        % Calculate Cohen's d and percent difference in lunges if needed
        pooledStd = sqrt((std(fly1FacingAngletimeWindow)^2 + std(fly2FacingAngletimeWindow)^2) / 2);
        cohensD = (meanFly1FacingAngle - meanFly2FacingAngle) / pooledStd;
        percentDifferenceLunges = (abs(numel(fly1LungestimeWindow) - numel(fly2LungestimeWindow)) / ...
                                  ((numel(fly1LungestimeWindow) + numel(fly2LungestimeWindow)) / 2)) * 100;

        % Create figure for the "Unclear" classification
        figure;

        % Subplot 1: Histogram of Facing Angles for Fly 1 and Fly 2
        subplot(2, 1, 1);  % Top subplot for facing angle histogram
        hold on;

        % Histogram for Fly 1
        histogram(fly1FacingAngletimeWindow, 'BinEdges', 0:0.1:pi, 'FaceColor', 'b', 'FaceAlpha', 0.5);
        % Histogram for Fly 2
        histogram(fly2FacingAngletimeWindow, 'BinEdges', 0:0.1:pi, 'FaceColor', 'r', 'FaceAlpha', 0.5);

        % Plot mean lines for facing angles
        plot([meanFly1FacingAngle, meanFly1FacingAngle], ylim, 'b--', 'LineWidth', 2);  % Median for Fly 1
        plot([meanFly2FacingAngle, meanFly2FacingAngle], ylim, 'r--', 'LineWidth', 2);  % Median for Fly 2

        % Add labels, title, and legend
        title(sprintf('Facing Angle Distribution for Fly %d vs Fly %d (dominanceWindow)', i, i + 1));
        xlabel('Facing Angle');
        ylabel('Frequency');
        legend(sprintf('Fly %d (Mean: %.2f)', i, meanFly1FacingAngle), ...
               sprintf('Fly %d (Mean: %.2f)', i + 1, meanFly2FacingAngle));
        hold off;

        % Subplot 2: Raster plot showing lunges for both flies in the dominance Window
        subplot(2, 1, 2);  % Bottom subplot for lunge raster
        rasterplotter(flymatAll(i:i+1), 'lunge', '');  % Plot lunges for both flies in the relevant window
        title(sprintf('Lunge Raster for Fly %d vs Fly %d (dominance Window)', i, i + 1));

        % Add text box with additional information
        infoText = sprintf(['Cohen''s d: %.2f\nPercent Difference in Lunges: %.2f%%\n', ...
                            'Fly %d Lunges (dominance Window): %d\nFly %d Lunges (dominance Window): %d'], ...
                            cohensD, percentDifferenceLunges, ...
                            i, numel(fly1LungestimeWindow), i + 1, numel(fly2LungestimeWindow));

        annotation('textbox', [0.15, 0.02, 0.7, 0.1], 'String', infoText, ...
                   'FitBoxToText', 'on', 'EdgeColor', 'none', 'FontSize', 10);
    end
end


%% --- Creating flymatAll_Final with all the relevant information ---
% This section creates a copy of flymatAll and adds information from FacingAngle classification,
% Lunging classification, and Cross-Metric analysis, along with all fields from FlyFeatures.

% Initialize the new structure flymatAll_Final as a copy of flymatAll
flymatAll_Final = flymatAll;  % Start by copying the existing flymatAll structure

% Get the field names of FlyFeatures
flyFeatureFields = fieldnames(FlyFeatures);

% Loop through each fly and add FlyFeatures data into flymatAll_Final
for i = 1:numFlies
    % For each field in FlyFeatures, assign to the corresponding fly
    for f = 1:length(flyFeatureFields)
        fieldName = flyFeatureFields{f};  % Get the current field name
        flymatAll_Final(i).(fieldName) = FlyFeatures.(fieldName)(i, :);  % Assign FlyFeatures field for this fly
    end
end

% Loop through each fly to add dominance classification
for i = 1:numFlies
    % --- Adding Dominance Classifications ---
    % Final classification from Cross Metric analysis (for each fly)
    flymatAll_Final(i).FinalDominanceClassification = newDominanceClassification(i);
    
    % Dominance classification from FacingAngle classification
    flymatAll_Final(i).FacingAngleDominance = dominanceVector_FA(i);
    
    % Dominance classification from Lunging classification
    flymatAll_Final(i).LungingDominance = LungeAnalysis(i).DominanceClassification;
end


%% --- Creating FlymatAll_Final_Cleaned by Removing "Unclear" and "No Fighting" Classifications ---
% note the fly number (row number) will now be different from FlymatAll_Final
% Initialize FlymatAll_Final_Cleaned 
flymatAll_Final_Cleaned = [];
numFlies=size(flymatAll_Final,2);
% Loop through each fly and copy over only those with a clear classification (no "Unclear" or "No Fighting")
for i = 1:numFlies
    if ~strcmp(flymatAll_Final(i).FinalDominanceClassification, 'Unclear') && ...
       ~strcmp(flymatAll_Final(i).FinalDominanceClassification, 'No Fighting')
        flymatAll_Final_Cleaned = [flymatAll_Final_Cleaned, flymatAll_Final(i)];
    end
end


%% --- Clear all variables except flymatAll_Final and flymatAll_Final_Cleaned ---

% Clear all variables except flymatAll_Final and flymatAll_Final_Cleaned
clearvars('-except', 'flymatAll_Final', 'flymatAll_Final_Cleaned');

%% --- Save the variables using MATLAB's save dialog ---

% Open a dialog box for the user to specify where to save the file
[filename, pathname] = uiputfile('*.mat', 'Save flymatAll_Final and flymatAll_Final_Cleaned As');

% Check if the user pressed cancel
if isequal(filename, 0) || isequal(pathname, 0)
    disp('User canceled save operation.');
else
    % Save the variables to the selected file
    save(fullfile(pathname, filename), 'flymatAll_Final', 'flymatAll_Final_Cleaned');
    fprintf('Saved flymatAll_Final and flymatAll_Final_Cleaned to %s\n', fullfile(pathname, filename));
end