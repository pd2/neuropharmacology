function [output_avg, output_sem] = neuropharma_population_stats(population_readings)
%
% [output_avg, output_se] = neuropharma_population_stats(population_readings)
%
% This function computes the statistics on a population time series of
% varying readings at each sample.
%
% Inputs:
%   population_reading - population time series -> reading
%
% Output:
%   output_avg - mean of all readings at each point in the time series
%   output_sem - standard error of the mean at each sampling point
%
% Author:- Pradeep Dheerendra, School of Neurology, Institute of Neuroscience,
%           Newcastle University, Newcastle-upon-Tyne, UK
% (C) Copyright 2014 - All rights reserved with Newcastle University

% Version History:-
%  ver - DD MMMM YYYY - Feature added
%  0.1 - 02 July 2014 - basic implementation

% number of sampling points in this population
num_samples = length(population_readings);

% output initialization
output_avg = zeros(1,num_samples);
output_sem = zeros(1,num_samples);

% compute stats for each samepling point
for num = 1:length(population_readings)
    
    % extract the readings for the current sampling point
    readings = population_readings{num};
    
    % number of readings in this sample
    num_readings = length(readings);
    
    % compute mean at the current sampling point
    output_avg(num) = mean(readings);
    
    % compute standard error of the mean at the current sampling point
    output_sem(num) = std(readings)/sqrt(num_readings);
    
end

end