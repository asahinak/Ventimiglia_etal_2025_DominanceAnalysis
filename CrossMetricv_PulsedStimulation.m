%% --- Cross-Metric Comparison (Facing Angles vs Lunge-Based Dominance) ---
% This compares facing angle and Lunge classifications and assigns an
% updated classification based on their integration.


% Initialize a variable to track mismatches between the two analyses
pairComparison = strings(numPairs, 1);  % Will store if the classifications agree or not

% Define the last two pulse windows
lastTwoPulses = [162000, 180000; 198000, 216000];

% Define bin edges to ensure consistent binning
binEdges = 0:0.1:pi;  % Same bin edges as in LungeAnalysis

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
        
        % Extract the facing angle data for the last two pulses (same as LungeAnalysis)
        fly1LastTwoPulseData = [];
        fly2LastTwoPulseData = [];
        
        % Combine the data from the last two pulses for each fly
        for j = 1:size(lastTwoPulses, 1)
            fly1LastTwoPulseData = [fly1LastTwoPulseData, FlyFeatures.FacingAngle(i, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
            fly2LastTwoPulseData = [fly2LastTwoPulseData, FlyFeatures.FacingAngle(i + 1, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
        end
        
        % Generate histograms for both flies with the same bin edges
        [fly1Freq, ~] = histcounts(fly1LastTwoPulseData, 'BinEdges', binEdges);
        [fly2Freq, ~] = histcounts(fly2LastTwoPulseData, 'BinEdges', binEdges);
        
        % Total lunges for each fly (use L_startsm)
        totalLunges1 = numel(flymatAll(i).L_startsm);
        totalLunges2 = numel(flymatAll(i + 1).L_startsm);
        
        % Count lunges for each pulse for both flies using L_startsm
        pulses = [18000, 36000;
                  54000, 72000;
                  90000, 108000;
                  126000, 144000;
                  162000, 180000;
                  198000, 216000];
        
      
        Fly1_Lunges = zeros(size(pulses, 1), 1);
        Fly2_Lunges = zeros(size(pulses, 1), 1);
        
        % Count lunges for each pulse for both flies using L_startsm
        for j = 1:size(pulses, 1)
            Fly1_Lunges(j) = sum(flymatAll(i).L_startsm >= pulses(j, 1) & flymatAll(i).L_startsm <= pulses(j, 2));
            Fly2_Lunges(j) = sum(flymatAll(i + 1).L_startsm >= pulses(j, 1) & flymatAll(i + 1).L_startsm <= pulses(j, 2));
        end

        % --- Create new figure for mismatch investigation ---
        figure;
        
        % Plot the histogram of the facing angles for the mismatched pair (Last two pulses data)
        subplot(3, 1, 1);  % Top subplot for facing angle histogram
        hold on;
        % Histogram for Fly 1
        histogram(fly1LastTwoPulseData, 'BinEdges', binEdges, 'FaceColor', 'b', 'FaceAlpha', 0.5);  
        % Histogram for Fly 2
        histogram(fly2LastTwoPulseData, 'BinEdges', binEdges, 'FaceColor', 'r', 'FaceAlpha', 0.5);  
        
        % Calculate and plot medians
        meanFly1 = mean(fly1LastTwoPulseData);
        meanFly2 = mean(fly2LastTwoPulseData);
        
        % Plot the mean lines
        plot([meanFly1, meanFly1], ylim, 'b--', 'LineWidth', 2);  % Median for Fly 1 (blue)
        plot([meanFly2, meanFly2], ylim, 'r--', 'LineWidth', 2);  % Median for Fly 2 (red)
        
        % Add labels, title, and legend
        title(sprintf('Facing Angle Distribution for Fly %d vs Fly %d (Mismatch - Last Two Pulses)', i, i + 1));
        xlabel('Facing Angle');
        ylabel('Frequency');
        legend(sprintf('Fly %d (Mean: %.2f)', i, meanFly1), sprintf('Fly %d (Mean: %.2f)', i + 1, meanFly2));
        hold off;
        
        % Plot the lunge raster for the mismatched pair
        subplot(3, 1, 2);  % Middle subplot for lunge raster
        rasterplotter_OH(flymatAll(i:i+1), 'lunge', '');  % Use the rasterplotter function
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
                            i, totalLunges1, i + 1, totalLunges2, ...
                            i, mat2str(Fly1_Lunges'), ...
                            i+1, mat2str(Fly2_Lunges'));

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
numPairs = numFlies / 2;  % Assuming numFlies is even, else round appropriately
PairClassification = strings(numPairs, 1);  % Preallocate for each pair

% Define last two pulse indices
lastTwoPulses = 5:6;

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

    % if FA calls No Dominance, but Lunges call dominance, check the number of lunges in the low lunger -- if < 10 total (last two stims) use FA call; otherwise use Lunge Call.     
    elseif strcmp(FA_Fly1, 'No Dominance') && ~strcmp(lunge_Fly1, 'Low Lunges')
        
        newDominanceClassification(i) = FA_Fly1;
        newDominanceClassification(i + 1) = FA_Fly2;
        PairClassification(pairIndex) = FA_Fly1;

        if strcmp(lunge_Fly1, 'Submissive')
            submissiveIndex = i;
        elseif strcmp(lunge_Fly2, 'Submissive')
            submissiveIndex = i + 1;
        else
            submissiveIndex = [];
        end

        if ~isempty(submissiveIndex)
            submissiveLunges = sum(LungeAnalysis(submissiveIndex).LungesPerPulse(lastTwoPulses));

            if submissiveLunges < 10
                newDominanceClassification(i) = FA_Fly1;
                newDominanceClassification(i + 1) = FA_Fly2;
            else
                newDominanceClassification(i) = lunge_Fly1;
                newDominanceClassification(i + 1) = lunge_Fly2;
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
disp('New Dominance Classification based on Total Lunges After 162000 or Facing Angle:');
disp(newDominanceClassification);


%% Check-out unclear pairs 

% Define last two pulse frames
lastTwoPulses = [162000, 180000; 198000, 216000];

% Loop through each pair to find and plot "Unclear" classifications
for i = 1:2:numFlies
    pairIndex = (i + 1) / 2;

    % Check if the pair is classified as "Unclear"
    if strcmp(PairClassification(pairIndex), 'Unclear')
        
        % Extract facing angle and lunge data for the last two pulses for both flies
        fly1FacingAngleLastTwoPulses = [];
        fly2FacingAngleLastTwoPulses = [];
        fly1LungesLastTwoPulses = [];
        fly2LungesLastTwoPulses = [];

        % Combine data from the last two pulses
        for j = 1:size(lastTwoPulses, 1)
            fly1FacingAngleLastTwoPulses = [fly1FacingAngleLastTwoPulses, FlyFeatures.FacingAngle(i, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
            fly2FacingAngleLastTwoPulses = [fly2FacingAngleLastTwoPulses, FlyFeatures.FacingAngle(i + 1, lastTwoPulses(j, 1):lastTwoPulses(j, 2))];
            fly1LungesLastTwoPulses = [fly1LungesLastTwoPulses, flymatAll(i).L_startsm(flymatAll(i).L_startsm >= lastTwoPulses(j, 1) & flymatAll(i).L_startsm <= lastTwoPulses(j, 2))];
            fly2LungesLastTwoPulses = [fly2LungesLastTwoPulses, flymatAll(i + 1).L_startsm(flymatAll(i + 1).L_startsm >= lastTwoPulses(j, 1) & flymatAll(i + 1).L_startsm <= lastTwoPulses(j, 2))];
        end

        % Calculate medians for facing angles
        meanFly1FacingAngle = mean(fly1FacingAngleLastTwoPulses);
        meanFly2FacingAngle = mean(fly2FacingAngleLastTwoPulses);

        % Calculate Cohen's d and percent difference in lunges if needed
        pooledStd = sqrt((std(fly1FacingAngleLastTwoPulses)^2 + std(fly2FacingAngleLastTwoPulses)^2) / 2);
        cohensD = (meanFly1FacingAngle - meanFly2FacingAngle) / pooledStd;
        percentDifferenceLunges = (abs(numel(fly1LungesLastTwoPulses) - numel(fly2LungesLastTwoPulses)) / ...
                                  ((numel(fly1LungesLastTwoPulses) + numel(fly2LungesLastTwoPulses)) / 2)) * 100;

        % Create figure for the "Unclear" classification
        figure;

        % Subplot 1: Histogram of Facing Angles for Fly 1 and Fly 2
        subplot(2, 1, 1);  % Top subplot for facing angle histogram
        hold on;

        % Histogram for Fly 1
        histogram(fly1FacingAngleLastTwoPulses, 'BinEdges', 0:0.1:pi, 'FaceColor', 'b', 'FaceAlpha', 0.5);
        % Histogram for Fly 2
        histogram(fly2FacingAngleLastTwoPulses, 'BinEdges', 0:0.1:pi, 'FaceColor', 'r', 'FaceAlpha', 0.5);

        % Plot mean lines for facing angles
        plot([meanFly1FacingAngle, meanFly1FacingAngle], ylim, 'b--', 'LineWidth', 2);  % Median for Fly 1
        plot([meanFly2FacingAngle, meanFly2FacingAngle], ylim, 'r--', 'LineWidth', 2);  % Median for Fly 2

        % Add labels, title, and legend
        title(sprintf('Facing Angle Distribution for Fly %d vs Fly %d (Last Two Pulses)', i, i + 1));
        xlabel('Facing Angle');
        ylabel('Frequency');
        legend(sprintf('Fly %d (Mean: %.2f)', i, meanFly1FacingAngle), ...
               sprintf('Fly %d (Mean: %.2f)', i + 1, meanFly2FacingAngle));
        hold off;

        % Subplot 2: Raster plot showing lunges for both flies in the last two pulses
        subplot(2, 1, 2);  % Bottom subplot for lunge raster
        rasterplotter_OH(flymatAll(i:i+1), 'lunge', '');  % Plot lunges for both flies in the relevant window
        title(sprintf('Lunge Raster for Fly %d vs Fly %d (Last Two Pulses)', i, i + 1));

        % Add text box with additional information
        infoText = sprintf(['Cohen''s d: %.2f\nPercent Difference in Lunges: %.2f%%\n', ...
                            'Fly %d Lunges (Last Two Pulses): %d\nFly %d Lunges (Last Two Pulses): %d'], ...
                            cohensD, percentDifferenceLunges, ...
                            i, numel(fly1LungesLastTwoPulses), i + 1, numel(fly2LungesLastTwoPulses));

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
    % Final classification from Cross Metric analysis
    flymatAll_Final(i).FinalDominanceClassification = newDominanceClassification(i);
    
    % Dominance classification from FacingAngleDA classification
    flymatAll_Final(i).FacingAngleDominance = dominanceVector_FA(i);
    
    % Dominance classification from LungingDA classification
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