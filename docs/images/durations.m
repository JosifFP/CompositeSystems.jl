clear All
ot10_NYBA = set_name(MARS.ot10.load(), 'NYBA');
ot16_NYBA = sync(sync(MARS.ot16.load(), MARS.ot10.load()), ot10_NYBA);
in02 = MARS.in02.load(true);

Events = get_durations(ot10_NYBA, ot16_NYBA, in02);

%%Main Function
function Events = get_durations(ot10_NYBA, ot16_NYBA, in02)
    Events = struct();
    Load = struct();
    Temp = struct();
    Temp.NYBA = struct();
    Events.Area_Names(1:11) = cellstr(ot10_NYBA.Names(1:11));
    Events.Intf_Names(1:76) = cellstr(ot16_NYBA.Names(1:76));
    Load.LS = in02.sync(ot10_NYBA);
    Load.NYBA = sum(Load.LS.LFU_Data, 3);
     
    for idx = 1:length(Events.Area_Names)
        item = Events.Area_Names{idx};
        item_pos = strcmp(item, Events.Area_Names);
        Load.(item) = Load.LS.LFU_Data(:,:,item_pos);
        Temp.(item) = struct();
    end
     
    num_bins = length(Load.NYBA(1,:));
    input = ot10_NYBA.find_events();
    N = height(input);
    Events.Index = input(:, 1:3);
    max_duration = 36;
    suffixes = {'Time_Max_Deficit', 'Max_Deficit', 'LOE', 'Load','Reason'};
    varTypes = {};
    varArea_Names = {};

    specifiedColumns = {...
        'Replication','Bin','Month','Day','Duration','Time_Start_End',...
        'NYBA_Time_Max_Deficit','NYBA_Area_Max_Deficit','NYBA_Max_Deficit',...
        'NYBA_LOE','NYBA_Load','NYBA_Time_Max_Excess',...
        'NYBA_Area_Max_Excess','NYBA_Max_Excess','NYBA_Load_Excess'};

    varTypes = {...
        'double','double','double','double','double','cell',...
        'double','cell','double',...
        'double','double','double',...
        'cell','double','double'};
    
    % Generate varTypes and varArea_Names for dynamic columns
    for j = 1:numel(suffixes)
        for idx = 1:length(Events.Area_Names)
            varTypes{end+1} = 'double';
            varArea_Names{end+1} = [Events.Area_Names{idx} '_' suffixes{j}];
        end
    end

    varArea_Names = [specifiedColumns, varArea_Names];
    Events.Data = table('Size',[N 70],'VariableTypes',...
        varTypes,'VariableNames',varArea_Names);
    
    
    Internal_Intfs = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
                      1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
                      0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
                      0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
                      0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0;
                      0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0;
                      0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0;
                      0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0;
                      0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0;
                      0 0 0 0 0 0 0 0 0 1 0 1 1 1 0 0 0 1;
                      0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1 0;];
                      %0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0;J1
                      %0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0;J2
                      %0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0;J3
                      %0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1;J5
                      %0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0;K1
                      %0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0;K2
    External_Intfs = [1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;%A
                      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;%B
                      0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0;%C
                      0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0;%D
                      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;%E
                      0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0;%F
                      0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 0 0 0 1;%G
                      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;%H
                      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;%I
                      0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;%J
                      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0;];%K      
     
    for ii = 1:N
        Temp.All = input.Data{ii}.Variables;
        Temp.time = input.Data{ii}.Time;
        Temp.num_hours = size(Temp.All, 1);
        Temp.NYBA.flattened_temp = Temp.All(Temp.All < 0);
     
        if ~isempty(Temp.NYBA.flattened_temp)
     
             Temp.NYBA.All = Temp.All;
     
             if size(Temp.NYBA.All, 2) == 1
                 [Temp.NYBA.Deficit, Temp.NYBA.Time_Max_Deficit] = min(Temp.NYBA.All, [], 1, 'omitnan');
                 [Temp.NYBA.Excess, Temp.NYBA.Time_Max_Excess] = max(Temp.NYBA.All, [], 1, 'omitnan');
             else
                 [Temp.NYBA.min_temp_per_row, Temp.NYBA.min_temp_per_col] = min(Temp.NYBA.All, [], 2, 'omitnan');
                 [Temp.NYBA.Deficit, Temp.NYBA.Time_Max_Deficit] = min(Temp.NYBA.min_temp_per_row);
     
                 [Temp.NYBA.max_temp_per_row, Temp.NYBA.max_temp_per_col] = max(Temp.NYBA.All, [], 2, 'omitnan');
                 [Temp.NYBA.Excess, Temp.NYBA.Time_Max_Excess] = max(Temp.NYBA.max_temp_per_row);
             end
     
             t = input(ii,2).Hour;
             Temp.NYBA.load_bin_index_Max_Deficit = t + Temp.NYBA.Time_Max_Deficit - 1;
             Temp.NYBA.load_bin_index_Max_Excess = t + Temp.NYBA.Time_Max_Excess - 1;
     
             Events.Data.Replication(ii) = input(ii,1).Replication;
             Events.Data.Bin(ii) = input(ii,3).Bin;
             Events.Data.Month(ii) = month(Temp.time(Temp.NYBA.Time_Max_Deficit));
             Events.Data.Day(ii) = day(Temp.time(Temp.NYBA.Time_Max_Deficit));
             Events.Data.Duration(ii) = Temp.num_hours;
             Events.Data.Time_Start_End(ii) = {[hour(Temp.time(1)); hour(Temp.time(end))]};
     
             if Temp.NYBA.Deficit <= 0
                 Events.Data.NYBA_Time_Max_Deficit(ii) = hour(Temp.time(Temp.NYBA.Time_Max_Deficit));
                 Temp.NYBA.Area_Deficit = Temp.NYBA.min_temp_per_col(Temp.NYBA.Time_Max_Deficit);
                 Events.Data.NYBA_Area_Max_Deficit(ii) = cellstr(Events.Area_Names{Temp.NYBA.Area_Deficit});
                 Events.Data.NYBA_Max_Deficit(ii) = Temp.NYBA.Deficit;
                 Events.Data.NYBA_LOE(ii) = sum(Temp.NYBA.flattened_temp, 'all');
                 Events.Data.NYBA_Load(ii) = Load.NYBA(Temp.NYBA.load_bin_index_Max_Deficit, input(ii,3).Bin);
                 %Events.All_At_Time_Max_Deficit(ii,1:11) = Temp.NYBA.All(Temp.NYBA.Time_Max_Deficit,1:11);
             end
     
             if Temp.NYBA.Excess > 0
                 Events.Data.NYBA_Time_Max_Excess(ii) = hour(Temp.time(Temp.NYBA.Time_Max_Excess));
                 Temp.NYBA.Area_Excess = Temp.NYBA.max_temp_per_col(Temp.NYBA.Time_Max_Excess);
                 Events.Data.NYBA_Area_Max_Excess(ii) = cellstr(Events.Area_Names{Temp.NYBA.Area_Excess});
                 Events.Data.NYBA_Max_Excess(ii) = Temp.NYBA.Excess;
                 Events.Data.NYBA_Load_Excess(ii) = Load.NYBA(Temp.NYBA.load_bin_index_Max_Excess, input(ii,3).Bin);
                 %Events.All_At_Time_Max_Excess(ii,1:11) = Temp.NYBA.All(Temp.NYBA.Time_Max_Excess,1:11);
             %else
                 %Events.All_At_Time_Max_Excess(ii,1:11) = zeros(1,11);
             end
             
             row = find(ot16_NYBA.Index.Replication==input(ii,1).Replication...
                 & ot16_NYBA.Index.Hour==Temp.NYBA.load_bin_index_Max_Deficit & ot16_NYBA.Index.Bin==input(ii,3).Bin);
             
             Out = double(ot16_NYBA.InService(row, 1:length(Events.Intf_Names)));
             Out(:, Out==1) = NaN;
             Out(:, Out==0) = 1;
             Events.Out(ii,1:length(Events.Intf_Names)) = Out;
             At_Limit = ot16_NYBA.Slack(row,1:length(Events.Intf_Names));
             At_Limit(:, At_Limit>5.00) = NaN;
             At_Limit(:, At_Limit<-5.00) = NaN;
             At_Limit(:, ~isnan(At_Limit)) = 1;
             Events.At_Limit(ii,1:length(Events.Intf_Names)) = At_Limit;             
             
             for idx = 1:length(Events.Area_Names)
                 item = Events.Area_Names{idx};
                 item_pos = strcmp(item, Events.Area_Names);
                 Temp.(item).All = Temp.All(:,item_pos);
                 Temp.(item).flattened_temp = Temp.(item).All(Temp.(item).All < 0);
                 R1 = Internal_Intfs(idx,:).*At_Limit(1:18);
                 R2 = External_Intfs(idx,:).*At_Limit(19:38);
                 R4 = Internal_Intfs(idx,:).*Out(1:18);
                 %R5 = External_Intfs(idx,:).*Out(19:38);
                 R1(:, R1==0) = NaN;
                 R2(:, R2==0) = NaN;
                 R4(:, R4==0) = NaN;
                 R4(18) = NaN; %CHPE
                 %R5(:, R5==0) = NaN;
     
                 if size(Temp.(item).All, 2) == 1
                     [Temp.(item).Deficit, Temp.(item).Time_Max_Deficit] = min(Temp.(item).All, [], 1, 'omitnan');
                 else
                     [Temp.(item).min_temp_per_row, ~] = min(Temp.(item).All, [], 2, 'omitnan');
                     [Temp.(item).Deficit, Temp.(item).Time_Max_Deficit] = min(Temp.(item).min_temp_per_row);
                 end
                 if Temp.(item).Deficit > 0
                    Temp.(item).Deficit = 0;
                 else
                     if nnz(~isnan(R1)) > 0 && nnz(~isnan(R2)) == 0
                         Events.Data{ii,59+idx} = 1;
                     elseif nnz(~isnan(R2)) > 0 && nnz(~isnan(R1)) == 0
                         Events.Data{ii,59+idx} = 2;
                     elseif nnz(~isnan(R2)) > 0 && nnz(~isnan(R1)) > 0
                         Events.Data{ii,59+idx} = 3;
                     elseif nnz(~isnan(R4)) > 0 && Events.Data{ii,59+idx} == 0
                         Events.Data{ii,59+idx} = 4;
                     elseif nnz(~isnan(R4)) > 0 && Events.Data{ii,59+idx} ~= 0
                         Events.Data{ii,59+idx} = 5;
                     end
                 end                 
                 t = input(ii,2).Hour;
                 Temp.(item).load_bin_index_Max_Deficit = t + Temp.(item).Time_Max_Deficit - 1;
                 Events.Data{ii,15+idx} = hour(Temp.time(Temp.(item).Time_Max_Deficit));
                 Events.Data{ii,26+idx} = Temp.(item).Deficit;
                 Events.Data{ii,37+idx} = sum(Temp.(item).flattened_temp, 'all');
                 Events.Data{ii,48+idx} = Load.(item)(Temp.(item).load_bin_index_Max_Deficit, input(ii,3).Bin); 
             end  
        end
    end
     
    duration = zeros(max_duration, num_bins);
    metrics = zeros(num_bins, 5);
     
    for jj = 1:num_bins
        Temp.Duration = Events.Data.Duration(Events.Index.Bin == jj);
        Temp.Duration = max(1,round(Temp.Duration));
        duration(:, jj) = accumarray(Temp.Duration,ones(size(Temp.Duration)),[max_duration, 1], [], 0);
        metrics(jj, :) = [length(Temp.Duration),mean(Temp.Duration),std(Temp.Duration),kurtosis(Temp.Duration, 0),skewness(Temp.Duration, 0)];
    end
     
    Events.Duration = array2table(horzcat(transpose(1:max_duration),duration),'VariableNames',horzcat({'Duration'},cellstr("Bin_"+(1:num_bins))));
    Events.Statistic_Summary = array2table(metrics,'RowNames',cellstr("Bin "+(1:num_bins)),'VariableNames',{'Count','Mean','StDev','Kurtosis','Skewness'});
    [Events.Adequacy_Summary, ~] = create_reports(ot10_NYBA,true);
end