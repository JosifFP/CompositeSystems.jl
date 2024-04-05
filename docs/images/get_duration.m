
function [output, summary, data] = get_duration(obj)

data = process(obj.find_events());
[output, summary] = summarize(data, length(obj.LFU.Probability));

end


function output = process(input)

N = height(input);

data = zeros(N, 4);
for ii = 1:height(input)
    temp = input.Data{ii}.Variables;
    data(ii, 1) = size(temp, 1);
    data(ii, 2) = sum(min(temp, [], 1) < 0);
    
    temp = abs(temp(temp < 0));  % only keep non-zero data
    data(ii, 3) = min(temp, [], 'all');
    data(ii, 4) = max(temp, [], 'all');
    data(ii, 5) = sum(temp, 'all');
end

output = horzcat(input(:, 1:3), array2table(data,...
    'VariableNames', {'Duration', 'NumDef', 'MinDef', 'MaxDef', 'EnergyDef'}));
end

function [output, summary] = summarize(input, num_bins)

duration = zeros(24, num_bins);
metrics = zeros(num_bins, 5);
for jj = 1:num_bins
    data = input.Duration(input.Bin == jj);
    duration(:, jj) = accumarray(data, ones(size(data)), [24, 1]);
    
    metrics(jj, :) = [length(data), mean(data), std(data), kurtosis(data, 0), skewness(data, 0)];
end
output = array2table(horzcat(transpose(1:24), duration),...
    'VariableNames', horzcat({'Duration'}, cellstr("Bin_" + (1:7))));

summary = array2table(metrics,...
    'RowNames', cellstr("Bin " + (1:7)),...
    'VariableNames', {'Count', 'Mean', 'StDev', 'Kurtosis', 'Skewness'});
end
