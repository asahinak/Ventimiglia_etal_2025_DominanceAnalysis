function plotLungeRates(timeVector, lungeRatesGroups, pulses, groupNames, colors)
    % plotLungeRates: Plots mean lunge rate with SEM and stimulation periods for multiple groups.
    %
    % Arguments:
    % - timeVector: Time (in minutes) corresponding to the lunging data.
    % - lungeRatesGroups: Cell array where each element is a cell array of lunging rates for a group.
    % - pulses: Array of pulse windows used for stimulation periods.
    % - groupNames: Cell array of group names (e.g., {'Dominant', 'Submissive', 'No Dominance'}).
    % - colors: Cell array of color codes (e.g., {'r', 'b', 'k'}) for each group.
    
    % Create the plot
    figure;
    hold on;
    
    % Initialize an array to store plot handles for the legend
    plotHandles = [];

    % Loop through each group and plot their mean lunge rate with SEM
    for g = 1:length(lungeRatesGroups)
        lungeRates = lungeRatesGroups{g};
        groupName = groupNames{g};
        color = colors{g};

        % Check if there are any flies to plot in the group
        if isempty(lungeRates)
            warning('No flies found in the %s group, skipping plot.', groupName);
            continue;
        end

        % Convert the cell array to a 3D matrix for easier manipulation
        try
            lungeRatesMatrix = cat(3, lungeRates{:});
        catch
            error('Lunge rates data for %s group have mismatched sizes or are empty.', groupName);
        end

        % Calculate the mean and SEM across flies for each time bin
        meanLungeRate = mean(lungeRatesMatrix, 3);  % Mean across the 3rd dimension (flies)
        semLungeRate = std(lungeRatesMatrix, 0, 3) / sqrt(size(lungeRatesMatrix, 3));  % SEM

        % Plot the SEM error cloud for each group
        fill([timeVector, fliplr(timeVector)], ...
             [meanLungeRate - semLungeRate, fliplr(meanLungeRate + semLungeRate)], ...
             color, 'FaceAlpha', 0.2, 'EdgeColor', 'none');  % SEM cloud

        % Plot the mean lunge rate line for each group
        plotHandle = plot(timeVector, meanLungeRate, [color '-'], 'LineWidth', 2);
        
        % Store the plot handle for the legend
        plotHandles = [plotHandles, plotHandle];
    end

    % Get the current y-axis limits to use for the stimulation box height
    yLimits = ylim;

    % Plot the gray boxes over the stimulation periods
    for j = 1:size(pulses, 1)
        % Define the start and end of the pulse window (already in minutes)
        pulseStart = pulses(j, 1);
        pulseEnd = pulses(j, 2);

        % Draw the rectangle for each stimulation window
        fill([pulseStart, pulseEnd, pulseEnd, pulseStart], ...
             [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], ...
             [0.5, 0.5, 0.5], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Gray, semi-transparent
    end

    % Add labels, title, and grid
    xlabel('Time (minutes)');
    ylabel('Lunge Rate');
    title('Lunge Rate Over Time for Multiple Groups');
    grid on;

    % Create the legend using the stored plot handles and corresponding group names
    legend(plotHandles, groupNames, 'Location', 'Best');
    
    hold off;
end