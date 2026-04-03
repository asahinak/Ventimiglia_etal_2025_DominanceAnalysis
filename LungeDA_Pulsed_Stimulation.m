%% --- Temporal Analysis of Dominance Based on Lunges with Pair Index ---
% This section performs a pairwise temporal analysis of dominance based on lunging behavior.
% It identifies the fly in each pair with the fewer lunges (low_lunger) and sums the number 
% of lunges during specific time windows (stimulation periods).
%
% Classification criteria:
% 1. The low-lunger must have lunged fewer than 5 times in either of the last two pulses.
% 2. The high-lunger (the other fly) must have lunged at least 1.5 times the number of lunges 
%    done by the low-lunger across the last two pulses.
%
% If both conditions are met, the pair is classified as "Dominance Established."
% If these conditions are not met, the pair is classified as "No Dominance."

% FlymatAll and FlyFeatures should already be in the workspace

% Ensure the number of flies is determined from the flymatAll structure
numFlies = length(flymatAll); % Assuming each element corresponds to one fly

% Define the time windows (pulse periods) of interest, specifying start and end times
pulses = [18000, 36000;
          54000, 72000;
          90000, 108000;
          126000, 144000;
          162000, 180000;
          198000, 216000];

% Calculate the number of fly pairs
numPairs = numFlies / 2; 

% Initialize structure to store lunge data and dominance classification for each fly
LungeAnalysis = struct;

% Loop through each pair of flies and analyze lunging behavior
pairIndex = 1;
for i = 1:2:numFlies
    if i + 1 > numFlies
        break; % Skip unpaired fly if odd number of flies
    end
    
    % Define the start of the time window for lunges after time 162000
    timeThreshold = 162000;

    % Determine which fly in the pair lunged fewer times (low_lunger) after time 162000
    fly1_L_startsm_afterThreshold = flymatAll(i).L_startsm(flymatAll(i).L_startsm >= timeThreshold);    % Lunge start times for fly1 after 162000
    fly2_L_startsm_afterThreshold = flymatAll(i + 1).L_startsm(flymatAll(i + 1).L_startsm >= timeThreshold);  % Lunge start times for fly2 after 162000

    % Calculate the total lunges for each fly after 162000 (using L_startsm)
    fly1TotalLungesAfterThreshold = numel(fly1_L_startsm_afterThreshold);
    fly2TotalLungesAfterThreshold = numel(fly2_L_startsm_afterThreshold);

    % Determine which fly lunged fewer times after 162000
    if fly1TotalLungesAfterThreshold < fly2TotalLungesAfterThreshold
        lowLungerIndex = i;    % Index of low lunger in flymatAll
        highLungerIndex = i+1; % Index of high lunger in flymatAll
        lowLungerL_startsm = flymatAll(i).L_startsm;  % Store lunge start times for low lunger (fly 1)
    else
        lowLungerIndex = i+1;  % Index of low lunger in flymatAll
        highLungerIndex = i;   % Index of high lunger in flymatAll
        lowLungerL_startsm = flymatAll(i + 1).L_startsm;  % Store lunge start times for low lunger (fly 2)
    end
    
    % Store the fly indices and pair index for both flies
    LungeAnalysis(lowLungerIndex).LowLunger = true;
    LungeAnalysis(lowLungerIndex).HighLunger = false;
    LungeAnalysis(lowLungerIndex).PairIndex = pairIndex; % Store the pair index for this fly
    
    LungeAnalysis(highLungerIndex).LowLunger = false;
    LungeAnalysis(highLungerIndex).HighLunger = true;
    LungeAnalysis(highLungerIndex).PairIndex = pairIndex; % Store the pair index for this fly

    % Store the preallocated space for lunge counts for each fly
    LungeAnalysis(lowLungerIndex).LungesPerPulse = zeros(size(pulses, 1), 1); % Preallocate array
    LungeAnalysis(highLungerIndex).LungesPerPulse = zeros(size(pulses, 1), 1); % Preallocate array
    
    % Loop through each pulse window and count lunges for both flies
    for j = 1:size(pulses, 1)
        % Count lunges in the current pulse window for the low lunger
        lowLungeCount = sum(lowLungerL_startsm >= pulses(j, 1) & lowLungerL_startsm <= pulses(j, 2));
        LungeAnalysis(lowLungerIndex).LungesPerPulse(j) = lowLungeCount;
        
        % Count lunges in the current pulse window for the high lunger
        highLungeCount = sum(flymatAll(highLungerIndex).L_startsm >= pulses(j, 1) & flymatAll(highLungerIndex).L_startsm <= pulses(j, 2));
        LungeAnalysis(highLungerIndex).LungesPerPulse(j) = highLungeCount;
    end
    
    % Classify the pair based on lunge behavior in the last two pulses
    lowLungerLastTwoPulses = LungeAnalysis(lowLungerIndex).LungesPerPulse(end-1:end);  % Lunges in the last two pulses for low lunger
    highLungerLastTwoPulses = LungeAnalysis(highLungerIndex).LungesPerPulse(end-1:end);  % Lunges in the last two pulses for high lunger
    
    % Check if both flies didn't lunge in the last two pulses (flag as "No Fighting")
    if sum(lowLungerLastTwoPulses) == 0 && sum(highLungerLastTwoPulses) == 0
        LungeAnalysis(lowLungerIndex).DominanceClassification = 'No Fighting';
        LungeAnalysis(highLungerIndex).DominanceClassification = 'No Fighting';
        LungeAnalysis(lowLungerIndex).PairClassification = 'No Fighting';
        LungeAnalysis(highLungerIndex).PairClassification = 'No Fighting';
    
    % Mark as "Low Lunges" if lunge activity is very low for the high lunger
    elseif all(highLungerLastTwoPulses < 5)
        LungeAnalysis(lowLungerIndex).DominanceClassification = 'Low Lunges';
        LungeAnalysis(highLungerIndex).DominanceClassification = 'Low Lunges';
        LungeAnalysis(lowLungerIndex).PairClassification = 'Low Lunges';
        LungeAnalysis(highLungerIndex).PairClassification = 'Low Lunges';
    
    % Check for "Dominance Established"
    elseif all(lowLungerLastTwoPulses <= 5) && sum(highLungerLastTwoPulses) >= 1.5 * sum(lowLungerLastTwoPulses)
        LungeAnalysis(lowLungerIndex).DominanceClassification = 'Submissive';
        LungeAnalysis(highLungerIndex).DominanceClassification = 'Dominant';
        LungeAnalysis(lowLungerIndex).PairClassification = 'Dominance Established';
        LungeAnalysis(highLungerIndex).PairClassification = 'Dominance Established';
    
    % If none of the above conditions apply, classify as "No Dominance"
    else
        LungeAnalysis(lowLungerIndex).DominanceClassification = 'No Dominance';
        LungeAnalysis(highLungerIndex).DominanceClassification = 'No Dominance';
        LungeAnalysis(lowLungerIndex).PairClassification = 'No Dominance';
        LungeAnalysis(highLungerIndex).PairClassification = 'No Dominance';
    end

    % Print results for the pair
    fprintf('Fly Pair %d-%d: Fly %d (Low Lunger)\n', i, i + 1, lowLungerIndex);
    fprintf('Lunges in each window for low lunger: %s\n', mat2str(LungeAnalysis(lowLungerIndex).LungesPerPulse'));
    fprintf('Lunges in each window for high lunger: %s\n', mat2str(LungeAnalysis(highLungerIndex).LungesPerPulse'));
    fprintf('Dominance Classification for low lunger: %s\n', LungeAnalysis(lowLungerIndex).DominanceClassification);
    fprintf('Dominance Classification for high lunger: %s\n\n', LungeAnalysis(highLungerIndex).DominanceClassification);
    
    pairIndex = pairIndex + 1; % Move to next pair
end

% Count how many flies were classified as "No Dominance"
noDominanceCount = sum(strcmp({LungeAnalysis.DominanceClassification}, 'No Dominance'));
disp(['Number of flies with "No Dominance" classification: ', num2str(noDominanceCount)]);

%% --- Plot Lunge Rate Over Time for Submissive and Dominant Flies with SEM and Stimulation Periods ---

% Define the stimulation times (pulse windows) in frames and convert to minutes by dividing by 3600
pulses = [18000, 36000;
          54000, 72000;
          90000, 108000;
          126000, 144000;
          162000, 180000;
          198000, 216000] / 3600;  % Convert from frames to minutes

% Initialize cell arrays to store the lunge rate data for submissive, dominant, and no dominance flies
submissiveLungeRates = {};
dominantLungeRates = {};
noDominanceLungeRates = {};

% Loop through each fly to extract the lunge rates for submissive, dominant, and no dominance flies
for i = 1:numFlies
    % Exclude flies marked as "No Fighting"
    if strcmp(LungeAnalysis(i).DominanceClassification, 'No Fighting')
        continue;  % Skip this fly and move to the next one
    end

    % Use the classification from LungeAnalysis to store lunge rates
    if strcmp(LungeAnalysis(i).DominanceClassification, 'Dominant')
        dominantLungeRates{end+1} = flymatAll(i).L_binbouts;  % Dominant flies' lunge data
    elseif strcmp(LungeAnalysis(i).DominanceClassification, 'Submissive')
        submissiveLungeRates{end+1} = flymatAll(i).L_binbouts;  % Submissive flies' lunge data
    elseif strcmp(LungeAnalysis(i).DominanceClassification, 'No Dominance')
        noDominanceLungeRates{end+1} = flymatAll(i).L_binbouts;  % No Dominance flies' lunge data
    end
end

% --- Find the shortest length for each group and truncate ---
% Determine the shortest length for each category of flies

% Submissive flies
if ~isempty(submissiveLungeRates)
    minLength = min(cellfun(@(x) size(x, 2), submissiveLungeRates));
    for i = 1:length(submissiveLungeRates)
        submissiveLungeRates{i} = submissiveLungeRates{i}(:, 1:minLength);  % Truncate to the minimum length
    end
end

% Dominant flies
if ~isempty(dominantLungeRates)
    minLength = min(cellfun(@(x) size(x, 2), dominantLungeRates));
    for i = 1:length(dominantLungeRates)
        dominantLungeRates{i} = dominantLungeRates{i}(:, 1:minLength);  % Truncate to the minimum length
    end
end

% No Dominance flies
if ~isempty(noDominanceLungeRates)
    minLength = min(cellfun(@(x) size(x, 2), noDominanceLungeRates));
    for i = 1:length(noDominanceLungeRates)
        noDominanceLungeRates{i} = noDominanceLungeRates{i}(:, 1:minLength);  % Truncate to the minimum length
    end
end

% --- Plot for Dominant and Submissive Flies Together ---
if isempty(submissiveLungeRates) && isempty(dominantLungeRates)
    warning('No submissive or dominant flies found, skipping plot.');
else
    % Define the minimum number of time bins across groups
    numTimeBins = Inf;
    if ~isempty(submissiveLungeRates)
        numTimeBins = min(numTimeBins, size(submissiveLungeRates{1}, 2));
    end
    if ~isempty(dominantLungeRates)
        numTimeBins = min(numTimeBins, size(dominantLungeRates{1}, 2));
    end

    % Redefine the time vector based on the actual number of bins (already in minutes)
    timeVector = (1:numTimeBins);  % Adjust this based on your actual bin length to minutes if needed

    % Prepare cell arrays for group names and colors
    groupNames = {};
    colors = {};
    lungeRatesGroups = {};

    % Add Dominant group if it exists
    if ~isempty(dominantLungeRates)
        lungeRatesGroups{end+1} = dominantLungeRates;
        groupNames{end+1} = 'Dominant';
        colors{end+1} = 'k';  % Black color for Dominant
    end

    % Add Submissive group if it exists
    if ~isempty(submissiveLungeRates)
        lungeRatesGroups{end+1} = submissiveLungeRates;
        groupNames{end+1} = 'Submissive';
        colors{end+1} = 'r';  % Red color for Submissive
    end

    % Plot dominant and submissive flies together
    plotLungeRates(timeVector, lungeRatesGroups, pulses, groupNames, colors);
end

% --- Plot for No Dominance Flies Separately ---
if isempty(noDominanceLungeRates)
    warning('No "No Dominance" flies found, skipping plot.');
else
    % Define the minimum number of time bins for No Dominance flies
    numTimeBins = min(cellfun(@(x) size(x, 2), noDominanceLungeRates));

    % Redefine the time vector based on the actual number of bins
    timeVector = (1:numTimeBins);  % Adjust this based on your actual bin length to minutes if needed

    % Plot no dominance flies in a separate figure
    plotLungeRates(timeVector, {noDominanceLungeRates}, pulses, {'No Dominance'}, {'b'});
end



%% --- Dominance base on total lunges  ---
% Dominance based on overall lunges, not using pulses.

% Ensure the 'dominanceByLunges' vector is initialized as a string array
dominanceByLunges = strings(numFlies, 1);  % Initialize as an array of strings

for i = 1:2:numFlies
    if i + 1 > numFlies
        warning('Odd number of flies, skipping the last unpaired fly.');
        break;
    end
    
    % Extract lunge data for fly 1 and fly 2 in each pair
    fly1Lunges = flymatAll(i).L_bouts;      % Total lunge bouts for fly 1
    fly2Lunges = flymatAll(i+1).L_bouts;    % Total lunge bouts for fly 2
    
    % Compare the number of lunges and assign dominance
    if fly1Lunges > fly2Lunges
        dominanceByLunges(i) = 'Dominant';   % Fly 1 is dominant
        dominanceByLunges(i+1) = 'Submissive'; % Fly 2 is submissive
    elseif fly1Lunges < fly2Lunges
        dominanceByLunges(i) = 'Submissive';   % Fly 1 is submissive
        dominanceByLunges(i+1) = 'Dominant'; % Fly 2 is dominant
    else
        dominanceByLunges(i) = 'Unclear';  % Indeterminate/Equal dominance
        dominanceByLunges(i+1) = 'Unclear';
    end
end

