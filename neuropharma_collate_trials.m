function output_data = neuropharma_collate_trials(population_data, cur_time_list, cur_reading)
%
% output_data = neuropharma_collate_trials(population_data, cur_time_list, cur_reading)
%
% This function combines the readings from multiple trials into a population
% list to enable accurate computation of statistics. It handles the
% following cases where:
% (1) readings corresponding to sampling instances are not present
% (2) sampling instances are not in sync across trials - puts in order
% (3) readings are NaN and are to be omitted from population
%
% Assumptions: population_data is a structure with fields time (array), reading (cell of arrays)
%
% Inputs:
%   population_data - a structure with fields time[], reading{}
%   cur_time    - current time scale
%   cur_reading - current reading
%
% Output:
%   population_data - return the updated variable
%
% Author:- Pradeep Dheerendra, School of Neurology, Institute of Neuroscience,
%           Newcastle University, Newcastle-upon-Tyne, UK
% (C) Copyright 2014 - All rights reserved with Newcastle University

% Version History:-
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 02 July 2014 - basic implementation
%  0.2 - 02 July 2014 - bug fix for double precision in 'time'


% map the variables from input arguments
pop_time = single([population_data.time]); % array of single precision
pop_reading = [population_data.reading]; % cell of arrays
% pop_count = [population_data.count]; % array

% match the current time point in the population data

for sample_num = 1:length(cur_time_list)
    
    % skip if the data is not to be included
    if ~isnan(cur_reading(sample_num))
        
        % extract current sampling time
        cur_time = cur_time_list(sample_num);
        
        % extract index at which the current sampling time is listed on population
        indx = find(pop_time == cur_time);
        
        % if current time point is non-existent in the population, then insert
        if isempty(indx)
            
            % find point of insertion
            new_indx = find(pop_time < cur_time, 1, 'last' );
            
            % insert the sampling time into the population list
            pop_time = [pop_time(1:new_indx) cur_time pop_time(new_indx+1:end)];
            
            % insert the reading into the population list
            pop_reading = [pop_reading(1:new_indx) {cur_reading(sample_num)} pop_reading(new_indx+1:end)];
            
            % insert the count in the population list
            % pop_count = [pop_count(1:new_indx) 1 pop_count(new_indx+1:end)];
            
        else  % if current sampling time is non-existent in population, then append
            
            % append the reading into the population list
            pop_reading{indx} = [ pop_reading{indx} cur_reading(sample_num)];
            
            % increase the count in the population list
            % pop_count(indx) = pop_count(indx) + 1;
        end
        
    end
    
end


% map the variables to output argument
output_data.time = pop_time;
output_data.reading = pop_reading;
% output_data.count = pop_count;

end