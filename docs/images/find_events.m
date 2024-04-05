
function output = find_events(obj, daily)

num_hours = length(obj.Time);
num_bins  = length(obj.LFU.Probability);
output = [];


for ii = 1:num_bins
    temp = obj.filter().by_bin(ii);
    Index = temp.Interconnected.Index;
    Index.Replication = double(Index.Replication);
    Index.Hour = double(Index.Hour);

    n = height(temp.Interconnected.Index);
    if n == 0
        continue
    elseif n == 1
        hr_table = temp.Interconnected.Index(:,1:3);
        
        hrs = hr_table.Hour;
        [hr_data, ~] = temp.get_event(hr_table.Replication, hrs);
        hr_table.Data = {array2timetable(hr_data, 'RowTimes', obj.Time(hrs), 'VariableNames', temp.Names)};
        
    elseif n > 1
        data = diff(Index.Hour + (Index.Replication-1)*num_hours);
        
        index1 = zeros(height(temp.Interconnected.Index),1);
        
        for jj = 1:length(data)-1
            if data(jj) > 1 && data(jj+1) > 1
                index1(jj+1,1) = 1;
            else
                index1(jj+1,1) = 0;
            end
        end
        if Index.Hour(2) - Index.Hour(1) == 1
            index1(1) = 0;
        else
            index1(1) = 1;
        end
        if Index.Hour(end) - Index.Hour(end-1) == 1
            index1(end) = 0;
        else
            index1(end) = 1;
        end
        index1 = logical(index1);
        
        data(data > 1) = 0;
        
        % https://www.mathworks.com/matlabcentral/answers/366126-how-many-consecutive-ones#answer_290246
        out = double(diff([~data(1);data(:)]) == 1);
        v = accumarray(cumsum(out).*data(:)+1,1);
        out(out == 1) = v(2:end);
        
        d_out = out(out > 0) + 1;
        
        index2 = out > 0;
        if sum(index1) == 0
            hr_table = [];
        else
            hr_table = Index(index1,1:3);
        end
        my_table = Index(index2,1:3);
        
        % Loop for multi-hour events
        Data = cell(height(my_table), 1);
        for jj = 1:height(my_table)
            hrs = my_table.Hour(jj) + (0:d_out(jj)-1);
            [my_data, ~] = temp.get_event(my_table.Replication(jj), hrs);
            Data{jj} = array2timetable(my_data, 'RowTimes', obj.Time(hrs), 'VariableNames', temp.Names);
        end
        my_table = horzcat(my_table, table(Data)); %#ok<AGROW>
        
        % Loop for single-hour events
        if isempty(hr_table)
            hr_data = [];
        else
            Data = cell(height(hr_table), 1);
            for jj = 1:height(hr_table)
                hrs = hr_table.Hour(jj);
                [hr_data, ~] = temp.get_event(hr_table.Replication(jj), hrs);
                Data{jj} = array2timetable(hr_data, 'RowTimes', obj.Time(hrs), 'VariableNames', temp.Names);
            end
            hr_table = horzcat(hr_table, table(Data)); %#ok<AGROW>
        end
    end
    
    
    if isempty(my_table)
        fprintf('No multihour events found in Bin %i\n', ii)
        eventdata = hr_table;
    elseif isempty(hr_table)
        fprintf('No 1-hour events found in Bin %i\n', ii)
        eventdata = my_table;
    else
        eventdata = sortrows(vertcat(my_table, hr_table), {'Replication','Hour'},{'ascend','ascend'});
    end
    eventdata.Day = floor((eventdata.Hour-1)/24)+1;
    
    
    if nargin == 2 && daily  % aggregate events occuring in the same day
        % NOTE: may be buggy if an event crosses the day boundary
        
        index = vertcat(diff(eventdata.Day) == 0 & diff(eventdata.Replication) == 0, false);
        discontinous_events = flipud(find(index));
        for kk = 1:length(discontinous_events)
            % NOTE: this assumes there are only 2 discontinous events per day
            idx = discontinous_events(kk) + (0:1);
            eventdata.Data{idx(1)} = vertcat(eventdata(idx, :).Data{:});
            eventdata(idx(2:end), :) = [];
        end
    end
    output = vertcat(output, eventdata); %#ok<AGROW>
    
    my_table = [];
    hr_table = [];
end

% Resort data to match original sorting 
output = sortrows(output,{'Replication','Hour','Bin'},{'ascend','ascend','ascend'});

end 
