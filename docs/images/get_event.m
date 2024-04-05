
function [event_margin, event_index] = get_event(obj, rep, hours, bin, marginstate)
narginchk(3, 5)

Index = obj.Interconnected.Index;

% 
event_index = Index.Replication == rep & and(Index.Hour >= hours(1), Index.Hour <= hours(end));


if nargin >= 4
    temp = event_index;
    event_index = temp & Index.Bin == bin;
elseif length(unique(Index.Bin(event_index))) > 1
    error('Data for this event exists in multiple load levels, please specify a load level.')
end
if nargin >= 5
    temp = event_index;
    event_index = temp & Index.MarginState == marginstate;
elseif length(unique(Index.MarginState(event_index))) > 1
    error('Data for this event exists for multiple margin states, please specify a margin state.')
end

event_margin = obj.Interconnected.Margin(event_index, :);

end